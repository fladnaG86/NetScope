import Foundation

struct SubnetInfo: Sendable {
    let networkAddress: String
    let mask: String
    let broadcastAddress: String
    let hostRange: (start: String, end: String)
    let totalHosts: Int
    var truncated: Bool = false
}

protocol SubnetServiceProtocol: Sendable {
    func calculateSubnet(cidr: String) throws -> SubnetInfo
    func parseTarget(_ target: String) throws -> SubnetInfo
    func enumerateHosts(subnet: SubnetInfo) -> [String]
}