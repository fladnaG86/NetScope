import Foundation

enum TransportProtocol: String, Codable, CaseIterable, Comparable {
    case tcp, udp

    static func < (lhs: TransportProtocol, rhs: TransportProtocol) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

enum PortState: String, Codable {
    case open, closed, filtered
}

struct PortInfo: Codable, Identifiable, Equatable {
    let id: Int // port number serves as id
    let number: Int
    let transport: TransportProtocol
    let service: String?
    let state: PortState

    var sortService: String { service ?? "" }
}