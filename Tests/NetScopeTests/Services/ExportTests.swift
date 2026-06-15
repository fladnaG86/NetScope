import XCTest
@testable import NetScope

final class ExportTests: XCTestCase {
    private var testDevices: [Device]!
    private var tempDir: URL!

    override func setUp() {
        super.setUp()
        tempDir = FileManager.default.temporaryDirectory.appendingPathComponent("NetScopeExportTests-\(UUID().uuidString)")

        testDevices = [
            Device(
                id: UUID(),
                ip: "192.168.1.1",
                hostname: "router",
                macAddress: "AA:BB:CC:DD:EE:01",
                vendor: "Cisco",
                isOnline: true,
                firstSeen: Date(),
                lastSeen: Date(),
                ports: [PortInfo(id: 80, number: 80, transport: .tcp, service: "http", state: .open)],
                notes: "Main router"
            ),
            Device(
                id: UUID(),
                ip: "192.168.1.2",
                hostname: nil,
                macAddress: nil,
                vendor: nil,
                isOnline: false,
                firstSeen: Date().addingTimeInterval(-3600),
                lastSeen: Date().addingTimeInterval(-60),
                ports: [],
                notes: nil
            ),
        ]
    }

    override func tearDown() {
        if let tempDir = tempDir {
            try? FileManager.default.removeItem(at: tempDir)
        }
        super.tearDown()
    }

    // MARK: - CSV Export

    func testCsvExport() throws {
        let exporter = CsvExporter()
        XCTAssertEqual(exporter.formatName, "CSV")
        XCTAssertEqual(exporter.fileExtension, "csv")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let resultURL = try exporter.export(devices: testDevices, metrics: [], to: tempDir)

        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        XCTAssertEqual(resultURL.pathExtension, "csv")

        let content = try String(contentsOf: resultURL)
        XCTAssertTrue(content.hasPrefix("IP,Hostname,MAC,Vendor,Online,Ports,FirstSeen,LastSeen,Notes"))
        XCTAssertTrue(content.contains("192.168.1.1"))
        XCTAssertTrue(content.contains("router"))
        XCTAssertTrue(content.contains("Cisco"))
        XCTAssertTrue(content.contains("192.168.1.2"))
    }

    // MARK: - JSON Export

    func testJsonExport() throws {
        let exporter = JsonExporter()
        XCTAssertEqual(exporter.formatName, "JSON")
        XCTAssertEqual(exporter.fileExtension, "json")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let resultURL = try exporter.export(devices: testDevices, metrics: [], to: tempDir)

        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        XCTAssertEqual(resultURL.pathExtension, "json")

        let data = try Data(contentsOf: resultURL)
        let obj = try JSONSerialization.jsonObject(with: data) as? [String: Any]
        XCTAssertNotNil(obj)
        let devices = obj?["devices"] as? [[String: Any]]
        XCTAssertEqual(devices?.count, 2)
    }

    // MARK: - HTML Export

    func testHtmlExport() throws {
        let exporter = HtmlExporter()
        XCTAssertEqual(exporter.formatName, "HTML")
        XCTAssertEqual(exporter.fileExtension, "html")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)
        let resultURL = try exporter.export(devices: testDevices, metrics: [], to: tempDir)

        XCTAssertTrue(FileManager.default.fileExists(atPath: resultURL.path))
        XCTAssertEqual(resultURL.pathExtension, "html")

        let content = try String(contentsOf: resultURL)
        XCTAssertTrue(content.contains("<!DOCTYPE html>"))
        XCTAssertTrue(content.contains("<table>"))
        XCTAssertTrue(content.contains("192.168.1.1"))
        XCTAssertTrue(content.contains("router"))
        XCTAssertTrue(content.contains("Cisco"))
        XCTAssertTrue(content.contains("</table>"))
    }

    // MARK: - No Data

    func testExportNoDataThrows() {
        let exporter = CsvExporter()
        XCTAssertThrowsError(try exporter.export(devices: [], metrics: [], to: tempDir)) { error in
            if let exportError = error as? ExportError {
                switch exportError {
                case .noData: break // expected
                default: XCTFail("Expected .noData, got \(exportError)")
                }
            } else {
                XCTFail("Expected ExportError, got \(error)")
            }
        }
    }

    // MARK: - ExportController

    func testExportControllerCsv() throws {
        let mockRepo = MockDeviceRepository()
        let controller = ExportController(deviceRepository: mockRepo)
        let url = try controller.export(format: .csv, devices: testDevices, metrics: [])
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(url.pathExtension, "csv")

        // Clean up
        let parentDir = url.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: parentDir)
    }

    func testExportControllerJson() throws {
        let mockRepo = MockDeviceRepository()
        let controller = ExportController(deviceRepository: mockRepo)
        let url = try controller.export(format: .json, devices: testDevices, metrics: [])
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(url.pathExtension, "json")

        // Clean up
        let parentDir = url.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: parentDir)
    }

    func testExportControllerHtml() throws {
        let mockRepo = MockDeviceRepository()
        let controller = ExportController(deviceRepository: mockRepo)
        let url = try controller.export(format: .html, devices: testDevices, metrics: [])
        XCTAssertTrue(FileManager.default.fileExists(atPath: url.path))
        XCTAssertEqual(url.pathExtension, "html")

        // Clean up
        let parentDir = url.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: parentDir)
    }

    func testExportControllerNoDataThrows() {
        let mockRepo = MockDeviceRepository()
        let controller = ExportController(deviceRepository: mockRepo)
        XCTAssertThrowsError(try controller.export(format: .csv, devices: [], metrics: [])) { error in
            if let exportError = error as? ExportError {
                switch exportError {
                case .noData: break // expected
                default: XCTFail("Expected .noData, got \(exportError)")
                }
            } else {
                XCTFail("Expected ExportError, got \(error)")
            }
        }
    }
}

// MARK: - Mock

private final class MockDeviceRepository: DeviceRepositoryProtocol, Sendable {
    func save(_ device: Device) async throws {}
    func findById(_ id: UUID) async throws -> Device? { nil }
    func findAll() async throws -> [Device] { [] }
    func delete(_ id: UUID) async throws {}
    func deleteAll() async throws {}
}