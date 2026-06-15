import XCTest
@testable import NetScope

final class ArpServiceTests: XCTestCase {
    private var service: ArpService!

    override func setUp() {
        super.setUp()
        service = ArpService()
    }

    func testArpReturnsResultWithoutCrashing() async {
        // Just verify the service returns a result without crashing
        let result = await service.resolve(ip: "127.0.0.1")
        XCTAssertEqual(result.ip, "127.0.0.1")
        // macAddress may be nil for localhost, that's fine
    }

    func testArpReturnsResultForNonExistentIP() async {
        // Even for an unreachable IP, the service should return gracefully
        let result = await service.resolve(ip: "192.0.2.1")
        XCTAssertEqual(result.ip, "192.0.2.1")
        XCTAssertNil(result.macAddress, "Unreachable IP should have nil MAC address")
    }
}