import XCTest
@testable import NetScope

final class ArpServiceTests: XCTestCase {
    private var service: ArpService!

    override func setUp() {
        super.setUp()
        service = ArpService()
    }

    func testArpReturnsResultWithoutCrashing() async {
        let result = await service.resolve(ip: "127.0.0.1")
        XCTAssertEqual(result.ip, "127.0.0.1")
    }

    func testArpReturnsResultForNonExistentIP() async {
        let result = await service.resolve(ip: "192.0.2.1")
        XCTAssertEqual(result.ip, "192.0.2.1")
        XCTAssertNil(result.macAddress, "Unreachable IP should have nil MAC address")
    }

    func testResolveAllReturnsDictionary() async {
        let table = await service.resolveAll()
        // Should return a dictionary (may be empty on CI/strange environments)
        XCTAssertNotNil(table, "resolveAll should return a valid dictionary")
    }
}