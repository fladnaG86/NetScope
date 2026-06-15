import Foundation

struct TraceRouteHop: Sendable, Identifiable {
    let id: Int        // hop number
    let host: String?
    let ip: String
    let rtt1: Double?
    let rtt2: Double?
    let rtt3: Double?
}

struct TraceRouteResult: Sendable {
    let hops: [TraceRouteHop]
    let destination: String
    let reachedDestination: Bool
}

struct TraceRouteService: Sendable {
    func trace(host: String, maxHops: Int = 30) async -> TraceRouteResult {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/sbin/traceroute")
        process.arguments = ["-m", "\(maxHops)", host]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return TraceRouteResult(hops: [], destination: host, reachedDestination: false)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return TraceRouteResult(hops: [], destination: host, reachedDestination: false)
        }

        let lines = output.components(separatedBy: .newlines)
        var hops: [TraceRouteHop] = []
        var reachedDestination = false

        for line in lines {
            if line.contains("traceroute to") || line.isEmpty {
                continue
            }
            if let hop = parseHopLine(line) {
                hops.append(hop)
                if hop.ip == host || hop.host == host {
                    reachedDestination = true
                }
            }
        }

        // If last hop IP matches destination, we reached it
        if let lastHop = hops.last, lastHop.ip == host {
            reachedDestination = true
        }

        return TraceRouteResult(hops: hops, destination: host, reachedDestination: reachedDestination)
    }

    // MARK: - Private Helpers

    /// Parses traceroute output lines like:
    /// " 1  router (192.168.1.1)  0.456 ms  0.321 ms  0.289 ms"
    /// " 2  * * *"
    /// " 3  10.0.0.1  1.234 ms  1.567 ms  1.890 ms"
    private func parseHopLine(_ line: String) -> TraceRouteHop? {
        let trimmed = line.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return nil }

        let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
        guard let hopNumber = Int(parts[0]) else { return nil }

        // Check for "* * *" (unreachable hop)
        if parts.count >= 3 && parts[1] == "*" && parts[2] == "*" {
            return TraceRouteHop(
                id: hopNumber,
                host: nil,
                ip: "*",
                rtt1: nil,
                rtt2: nil,
                rtt3: nil
            )
        }

        // Parse host/ip and RTT values
        var host: String?
        var ip: String = ""
        var rtt1: Double?
        var rtt2: Double?
        var rtt3: Double?

        // Find the IP address in parentheses if present (e.g., "router (192.168.1.1)")
        if let parenRange = line.range(of: "("), let closeParen = line.range(of: ")", options: [], range: parenRange.upperBound..<line.endIndex) {
            host = String(line[line.index(after: line.range(of: " ", options: [], range: line.startIndex..<parenRange.lowerBound)!.upperBound)..<parenRange.lowerBound]).trimmingCharacters(in: .whitespaces)
            ip = String(line[parenRange.upperBound..<closeParen.lowerBound])
        } else {
            // No parentheses, the second token is the IP
            if parts.count > 1 {
                ip = String(parts[1])
            }
        }

        // Extract RTT values (numbers followed by "ms")
        let msPattern = #"(\d+\.\d+)\s*ms"#
        guard let regex = try? NSRegularExpression(pattern: msPattern) else {
            return TraceRouteHop(id: hopNumber, host: host, ip: ip, rtt1: nil, rtt2: nil, rtt3: nil)
        }
        let matches = regex.matches(in: line, range: NSRange(line.startIndex..., in: line))
        if matches.count >= 1, let range = Range(matches[0].range(at: 1), in: line) {
            rtt1 = Double(String(line[range]))
        }
        if matches.count >= 2, let range = Range(matches[1].range(at: 1), in: line) {
            rtt2 = Double(String(line[range]))
        }
        if matches.count >= 3, let range = Range(matches[2].range(at: 1), in: line) {
            rtt3 = Double(String(line[range]))
        }

        return TraceRouteHop(id: hopNumber, host: host, ip: ip, rtt1: rtt1, rtt2: rtt2, rtt3: rtt3)
    }
}