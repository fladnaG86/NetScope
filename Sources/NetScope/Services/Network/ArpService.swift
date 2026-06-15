import Foundation

struct ArpService: ArpServiceProtocol {
    func resolve(ip: String) async -> ArpResult {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/usr/sbin/arp")
        process.arguments = ["-n", ip]
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return ArpResult(ip: ip, macAddress: nil)
        }

        if process.terminationStatus != 0 {
            return ArpResult(ip: ip, macAddress: nil)
        }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return ArpResult(ip: ip, macAddress: nil)
        }

        let macAddress = parseMacAddress(from: output)
        return ArpResult(ip: ip, macAddress: macAddress)
    }

    // MARK: - Private Helpers

    /// Parses output like: "host (192.168.1.1) at aa:bb:cc:dd:ee:ff on en0 ifscope [ethernet]"
    /// Also handles: "? (192.168.1.1) at aa:bb:cc:dd:ee:ff on en0 ifscope [ethernet]"
    private func parseMacAddress(from output: String) -> String? {
        // Match MAC address pattern: XX:XX:XX:XX:XX:XX
        let macPattern = "([0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2}:[0-9a-fA-F]{2})"
        guard let regex = try? NSRegularExpression(pattern: macPattern, options: []) else {
            return nil
        }

        let range = NSRange(output.startIndex..., in: output)
        if let match = regex.firstMatch(in: output, range: range),
           let macRange = Range(match.range(at: 1), in: output)
        {
            return String(output[macRange]).uppercased()
        }

        // Also handle "incomplete" or "(incomplete)" which means ARP resolution failed
        return nil
    }
}