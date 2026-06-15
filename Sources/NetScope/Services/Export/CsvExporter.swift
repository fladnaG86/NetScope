import Foundation

struct CsvExporter: ExporterProtocol {
    let formatName = "CSV"
    let fileExtension = "csv"

    func export(devices: [Device], metrics: [NetworkMetrics], to url: URL) throws -> URL {
        guard !devices.isEmpty || !metrics.isEmpty else {
            throw ExportError.noData
        }

        let fileURL = url.appendingPathComponent("export.\(fileExtension)")
        var lines: [String] = []

        // Header
        lines.append("IP,Hostname,MAC,Vendor,Online,Ports,FirstSeen,LastSeen,Notes")

        // Data rows
        let dateFormatter = ISO8601DateFormatter()
        for device in devices {
            let hostname = device.hostname ?? ""
            let mac = device.macAddress ?? ""
            let vendor = device.vendor ?? ""
            let online = device.isOnline ? "true" : "false"
            let portsList = device.ports.map { "\($0.number)" }.joined(separator: ";")
            let firstSeen = dateFormatter.string(from: device.firstSeen)
            let lastSeen = dateFormatter.string(from: device.lastSeen)
            let notes = (device.notes ?? "").replacingOccurrences(of: "\"", with: "\"\"")

            let line: String
            if notes.contains(",") || notes.contains("\"") || notes.contains("\n") {
                line = "\(device.ip),\"\(hostname)\",\(mac),\"\(vendor)\",\(online),\"\(portsList)\",\(firstSeen),\(lastSeen),\"\(notes)\""
            } else {
                line = "\(device.ip),\(hostname),\(mac),\(vendor),\(online),\(portsList),\(firstSeen),\(lastSeen),\(notes)"
            }
            lines.append(line)
        }

        let content = lines.joined(separator: "\n")
        do {
            try content.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.fileWriteFailed(fileURL)
        }

        return fileURL
    }
}