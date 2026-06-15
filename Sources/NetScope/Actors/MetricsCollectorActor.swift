import Foundation

actor MetricsCollectorActor {
    private var samples: [Double] = []
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

    func setDeviceId(_ deviceId: UUID) {
        storedDeviceId = deviceId
    }

    func calculateMetrics(deviceId: UUID? = nil) -> NetworkMetrics? {
        guard !samples.isEmpty else { return nil }

        let deviceId = deviceId ?? storedDeviceId ?? UUID()
        let sorted = samples.sorted()

        let min = sorted.first!
        let max = sorted.last!
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

        // Quality score
        let qualityScore: QualityScore
        if average < 10 && jitter < 2 {
            qualityScore = .excellent
        } else if average < 50 && jitter < 10 {
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

        return NetworkMetrics(
            id: nil,
            deviceId: deviceId,
            timestamp: Date(),
            latency: latency,
            jitter: jitter,
            packetLoss: 0.0,
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