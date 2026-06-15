import Foundation

struct BandwidthResult: Sendable {
    let host: String
    let bytesPerSecond: Double
    let duration: TimeInterval
}

struct BandwidthService: Sendable {
    /// Tests bandwidth to a given host using iperf3 if available.
    /// Falls back to a simple placeholder if iperf3 is not installed.
    func testBandwidth(host: String, port: Int = 5201, duration: TimeInterval = 10.0) async -> BandwidthResult? {
        // Check if iperf3 is available
        let whichProcess = Process()
        whichProcess.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        whichProcess.arguments = ["iperf3"]
        let whichPipe = Pipe()
        whichProcess.standardOutput = whichPipe
        whichProcess.standardError = Pipe()

        do {
            try whichProcess.run()
            whichProcess.waitUntilExit()
        } catch {
            return fallbackResult(host: host, duration: duration)
        }

        let whichData = whichPipe.fileHandleForReading.readDataToEndOfFile()
        let whichOutput = String(data: whichData, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard whichProcess.terminationStatus == 0 && !whichOutput.isEmpty else {
            return fallbackResult(host: host, duration: duration)
        }

        // Run iperf3 client test
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: whichOutput)
        process.arguments = ["-c", host, "-p", "\(port)", "-t", "\(Int(duration))", "-J"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return fallbackResult(host: host, duration: duration)
        }

        guard process.terminationStatus == 0 else {
            return fallbackResult(host: host, duration: duration)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return fallbackResult(host: host, duration: duration)
        }

        // Parse JSON output from iperf3
        return parseIperf3Json(output, host: host, duration: duration)
    }

    // MARK: - Private Helpers

    private func parseIperf3Json(_ json: String, host: String, duration: TimeInterval) -> BandwidthResult? {
        guard let jsonData = json.data(using: .utf8),
              let obj = try? JSONSerialization.jsonObject(with: jsonData) as? [String: Any],
              let end = obj["end"] as? [String: Any],
              let sum = end["sum_received"] as? [String: Any],
              let bitsPerSecond = sum["bits_per_second"] as? Double else {
            return fallbackResult(host: host, duration: duration)
        }

        let bytesPerSecond = bitsPerSecond / 8.0
        return BandwidthResult(host: host, bytesPerSecond: bytesPerSecond, duration: duration)
    }

    private func fallbackResult(host: String, duration: TimeInterval) -> BandwidthResult? {
        // Simple placeholder: iperf3 not available
        return nil
    }
}