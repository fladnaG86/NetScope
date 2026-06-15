import Foundation

struct SubnetInfo: Sendable {
    let networkAddress: String
    let mask: String
    let broadcastAddress: String
    let hostRange: (start: String, end: String)
    let totalHosts: Int
}

protocol SubnetServiceProtocol: Sendable {
    func calculateSubnet(cidr: String) throws -> SubnetInfo
    func enumerateHosts(subnet: SubnetInfo) -> [String]
}