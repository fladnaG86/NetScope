import Foundation

enum QualityScore: String, Codable, CaseIterable {
    case excellent, good, fair, poor
}

struct LatencyStats: Codable, Equatable {
    let min: Double
    let max: Double
    let average: Double
    let median: Double
    let standardDeviation: Double
}

struct NetworkMetrics: Codable, Identifiable {
    let id: Int64? // GRDB row ID
    let deviceId: UUID
    let timestamp: Date
    let latency: LatencyStats
    let jitter: Double
    let packetLoss: Double // 0.0 - 1.0
    let qualityScore: QualityScore
}