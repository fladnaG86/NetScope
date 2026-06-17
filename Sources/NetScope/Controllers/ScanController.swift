import Foundation

final class ScanController: Sendable {
    let subnetService: any SubnetServiceProtocol
    let pingService: any PingServiceProtocol
    let arpService: any ArpServiceProtocol
    let dnsService: any DnsServiceProtocol
    let portService: any PortServiceProtocol
    let macVendorService: any MacVendorServiceProtocol
    let scanState: ScanStateActor
    let deviceCache: DeviceCacheActor
    let deviceRepository: any DeviceRepositoryProtocol
    let settings: any SettingsProviderProtocol

    init(
        subnetService: any SubnetServiceProtocol,
        pingService: any PingServiceProtocol,
        arpService: any ArpServiceProtocol,
        dnsService: any DnsServiceProtocol,
        portService: any PortServiceProtocol,
        macVendorService: any MacVendorServiceProtocol,
        scanState: ScanStateActor,
        deviceCache: DeviceCacheActor,
        deviceRepository: any DeviceRepositoryProtocol,
        settings: any SettingsProviderProtocol = UserDefaultsSettingsProvider()
    ) {
        self.subnetService = subnetService
        self.pingService = pingService
        self.arpService = arpService
        self.dnsService = dnsService
        self.portService = portService
        self.macVendorService = macVendorService
        self.scanState = scanState
        self.deviceCache = deviceCache
        self.deviceRepository = deviceRepository
        self.settings = settings
    }

    func scan(subnet: String, mode: ScanMode = .quick) async throws {
        let subnetInfo = try subnetService.parseTarget(subnet)
        let hosts = subnetService.enumerateHosts(subnet: subnetInfo)
        let timeout = await MainActor.run { settings.scanTimeout }
        let maxConcurrent = await MainActor.run { settings.maxConcurrentScans }
        await scanState.startScan(totalHosts: hosts.count)

        // Phase 1: Parallel ping sweep (bounded concurrency via actor)
        var liveHosts: [String] = []
        let limiter = ConcurrencyLimiter(maxConcurrent)
        await withTaskGroup(of: String?.self) { group in
            for host in hosts {
                if await scanState.isCancelled { break }

                group.addTask { [pingService, scanState] in
                    await limiter.acquire()
                    defer { Task { await limiter.release() } }
                    guard await !scanState.isCancelled else { return nil }
                    do {
                        let result = try await pingService.ping(host: host, timeout: timeout)
                        await scanState.incrementScanned()
                        return result.isReachable ? host : nil
                    } catch {
                        await scanState.incrementScanned()
                        return nil
                    }
                }
            }

            for await result in group {
                if let host = result {
                    liveHosts.append(host)
                }
            }
        }

        guard await !scanState.isCancelled else {
            throw ScanError.cancelled
        }

        // Read ARP table once — ping sweep just populated it
        let arpTable = await arpService.resolveAll()

        // Debug: write ARP results
        let dbg = "[Scan] ARP:\(arpTable.count) live:\(liveHosts.count) " + liveHosts.map { "\($0)=\(arpTable[$0] ?? "nil")" }.joined(separator: " ") + "\n"
        let dbgData = dbg.data(using: .utf8) ?? Data()
        try? dbgData.write(to: URL(fileURLWithPath: "/tmp/netscope_scan.log"), options: .atomic)

        // Phase 2: Parallel detail gathering for live hosts
        await withTaskGroup(of: Void.self) { group in
            for host in liveHosts {
                if await scanState.isCancelled { break }

                group.addTask { [dnsService, macVendorService, portService, scanState, deviceCache, deviceRepository, mode, timeout] in
                    guard await !scanState.isCancelled else { return }

                    // DNS lookup per host (can't batch this easily)
                    async let dnsResult = dnsService.reverseLookup(ip: host)

                    var portInfos: [PortInfo] = []
                    if mode == .deep {
                        let ports = Array(PortService.commonPorts.keys).sorted()
                        let portResult = await portService.scan(host: host, ports: ports, timeout: timeout)
                        portInfos = portResult.ports
                    }

                    let macAddress = arpTable[host]
                    let dns = await dnsResult

                    let vendor = macAddress.flatMap { macVendorService.lookup(macAddress: $0) }

                    // Check cache for existing device (to preserve UUID on re-scan)
                    let existingDevice = await deviceCache.get(ip: host)
                    let deviceId = existingDevice?.id ?? UUID()

                    let device = Device(
                        id: deviceId,
                        ip: host,
                        hostname: dns.hostname,
                        macAddress: macAddress,
                        vendor: vendor,
                        isOnline: true,
                        firstSeen: existingDevice?.firstSeen ?? Date(),
                        lastSeen: Date(),
                        ports: portInfos
                    )

                    await scanState.addDevice(device)
                    await deviceCache.set(device)
                    do {
                        try await deviceRepository.save(device)
                    } catch {
                        // Log but don't fail the scan — device is in UI cache
                        print("[ScanController] Failed to save device \(host): \(error)")
                    }
                }
            }
        }

        await scanState.finishScan()
    }

    func cancelScan() async {
        await scanState.cancel()
    }
}