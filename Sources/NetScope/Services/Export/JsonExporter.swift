import Foundation

struct JsonExporter: ExporterProtocol {
    let formatName = "JSON"
    let fileExtension = "json"

    func export(devices: [Device], metrics: [NetworkMetrics], to url: URL) throws -> URL {
        guard !devices.isEmpty || !metrics.isEmpty else {
            throw ExportError.noData
        }

        let fileURL = url.appendingPathComponent("export.\(fileExtension)")

        struct ExportPayload: Encodable {
            let devices: [Device]
            let metrics: [NetworkMetrics]
        }

        let payload = ExportPayload(devices: devices, metrics: metrics)

        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        encoder.dateEncodingStrategy = .iso8601

        let data: Data
        do {
            data = try encoder.encode(payload)
        } catch {
            throw ExportError.fileWriteFailed(fileURL)
        }

        do {
            try data.write(to: fileURL)
        } catch {
            throw ExportError.fileWriteFailed(fileURL)
        }

        return fileURL
    }
}