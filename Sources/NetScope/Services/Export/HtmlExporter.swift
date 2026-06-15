import Foundation

struct HtmlExporter: ExporterProtocol {
    let formatName = "HTML"
    let fileExtension = "html"

    func export(devices: [Device], metrics: [NetworkMetrics], to url: URL) throws -> URL {
        guard !devices.isEmpty || !metrics.isEmpty else {
            throw ExportError.noData
        }

        let fileURL = url.appendingPathComponent("export.\(fileExtension)")

        let dateFormatter = ISO8601DateFormatter()

        var html = """
        <!DOCTYPE html>
        <html lang="en">
        <head>
        <meta charset="UTF-8">
        <meta name="viewport" content="width=device-width, initial-scale=1.0">
        <title>NetScope Export</title>
        <style>
        body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; margin: 20px; background: #f9f9f9; }
        h1 { color: #333; }
        table { border-collapse: collapse; width: 100%; background: white; box-shadow: 0 1px 3px rgba(0,0,0,0.1); }
        th, td { border: 1px solid #ddd; padding: 10px 14px; text-align: left; }
        th { background-color: #4a90d9; color: white; font-weight: 600; }
        tr:nth-child(even) { background-color: #f2f2f2; }
        .online { color: #27ae60; font-weight: bold; }
        .offline { color: #c0392b; }
        </style>
        </head>
        <body>
        <h1>NetScope Device Export</h1>
        <table>
        <thead>
        <tr><th>IP</th><th>Hostname</th><th>MAC</th><th>Vendor</th><th>Status</th><th>Ports</th><th>First Seen</th><th>Last Seen</th><th>Notes</th></tr>
        </thead>
        <tbody>

        """

        for device in devices {
            let hostname = escapeHtml(device.hostname ?? "-")
            let mac = escapeHtml(device.macAddress ?? "-")
            let vendor = escapeHtml(device.vendor ?? "-")
            let statusClass = device.isOnline ? "online" : "offline"
            let statusText = device.isOnline ? "Online" : "Offline"
            let portsList = device.ports.map { "\($0.number)/\($0.transport.rawValue)" }.joined(separator: ", ")
            let firstSeen = dateFormatter.string(from: device.firstSeen)
            let lastSeen = dateFormatter.string(from: device.lastSeen)
            let notes = escapeHtml(device.notes ?? "-")

            html += "<tr>"
            html += "<td>\(device.ip)</td>"
            html += "<td>\(hostname)</td>"
            html += "<td>\(mac)</td>"
            html += "<td>\(vendor)</td>"
            html += "<td class=\"\(statusClass)\">\(statusText)</td>"
            html += "<td>\(portsList)</td>"
            html += "<td>\(firstSeen)</td>"
            html += "<td>\(lastSeen)</td>"
            html += "<td>\(notes)</td>"
            html += "</tr>\n"
        }

        html += """
        </tbody>
        </table>
        </body>
        </html>

        """

        do {
            try html.write(to: fileURL, atomically: true, encoding: .utf8)
        } catch {
            throw ExportError.fileWriteFailed(fileURL)
        }

        return fileURL
    }

    // MARK: - Private Helpers

    private func escapeHtml(_ string: String) -> String {
        string
            .replacingOccurrences(of: "&", with: "&amp;")
            .replacingOccurrences(of: "<", with: "&lt;")
            .replacingOccurrences(of: ">", with: "&gt;")
            .replacingOccurrences(of: "\"", with: "&quot;")
            .replacingOccurrences(of: "'", with: "&#39;")
    }
}