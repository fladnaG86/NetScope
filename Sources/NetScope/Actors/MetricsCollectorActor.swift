import Foundation

actor MetricsCollectorActor {
    private var samples: [Double] = []
    private var failedPings: Int = 0
    private let maxSamples: Int
    private var storedDeviceId: UUID?

    init(maxSamples: Int = 100) {
        self.maxSamples = maxSamples
    }

    func addSample(_ latencyMs: Double) {
        samples.append(latencyMs)
        if samples.count > maxSamples {
            samples.removeFirst(samples.count - maxSamples)
        }
    }

    func addFailedPing() {
        failedPings += 1
    }

    func setDeviceId(_ deviceId: UUID) {
        storedDeviceId = deviceId
    }

    func calculateMetrics(deviceId: UUID? = nil) -> NetworkMetrics? {
        guard !samples.isEmpty else { return nil }

        let deviceId = storedDeviceId ?? deviceId ?? UUID()
        let sorted = samples.sorted()

        let min = sorted[0]
        let max = sorted[sorted.count - 1]
        let average = samples.reduce(0, +) / Double(samples.count)

        // Median
        let median: Double
        if sorted.count % 2 == 0 {
            median = (sorted[sorted.count / 2 - 1] + sorted[sorted.count / 2]) / 2.0
        } else {
            median = sorted[sorted.count / 2]
        }

        // Standard deviation
        let variance = samples.reduce(0) { acc, val in acc + (val - average) * (val - average) } / Double(samples.count)
        let standardDeviation = sqrt(variance)

        // Jitter = standard deviation (simplified)
        let jitter = standardDeviation

        // Packet loss: ratio of failed pings to total attempts
        let totalAttempts = samples.count + failedPings
        let packetLoss = totalAttempts > 0 ? Double(failedPings) / Double(totalAttempts) : 0.0

        // Quality score (factors in latency, jitter, AND packet loss)
        let qualityScore: QualityScore
        if packetLoss > 0.5 {
            qualityScore = .poor
        } else if packetLoss > 0.2 {
            qualityScore = .fair
        } else if average < 10 && jitter < 2 && packetLoss < 0.05 {
            qualityScore = .excellent
        } else if average < 50 && jitter < 10 && packetLoss < 0.1 {
            qualityScore = .good
        } else if average < 100 && jitter < 30 {
            qualityScore = .fair
        } else {
            qualityScore = .poor
        }

        let latency = LatencyStats(
            min: min,
            max: max,
            average: average,
            median: median,
            standardDeviation: standardDeviation
        )

        // Reset failed pings counter after calculation
        failedPings = 0

        return NetworkMetrics(
            id: nil,
            deviceId: deviceId,
            timestamp: Date(),
            latency: latency,
            jitter: jitter,
            packetLoss: packetLoss,
            qualityScore: qualityScore
        )
    }

    func clear() {
        samples.removeAll()
        storedDeviceId = nil
    }

    var sampleCount: Int {
        samples.count
    }
}