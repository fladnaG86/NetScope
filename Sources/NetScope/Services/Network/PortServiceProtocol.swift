import Foundation

struct PortScanResult: Sendable {
    let host: String
    let ports: [PortInfo]
}

protocol PortServiceProtocol: Sendable {
    func scan(host: String, ports: [Int], timeout: TimeInterval) async -> PortScanResult
}