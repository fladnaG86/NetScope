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

    init(
        subnetService: any SubnetServiceProtocol,
        pingService: any PingServiceProtocol,
        arpService: any ArpServiceProtocol,
        dnsService: any DnsServiceProtocol,
        portService: any PortServiceProtocol,
        macVendorService: any MacVendorServiceProtocol,
        scanState: ScanStateActor,
        deviceCache: DeviceCacheActor,
        deviceRepository: any DeviceRepositoryProtocol
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
    }

    func scan(subnet: String, mode: ScanMode = .quick) async throws {
        let subnetInfo = try subnetService.calculateSubnet(cidr: subnet)
        let hosts = subnetService.enumerateHosts(subnet: subnetInfo)
        await scanState.startScan(totalHosts: hosts.count)

        // Phase 1: Parallel ping sweep
        var liveHosts: [String] = []
        await withTaskGroup(of: String?.self) { group in
            for host in hosts {
                if await scanState.isCancelled { break }

                group.addTask { [pingService, scanState] in
                    guard await !scanState.isCancelled else { return nil }
                    do {
                        let result = try await pingService.ping(host: host, timeout: 5.0)
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

        // Phase 2: Parallel detail gathering for live hosts
        await withTaskGroup(of: Void.self) { group in
            for host in liveHosts {
                if await scanState.isCancelled { break }

                group.addTask { [arpService, dnsService, macVendorService, portService, scanState, deviceCache, deviceRepository, mode] in
                    guard await !scanState.isCancelled else { return }

                    // Concurrently gather ARP, DNS, and optionally port info
                    async let arpResult = arpService.resolve(ip: host)
                    async let dnsResult = dnsService.reverseLookup(ip: host)

                    var portInfos: [PortInfo] = []
                    if mode == .deep {
                        let ports = Array(PortService.commonPorts.keys).sorted()
                        let portResult = await portService.scan(host: host, ports: ports, timeout: 5.0)
                        portInfos = portResult.ports
                    }

                    let arp = await arpResult
                    let dns = await dnsResult

                    let vendor = arp.macAddress.flatMap { macVendorService.lookup(macAddress: $0) }

                    // Check cache for existing device (to preserve UUID on re-scan)
                    let existingDevice = await deviceCache.get(ip: host)
                    let deviceId = existingDevice?.id ?? UUID()

                    let device = Device(
                        id: deviceId,
                        ip: host,
                        hostname: dns.hostname,
                        macAddress: arp.macAddress,
                        vendor: vendor,
                        isOnline: true,
                        firstSeen: existingDevice?.firstSeen ?? Date(),
                        lastSeen: Date(),
                        ports: portInfos
                    )

                    await scanState.addDevice(device)
                    await deviceCache.set(device)
                    try? await deviceRepository.save(device)
                }
            }
        }

        await scanState.finishScan()
    }

    func cancelScan() async {
        await scanState.cancel()
    }
}