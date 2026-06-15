import Foundation

struct PingResult: Sendable {
    let host: String
    let isReachable: Bool
    let latencyMs: Double?
}

protocol PingServiceProtocol: Sendable {
    func ping(host: String, timeout: TimeInterval) async throws -> PingResult
}