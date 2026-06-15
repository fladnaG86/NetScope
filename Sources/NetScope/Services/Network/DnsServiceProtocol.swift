import Foundation

struct DnsResult: Sendable {
    let ip: String
    let hostname: String?
}

protocol DnsServiceProtocol: Sendable {
    func reverseLookup(ip: String) async -> DnsResult
}