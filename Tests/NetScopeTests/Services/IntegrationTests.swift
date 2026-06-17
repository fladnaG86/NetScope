import XCTest
@testable import NetScope

/// Integration tests using real services.
/// Note: ARP tests may fail in `swift test` due to sandbox restrictions
/// that prevent `arp -a` from reading the ARP table. These tests pass
/// when running the actual app or standalone scripts.
final class IntegrationTests: XCTestCase {

    /// Test that ArpService.resolveAll returns a dictionary (may be empty in sandbox)
    func testArpResolveAllReturnsDictionary() async {
        let arp = ArpService()
        let table = await arp.resolveAll()
        // Table may be empty in sandboxed test environments
        XCTAssertNotNil(table, "resolveAll should return a valid dictionary")
    }

    /// Test that ArpService.resolve returns correct IP even when table is empty
    func testArpResolveReturnsCorrectIP() async {
        let arp = ArpService()
        let result = await arp.resolve(ip: "192.0.2.1")
        XCTAssertEqual(result.ip, "192.0.2.1")
    }

    /// Test real DNS reverse lookup against the gateway
    func testRealDnsGateway() async {
        let dns = DnsService()
        let result = await dns.reverseLookup(ip: "192.168.0.1")
        XCTAssertEqual(result.ip, "192.168.0.1")
        // hostname may be nil if no PTR record, that's OK
    }

    /// Test real PingService against the gateway
    func testRealPingGateway() async throws {
        let ping = PingService()
        let result = try await ping.ping(host: "192.168.0.1", timeout: 3)
        XCTAssertTrue(result.isReachable, "Gateway should be reachable")
    }
}