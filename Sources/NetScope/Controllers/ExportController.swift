import Foundation

enum ExportFormat: String, CaseIterable {
    case csv, json, html
}

final class ExportController: Sendable {
    let deviceRepository: any DeviceRepositoryProtocol

    init(deviceRepository: any DeviceRepositoryProtocol) {
        self.deviceRepository = deviceRepository
    }

    func export(format: ExportFormat, devices: [Device], metrics: [NetworkMetrics]) throws -> URL {
        guard !devices.isEmpty || !metrics.isEmpty else {
            throw ExportError.noData
        }

        let exporter: any ExporterProtocol = switch format {
        case .csv: CsvExporter()
        case .json: JsonExporter()
        case .html: HtmlExporter()
        }

        let tempDir = FileManager.default.temporaryDirectory
            .appendingPathComponent("NetScope Export \(UUID().uuidString)")

        try FileManager.default.createDirectory(at: tempDir, withIntermediateDirectories: true)

        do {
            let result = try exporter.export(devices: devices, metrics: metrics, to: tempDir)
            return result
        } catch let error as ExportError {
            throw error
        } catch {
            throw ExportError.fileWriteFailed(tempDir)
        }
    }
}