import XCTest
@testable import NetScope

final class DeviceTests: XCTestCase {

    // MARK: - Device

    func testDeviceCreationWithAllFields() {
        let id = UUID()
        let now = Date()
        let port = PortInfo(id: 80, number: 80, transport: .tcp, service: "http", state: .open)

        let device = Device(
            id: id,
            ip: "192.168.1.1",
            hostname: "router.local",
            macAddress: "AA:BB:CC:DD:EE:FF",
            vendor: "TestVendor",
            isOnline: true,
            firstSeen: now,
            lastSeen: now,
            ports: [port],
            notes: "Main router"
        )

        XCTAssertEqual(device.id, id)
        XCTAssertEqual(device.ip, "192.168.1.1")
        XCTAssertEqual(device.hostname, "router.local")
        XCTAssertEqual(device.macAddress, "AA:BB:CC:DD:EE:FF")
        XCTAssertEqual(device.vendor, "TestVendor")
        XCTAssertTrue(device.isOnline)
        XCTAssertEqual(device.firstSeen, now)
        XCTAssertEqual(device.lastSeen, now)
        XCTAssertEqual(device.ports.count, 1)
        XCTAssertEqual(device.ports.first?.number, 80)
        XCTAssertEqual(device.notes, "Main router")
    }

    func testDeviceCreationWithDefaults() {
        let device = Device(ip: "10.0.0.1")

        XCTAssertEqual(device.ip, "10.0.0.1")
        XCTAssertNil(device.hostname)
        XCTAssertNil(device.macAddress)
        XCTAssertNil(device.vendor)
        XCTAssertTrue(device.isOnline)
        XCTAssertTrue(device.ports.isEmpty)
        XCTAssertNil(device.notes)
    }

    func testDeviceIsIdentifiableByUniqueID() {
        let device1 = Device(ip: "192.168.1.1")
        let device2 = Device(ip: "192.168.1.1")

        // Same IP but different UUIDs — Identifiable ensures distinct identities
        XCTAssertNotEqual(device1.id, device2.id)
        XCTAssertNotEqual(device1, device2)
    }

    func testDeviceEqualityIsByIDOnly() {
        let id = UUID()
        let device1 = Device(id: id, ip: "192.168.1.1", hostname: "alpha")
        let device2 = Device(id: id, ip: "10.0.0.5", hostname: "beta")

        // Same id, different data — equal per the == override
        XCTAssertEqual(device1, device2)
    }

    // MARK: - PortInfo

    func testPortInfoCreation() {
        let port = PortInfo(id: 443, number: 443, transport: .tcp, service: "https", state: .open)

        XCTAssertEqual(port.id, 443)
        XCTAssertEqual(port.number, 443)
        XCTAssertEqual(port.transport, .tcp)
        XCTAssertEqual(port.service, "https")
        XCTAssertEqual(port.state, .open)
    }

    func testPortInfoWithoutService() {
        let port = PortInfo(id: 8080, number: 8080, transport: .tcp, service: nil, state: .filtered)

        XCTAssertNil(port.service)
        XCTAssertEqual(port.state, .filtered)
    }

    func testPortInfoUDP() {
        let port = PortInfo(id: 53, number: 53, transport: .udp, service: "dns", state: .open)

        XCTAssertEqual(port.transport, .udp)
    }

    // MARK: - QualityScore

    func testQualityScoreAllCases() {
        let cases = QualityScore.allCases
        XCTAssertEqual(cases.count, 4)
        XCTAssertTrue(cases.contains(.excellent))
        XCTAssertTrue(cases.contains(.good))
        XCTAssertTrue(cases.contains(.fair))
        XCTAssertTrue(cases.contains(.poor))
    }

    func testQualityScoreRawValues() {
        XCTAssertEqual(QualityScore.excellent.rawValue, "excellent")
        XCTAssertEqual(QualityScore.good.rawValue, "good")
        XCTAssertEqual(QualityScore.fair.rawValue, "fair")
        XCTAssertEqual(QualityScore.poor.rawValue, "poor")
    }

    // MARK: - ScanMode

    func testScanModeAllCases() {
        let cases = ScanMode.allCases
        XCTAssertEqual(cases.count, 2)
        XCTAssertTrue(cases.contains(.quick))
        XCTAssertTrue(cases.contains(.deep))
    }

    func testScanModeRawValues() {
        XCTAssertEqual(ScanMode.quick.rawValue, "quick")
        XCTAssertEqual(ScanMode.deep.rawValue, "deep")
    }
}