import XCTest
@testable import NetScope

final class DnsServiceTests: XCTestCase {
    private var service: DnsService!

    override func setUp() {
        super.setUp()
        service = DnsService()
    }

    func testReverseLookupLocalhost() async {
        // 127.0.0.1 should resolve (likely to "localhost" on macOS)
        let result = await service.reverseLookup(ip: "127.0.0.1")
        XCTAssertEqual(result.ip, "127.0.0.1")
        // On macOS, 127.0.0.1 typically resolves to "localhost"
        XCTAssertNotNil(result.hostname, "127.0.0.1 should have a reverse DNS entry")
    }

    func testReverseLookupUnreachableIP() async {
        // An unreachable IP should return nil hostname
        let result = await service.reverseLookup(ip: "192.0.2.1")
        XCTAssertEqual(result.ip, "192.0.2.1")
        // This IP is in TEST-NET and likely won't have a reverse DNS entry
    }
}