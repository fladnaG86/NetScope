import Foundation

final class MetricsController: Sendable {
    let pingService: any PingServiceProtocol
    let collector: MetricsCollectorActor
    let metricsRepository: any MetricsRepositoryProtocol

    init(
        pingService: any PingServiceProtocol,
        collector: MetricsCollectorActor,
        metricsRepository: any MetricsRepositoryProtocol
    ) {
        self.pingService = pingService
        self.collector = collector
        self.metricsRepository = metricsRepository
    }

    /// Collects metrics for a given host by pinging it N times at a specified interval,
    /// then calculating and persisting the resulting NetworkMetrics.
    func collectMetrics(
        for host: String,
        deviceId: UUID,
        samples: Int = 10,
        interval: TimeInterval = 1.0
    ) async throws -> NetworkMetrics? {
        await collector.clear()
        await collector.setDeviceId(deviceId)

        var failCount = 0

        for i in 0..<samples {
            do {
                let result = try await pingService.ping(host: host, timeout: 5.0)
                if result.isReachable, let latency = result.latencyMs {
                    await collector.addSample(latency)
                } else {
                    failCount += 1
                }
            } catch {
                failCount += 1
            }

            // Don't wait after the last sample
            if i < samples - 1 {
                try await Task.sleep(nanoseconds: UInt64(interval * 1_000_000_000))
            }
        }

        let sampleCount = await collector.sampleCount
        guard sampleCount > 0 else {
            throw MetricsError.insufficientSamples
        }

        guard let metrics = await collector.calculateMetrics(deviceId: deviceId) else {
            throw MetricsError.insufficientSamples
        }

        // Update packet loss based on failed pings
        let totalAttempts = samples
        let packetLoss = Double(failCount) / Double(totalAttempts)

        let finalMetrics = NetworkMetrics(
            id: metrics.id,
            deviceId: metrics.deviceId,
            timestamp: metrics.timestamp,
            latency: metrics.latency,
            jitter: metrics.jitter,
            packetLoss: packetLoss,
            qualityScore: metrics.qualityScore
        )

        try await metricsRepository.save(finalMetrics)

        return finalMetrics
    }
}