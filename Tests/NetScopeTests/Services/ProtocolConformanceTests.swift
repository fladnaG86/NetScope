import XCTest
@testable import NetScope

// MARK: - Mock Implementations

struct MockPingService: PingServiceProtocol, Sendable {
    func ping(host: String, timeout: TimeInterval) async throws -> PingResult {
        PingResult(host: host, isReachable: true, latencyMs: 1.5)
    }
}

struct MockArpService: ArpServiceProtocol, Sendable {
    func resolve(ip: String) async -> ArpResult {
        ArpResult(ip: ip, macAddress: "00:11:22:33:44:55")
    }
}

struct MockDnsService: DnsServiceProtocol, Sendable {
    func reverseLookup(ip: String) async -> DnsResult {
        DnsResult(ip: ip, hostname: "host.local")
    }
}

struct MockPortService: PortServiceProtocol, Sendable {
    func scan(host: String, ports: [Int], timeout: TimeInterval) async -> PortScanResult {
        let portInfos = ports.map { port in
            PortInfo(id: port, number: port, transport: .tcp, service: nil, state: .open)
        }
        return PortScanResult(host: host, ports: portInfos)
    }
}

struct MockSubnetService: SubnetServiceProtocol, Sendable {
    func calculateSubnet(cidr: String) throws -> SubnetInfo {
        SubnetInfo(
            networkAddress: "192.168.1.0",
            mask: "255.255.255.0",
            broadcastAddress: "192.168.1.255",
            hostRange: (start: "192.168.1.1", end: "192.168.1.254"),
            totalHosts: 254
        )
    }

    func enumerateHosts(subnet: SubnetInfo) -> [String] {
        ["192.168.1.1", "192.168.1.2"]
    }
}

struct MockMacVendorService: MacVendorServiceProtocol, Sendable {
    func lookup(macAddress: String) -> String? {
        "Test Vendor"
    }
}

struct MockExporter: ExporterProtocol, Sendable {
    let formatName = "CSV"
    let fileExtension = "csv"

    func export(devices: [Device], metrics: [NetworkMetrics], to url: URL) throws -> URL {
        url
    }
}

// MARK: - Tests

final class ProtocolConformanceTests: XCTestCase {

    // MARK: PingServiceProtocol

    func testMockPingServiceConformsToProtocol() {
        let service: PingServiceProtocol = MockPingService()
        XCTAssertTrue(service is MockPingService)
    }

    func testPingServiceReturnsResult() async throws {
        let service: PingServiceProtocol = MockPingService()
        let result = try await service.ping(host: "192.168.1.1", timeout: 5.0)
        XCTAssertEqual(result.host, "192.168.1.1")
        XCTAssertTrue(result.isReachable)
        XCTAssertEqual(result.latencyMs, 1.5)
    }

    // MARK: ArpServiceProtocol

    func testMockArpServiceConformsToProtocol() {
        let service: ArpServiceProtocol = MockArpService()
        XCTAssertTrue(service is MockArpService)
    }

    func testArpServiceReturnsResult() async {
        let service: ArpServiceProtocol = MockArpService()
        let result = await service.resolve(ip: "192.168.1.1")
        XCTAssertEqual(result.ip, "192.168.1.1")
        XCTAssertEqual(result.macAddress, "00:11:22:33:44:55")
    }

    // MARK: DnsServiceProtocol

    func testMockDnsServiceConformsToProtocol() {
        let service: DnsServiceProtocol = MockDnsService()
        XCTAssertTrue(service is MockDnsService)
    }

    func testDnsServiceReturnsResult() async {
        let service: DnsServiceProtocol = MockDnsService()
        let result = await service.reverseLookup(ip: "192.168.1.1")
        XCTAssertEqual(result.ip, "192.168.1.1")
        XCTAssertEqual(result.hostname, "host.local")
    }

    // MARK: PortServiceProtocol

    func testMockPortServiceConformsToProtocol() {
        let service: PortServiceProtocol = MockPortService()
        XCTAssertTrue(service is MockPortService)
    }

    func testPortServiceReturnsResult() async {
        let service: PortServiceProtocol = MockPortService()
        let result = await service.scan(host: "192.168.1.1", ports: [80, 443], timeout: 5.0)
        XCTAssertEqual(result.host, "192.168.1.1")
        XCTAssertEqual(result.ports.count, 2)
        XCTAssertEqual(result.ports[0].number, 80)
        XCTAssertEqual(result.ports[1].number, 443)
    }

    // MARK: SubnetServiceProtocol

    func testMockSubnetServiceConformsToProtocol() {
        let service: SubnetServiceProtocol = MockSubnetService()
        XCTAssertTrue(service is MockSubnetService)
    }

    func testSubnetServiceCalculatesSubnet() throws {
        let service: SubnetServiceProtocol = MockSubnetService()
        let info = try service.calculateSubnet(cidr: "192.168.1.0/24")
        XCTAssertEqual(info.networkAddress, "192.168.1.0")
        XCTAssertEqual(info.mask, "255.255.255.0")
        XCTAssertEqual(info.broadcastAddress, "192.168.1.255")
        XCTAssertEqual(info.hostRange.start, "192.168.1.1")
        XCTAssertEqual(info.hostRange.end, "192.168.1.254")
        XCTAssertEqual(info.totalHosts, 254)
    }

    func testSubnetServiceEnumeratesHosts() throws {
        let service: SubnetServiceProtocol = MockSubnetService()
        let info = try service.calculateSubnet(cidr: "192.168.1.0/24")
        let hosts = service.enumerateHosts(subnet: info)
        XCTAssertEqual(hosts.count, 2)
    }

    // MARK: MacVendorServiceProtocol

    func testMockMacVendorServiceConformsToProtocol() {
        let service: MacVendorServiceProtocol = MockMacVendorService()
        XCTAssertTrue(service is MockMacVendorService)
    }

    func testMacVendorServiceReturnsResult() {
        let service: MacVendorServiceProtocol = MockMacVendorService()
        let vendor = service.lookup(macAddress: "00:11:22:33:44:55")
        XCTAssertEqual(vendor, "Test Vendor")
    }

    // MARK: ExporterProtocol

    func testMockExporterConformsToProtocol() {
        let exporter: ExporterProtocol = MockExporter()
        XCTAssertTrue(exporter is MockExporter)
    }

    func testExporterProperties() {
        let exporter: ExporterProtocol = MockExporter()
        XCTAssertEqual(exporter.formatName, "CSV")
        XCTAssertEqual(exporter.fileExtension, "csv")
    }

    func testExporterExportsToURL() throws {
        let exporter: ExporterProtocol = MockExporter()
        let url = URL(fileURLWithPath: "/tmp/test_export.csv")
        let result = try exporter.export(devices: [], metrics: [], to: url)
        XCTAssertEqual(result, url)
    }

    // MARK: Error Types

    func testScanErrorDescriptions() {
        XCTAssertEqual(ScanError.networkUnavailable.errorDescription, "Network unavailable")
        XCTAssertEqual(ScanError.subnetInvalid("10.0.0/24").errorDescription, "Invalid subnet: 10.0.0/24")
        XCTAssertEqual(ScanError.permissionDenied.errorDescription, "Permission denied")
        let uuid = UUID()
        XCTAssertEqual(ScanError.timeout(uuid).errorDescription, "Scan timed out for device \(uuid)")
        XCTAssertEqual(ScanError.cancelled.errorDescription, "Scan cancelled")
    }

    func testMetricsErrorDescriptions() {
        XCTAssertEqual(MetricsError.deviceNotFound.errorDescription, "Device not found")
        XCTAssertEqual(MetricsError.pingFailed("10.0.0.1").errorDescription, "Ping failed for 10.0.0.1")
        XCTAssertEqual(MetricsError.insufficientSamples.errorDescription, "Insufficient samples for metrics")
    }

    func testExportErrorDescriptions() {
        let url = URL(fileURLWithPath: "/tmp/out.csv")
        XCTAssertEqual(ExportError.fileWriteFailed(url).errorDescription, "Failed to write file: /tmp/out.csv")
        XCTAssertEqual(ExportError.noData.errorDescription, "No data to export")
        XCTAssertEqual(ExportError.unsupportedFormat.errorDescription, "Unsupported export format")
    }
}