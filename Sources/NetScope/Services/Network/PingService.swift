import Foundation

struct PingService: PingServiceProtocol {
    func ping(host: String, timeout: TimeInterval) async throws -> PingResult {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-c", "1", "-t", "\(Int(timeout))", host]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return PingResult(host: host, isReachable: false, latencyMs: nil)
        }

        let isReachable = process.terminationStatus == 0

        var latencyMs: Double? = nil
        if isReachable {
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                latencyMs = parseLatency(from: output)
            }
        }

        return PingResult(host: host, isReachable: isReachable, latencyMs: latencyMs)
    }

    // MARK: - Private Helpers

    /// Parses lines like: "round-trip min/avg/max/stddev = 0.045/0.062/0.089/0.017 ms"
    private func parseLatency(from output: String) -> Double? {
        let lines = output.components(separatedBy: .newlines)
        for line in lines {
            if line.contains("round-trip") || line.contains("rtt") {
                // Split on "=" to get the values part
                if let eqRange = line.range(of: "=") {
                    let valuesPart = String(line[eqRange.upperBound...]).trimmingCharacters(in: .whitespaces)
                    // Remove trailing "ms" if present
                    let cleaned = valuesPart.replacingOccurrences(of: "ms", with: "").trimmingCharacters(in: .whitespaces)
                    let components = cleaned.split(separator: "/").compactMap { Double($0.trimmingCharacters(in: .whitespaces)) }
                    // avg is the second value (min/avg/max/stddev)
                    if components.count >= 2 {
                        return components[1]
                    }
                }
            }
        }
        return nil
    }
}