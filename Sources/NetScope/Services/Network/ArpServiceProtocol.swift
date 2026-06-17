import Foundation

struct ArpResult: Sendable {
    let ip: String
    let macAddress: String?
}

protocol ArpServiceProtocol: Sendable {
    /// Resolve a single IP's MAC address (reads full table each time)
    func resolve(ip: String) async -> ArpResult
    /// Read the entire ARP table once: [IP: MAC]
    func resolveAll() async -> [String: String]
}