import Foundation

struct ArpResult: Sendable {
    let ip: String
    let macAddress: String?
}

protocol ArpServiceProtocol: Sendable {
    func resolve(ip: String) async -> ArpResult
}