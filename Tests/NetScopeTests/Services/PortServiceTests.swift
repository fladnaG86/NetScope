import XCTest
@testable import NetScope

final class PortServiceTests: XCTestCase {
    private var service: PortService!

    override func setUp() {
        super.setUp()
        service = PortService()
    }

    func testCommonPortsDict() {
        // Verify static common ports dictionary has expected entries
        XCTAssertFalse(PortService.commonPorts.isEmpty)
        XCTAssertEqual(PortService.commonPorts[22], "SSH")
        XCTAssertEqual(PortService.commonPorts[80], "HTTP")
        XCTAssertEqual(PortService.commonPorts[443], "HTTPS")
        XCTAssertEqual(PortService.commonPorts[3306], "MySQL")
        XCTAssertEqual(PortService.commonPorts[27017], "MongoDB")
    }

    func testScanLocalhostSmoke() async {
        // Basic smoke test: scan a couple of common ports on localhost
        // SSH (22) might be open or closed, HTTP (80) likely closed
        let result = await service.scan(host: "127.0.0.1", ports: [22, 80], timeout: 2)
        XCTAssertEqual(result.host, "127.0.0.1")
        XCTAssertEqual(result.ports.count, 2)
        // Verify the result contains PortInfo objects without crashing
        for portInfo in result.ports {
            XCTAssertNotNil(PortState(rawValue: portInfo.state.rawValue))
        }
    }

    func testScanReturnsAllPorts() async {
        // Even unreachable hosts should return results for all requested ports
        let result = await service.scan(host: "192.0.2.1", ports: [22, 80, 443], timeout: 1)
        XCTAssertEqual(result.host, "192.0.2.1")
        XCTAssertEqual(result.ports.count, 3)
    }

    func testScanEmptyPorts() async {
        let result = await service.scan(host: "127.0.0.1", ports: [], timeout: 2)
        XCTAssertEqual(result.host, "127.0.0.1")
        XCTAssertTrue(result.ports.isEmpty)
    }
}