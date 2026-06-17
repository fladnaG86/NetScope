import XCTest
@testable import NetScope
import GRDB

// MARK: - Mock Services

struct MockSubnetServiceForScan: SubnetServiceProtocol {
    func calculateSubnet(cidr: String) throws -> SubnetInfo {
        SubnetInfo(
            networkAddress: "192.168.1.0",
            mask: "255.255.255.252",
            broadcastAddress: "192.168.1.3",
            hostRange: (start: "192.168.1.1", end: "192.168.1.2"),
            totalHosts: 2
        )
    }

    func parseTarget(_ target: String) throws -> SubnetInfo {
        try calculateSubnet(cidr: target)
    }

    func enumerateHosts(subnet: SubnetInfo) -> [String] {
        ["192.168.1.1", "192.168.1.2"]
    }
}

struct MockPingForScan: PingServiceProtocol {
    var delay: UInt64 = 0 // nanoseconds
    func ping(host: String, timeout: TimeInterval) async throws -> PingResult {
        if delay > 0 {
            try await Task.sleep(nanoseconds: delay)
        }
        return PingResult(host: host, isReachable: true, latencyMs: 5.0)
    }
}

struct MockArpForScan: ArpServiceProtocol {
    func resolve(ip: String) async -> ArpResult {
        ArpResult(ip: ip, macAddress: "AA:BB:CC:DD:EE:FF")
    }

    func resolveAll() async -> [String: String] {
        ["192.168.1.1": "AA:BB:CC:DD:EE:FF", "192.168.1.2": "AA:BB:CC:DD:EE:FF"]
    }
}

struct MockDnsForScan: DnsServiceProtocol {
    func reverseLookup(ip: String) async -> DnsResult {
        DnsResult(ip: ip, hostname: "mock-host.local")
    }
}

struct MockPortForScan: PortServiceProtocol {
    func scan(host: String, ports: [Int], timeout: TimeInterval) async -> PortScanResult {
        PortScanResult(
            host: host,
            ports: [PortInfo(id: 22, number: 22, transport: .tcp, service: "SSH", state: .open)]
        )
    }
}

struct MockMacVendorForScan: MacVendorServiceProtocol {
    func lookup(macAddress: String) -> String? { "TestVendor" }
}

// MARK: - Tests

final class ScanControllerTests: XCTestCase {

    private func makeController(
        ping: any PingServiceProtocol = MockPingForScan(),
        mode: ScanMode = .quick
    ) throws -> ScanController {
        let dbManager = try DatabaseManager(inMemory: true)
        let repo = try DeviceRepository(dbManager: dbManager)
        let scanState = ScanStateActor()
        let deviceCache = DeviceCacheActor()

        return ScanController(
            subnetService: MockSubnetServiceForScan(),
            pingService: ping,
            arpService: MockArpForScan(),
            dnsService: MockDnsForScan(),
            portService: MockPortForScan(),
            macVendorService: MockMacVendorForScan(),
            scanState: scanState,
            deviceCache: deviceCache,
            deviceRepository: repo,
            settings: TestSettingsProvider.quick
        )
    }

    func testQuickScanDiscoversDevices() async throws {
        let controller = try makeController()
        try await controller.scan(subnet: "192.168.1.0/30", mode: .quick)

        let devices = await controller.scanState.devices
        XCTAssertFalse(devices.isEmpty, "Quick scan should discover devices")
        // With 2 hosts and all pings reachable, expect 2 devices
        XCTAssertEqual(devices.count, 2)

        for device in devices {
            XCTAssertEqual(device.hostname, "mock-host.local")
            XCTAssertEqual(device.macAddress, "AA:BB:CC:DD:EE:FF")
            XCTAssertEqual(device.vendor, "TestVendor")
            XCTAssertTrue(device.isOnline)
            // Quick mode should not scan ports
            XCTAssertTrue(device.ports.isEmpty, "Quick scan should not include port results")
        }
    }

    func testDeepScanIncludesPorts() async throws {
        let controller = try makeController()
        try await controller.scan(subnet: "192.168.1.0/30", mode: .deep)

        let devices = await controller.scanState.devices
        XCTAssertFalse(devices.isEmpty, "Deep scan should discover devices")
        XCTAssertEqual(devices.count, 2)

        for device in devices {
            XCTAssertFalse(device.ports.isEmpty, "Deep scan should include port results")
            XCTAssertTrue(device.ports.contains(where: { $0.number == 22 && $0.state == .open }))
        }
    }

    func testCancelScan() async throws {
        // Use a slow ping mock so cancellation actually fires during the scan
        let slowPing = MockPingForScan(delay: 500_000_000) // 500ms per ping
        let controller = try makeController(ping: slowPing)

        // Start the scan in a background task
        let scanTask = Task {
            try? await controller.scan(subnet: "192.168.1.0/30", mode: .quick)
        }

        // Give the scan a moment to start, then cancel
        try await Task.sleep(nanoseconds: 50_000_000) // 50ms
        await controller.cancelScan()

        // Wait for the scan task to finish
        await scanTask.value

        let isCancelled = await controller.scanState.isCancelled
        XCTAssertTrue(isCancelled, "Scan should be marked as cancelled after cancelScan()")
    }
}