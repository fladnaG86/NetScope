import XCTest
@testable import NetScope

final class PingServiceTests: XCTestCase {
    private var service: PingService!

    override func setUp() {
        super.setUp()
        service = PingService()
    }

    func testPingLocalhost() async throws {
        // Ping 127.0.0.1 -> isReachable=true
        let result = try await service.ping(host: "127.0.0.1", timeout: 5)
        XCTAssertEqual(result.host, "127.0.0.1")
        XCTAssertTrue(result.isReachable, "Localhost should be reachable")
        XCTAssertNotNil(result.latencyMs, "Latency should be reported for localhost")
        if let latency = result.latencyMs {
            XCTAssertGreaterThanOrEqual(latency, 0, "Latency should be non-negative")
        }
    }

    func testPingUnreachable() async throws {
        // 192.0.2.1 is in TEST-NET (RFC 5737), should be unreachable
        let result = try await service.ping(host: "192.0.2.1", timeout: 1)
        XCTAssertEqual(result.host, "192.0.2.1")
        XCTAssertFalse(result.isReachable, "TEST-NET address should be unreachable")
        XCTAssertNil(result.latencyMs, "Latency should be nil for unreachable host")
    }
}