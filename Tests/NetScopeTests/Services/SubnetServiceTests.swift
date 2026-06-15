import XCTest
@testable import NetScope

final class SubnetServiceTests: XCTestCase {
    private var service: SubnetService!

    override func setUp() {
        super.setUp()
        service = SubnetService()
    }

    func testClassCSubnet() throws {
        // "192.168.1.0/24" -> 254 hosts, correct mask/broadcast
        let info = try service.calculateSubnet(cidr: "192.168.1.0/24")

        XCTAssertEqual(info.networkAddress, "192.168.1.0")
        XCTAssertEqual(info.mask, "255.255.255.0")
        XCTAssertEqual(info.broadcastAddress, "192.168.1.255")
        XCTAssertEqual(info.totalHosts, 254)
        XCTAssertEqual(info.hostRange.start, "192.168.1.1")
        XCTAssertEqual(info.hostRange.end, "192.168.1.254")
    }

    func testSmallSubnet() throws {
        // "192.168.1.0/30" -> 2 hosts
        let info = try service.calculateSubnet(cidr: "192.168.1.0/30")

        XCTAssertEqual(info.networkAddress, "192.168.1.0")
        XCTAssertEqual(info.mask, "255.255.255.252")
        XCTAssertEqual(info.broadcastAddress, "192.168.1.3")
        XCTAssertEqual(info.totalHosts, 2)
        XCTAssertEqual(info.hostRange.start, "192.168.1.1")
        XCTAssertEqual(info.hostRange.end, "192.168.1.2")
    }

    func testInvalidCIDR() {
        do {
            _ = try service.calculateSubnet(cidr: "invalid")
            XCTFail("Expected ScanError.subnetInvalid to be thrown")
        } catch let error as ScanError {
            if case .subnetInvalid(let value) = error {
                XCTAssertEqual(value, "invalid")
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testInvalidPrefixLength() {
        do {
            _ = try service.calculateSubnet(cidr: "192.168.1.0/33")
            XCTFail("Expected ScanError.subnetInvalid to be thrown")
        } catch let error as ScanError {
            if case .subnetInvalid = error {
                // expected
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testMissingPrefix() {
        do {
            _ = try service.calculateSubnet(cidr: "192.168.1.0")
            XCTFail("Expected ScanError.subnetInvalid to be thrown")
        } catch let error as ScanError {
            if case .subnetInvalid = error {
                // expected
            } else {
                XCTFail("Wrong error case: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func testEnumerateHostsClassC() throws {
        let info = try service.calculateSubnet(cidr: "192.168.1.0/24")
        let hosts = service.enumerateHosts(subnet: info)

        XCTAssertEqual(hosts.count, 254)
        XCTAssertEqual(hosts.first, "192.168.1.1")
        XCTAssertEqual(hosts.last, "192.168.1.254")
    }

    func testEnumerateHostsSmallSubnet() throws {
        let info = try service.calculateSubnet(cidr: "192.168.1.0/30")
        let hosts = service.enumerateHosts(subnet: info)

        XCTAssertEqual(hosts.count, 2)
        XCTAssertEqual(hosts[0], "192.168.1.1")
        XCTAssertEqual(hosts[1], "192.168.1.2")
    }

    func testEnumerateHostsCapAt1024() throws {
        // /20 = 4094 hosts, should be capped at 1024
        let info = try service.calculateSubnet(cidr: "192.168.0.0/20")
        let hosts = service.enumerateHosts(subnet: info)

        XCTAssertEqual(hosts.count, 1024)
    }
}