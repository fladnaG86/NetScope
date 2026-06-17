import Foundation
import GRDB

struct MetricsRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "metrics"

    var id: Int64?
    var deviceId: String
    var latencyMin: Double?
    var latencyMax: Double?
    var latencyAvg: Double?
    var latencyMedian: Double?
    var latencyStddev: Double?
    var jitter: Double?
    var packetLoss: Double?
    var qualityScore: String
    var timestamp: Date

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case latencyMin = "latency_min"
        case latencyMax = "latency_max"
        case latencyAvg = "latency_avg"
        case latencyMedian = "latency_median"
        case latencyStddev = "latency_stddev"
        case jitter
        case packetLoss = "packet_loss"
        case qualityScore = "quality_score"
        case timestamp
    }

    init(from metrics: NetworkMetrics) {
        self.id = metrics.id
        self.deviceId = metrics.deviceId.uuidString
        self.latencyMin = metrics.latency.min
        self.latencyMax = metrics.latency.max
        self.latencyAvg = metrics.latency.average
        self.latencyMedian = metrics.latency.median
        self.latencyStddev = metrics.latency.standardDeviation
        self.jitter = metrics.jitter
        self.packetLoss = metrics.packetLoss
        self.qualityScore = metrics.qualityScore.rawValue
        self.timestamp = metrics.timestamp
    }

    func toMetrics() -> NetworkMetrics {
        NetworkMetrics(
            id: id,
            deviceId: UUID(uuidString: deviceId) ?? UUID(),
            timestamp: timestamp,
            latency: LatencyStats(
                min: latencyMin ?? 0,
                max: latencyMax ?? 0,
                average: latencyAvg ?? 0,
                median: latencyMedian ?? 0,
                standardDeviation: latencyStddev ?? 0
            ),
            jitter: jitter ?? 0,
            packetLoss: packetLoss ?? 0,
            qualityScore: QualityScore(rawValue: qualityScore) ?? .fair
        )
    }
}