import XCTest
@testable import NetScope

final class MacVendorServiceTests: XCTestCase {
    private var service: MacVendorService!

    override func setUp() {
        super.setUp()
        // Use a test database instead of relying on bundle resource
        let testDB: [String: String] = [
            "AABBCC": "Test Vendor Inc.",
            "DDEEFF": "Another Corp",
            "112233": "Third Company Ltd",
        ]
        service = MacVendorService(ouiDatabase: testDB)
    }

    func testLookupKnownVendor() {
        let result = service.lookup(macAddress: "AA:BB:CC:DD:EE:FF")
        XCTAssertEqual(result, "Test Vendor Inc.")
    }

    func testLookupWithDashes() {
        let result = service.lookup(macAddress: "AA-BB-CC-DD-EE-FF")
        XCTAssertEqual(result, "Test Vendor Inc.")
    }

    func testLookupWithDots() {
        let result = service.lookup(macAddress: "AABB.CCDD.EEFF")
        // First 3 octets = AABBCC
        XCTAssertEqual(result, "Test Vendor Inc.")
    }

    func testLookupUnknownVendor() {
        let result = service.lookup(macAddress: "FF:FF:FF:00:00:00")
        XCTAssertNil(result)
    }

    func testLookupInvalidMac() {
        let result = service.lookup(macAddress: "invalid")
        XCTAssertNil(result)
    }

    func testLookupEmptyString() {
        let result = service.lookup(macAddress: "")
        XCTAssertNil(result)
    }

    func testDefaultInitDoesNotCrash() {
        // When oui_database.txt is not in the bundle, init() should not crash
        let defaultService = MacVendorService()
        _ = defaultService.lookup(macAddress: "AA:BB:CC:DD:EE:FF")
        // Result will be nil since no database is loaded, but it must not crash
        XCTAssertNotNil(defaultService as MacVendorServiceProtocol)
    }
}