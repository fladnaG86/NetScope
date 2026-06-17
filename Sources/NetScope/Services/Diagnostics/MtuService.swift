import Foundation

struct MtuResult: Sendable {
    let host: String
    let mtu: Int
}

struct MtuService: Sendable {
    /// Discovers the path MTU to a given host using binary search.
    /// Uses `/sbin/ping -D -c 1 -s <size> <host>` to test DF (Don't Fragment) packets.
    /// Search range: 68-1500 (payload), add 28 for IP+ICMP header overhead.
    func discover(host: String) async -> MtuResult {
        let minPayload = 68
        let maxPayload = 1500
        var low = minPayload
        var high = maxPayload
        var bestMtu = low + 28 // IP+ICMP header overhead

        while low <= high {
            let mid = low + (high - low) / 2
            let fragmentOk = await pingWithDf(host: host, size: mid)

            if fragmentOk {
                bestMtu = mid + 28
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        return MtuResult(host: host, mtu: bestMtu)
    }

    // MARK: - Private Helpers

    /// Sends a single ping with DF bit set (-D) and specified payload size (-s).
    /// Returns true if the packet was delivered without fragmentation.
    private func pingWithDf(host: String, size: Int) async -> Bool {
        let process = Process()
        let pipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/sbin/ping")
        process.arguments = ["-D", "-c", "1", "-s", "\(size)", "-t", "5", host]
        process.standardOutput = pipe
        process.standardError = Pipe()

        let exitStatus = await AsyncProcess.run(process)
        // Exit code 0 = packet delivered without fragmentation
        // Exit code 2 = local error (often "message too long" when MTU exceeded)
        return exitStatus == 0
    }
}