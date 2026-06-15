import Foundation

struct Device: Identifiable, Codable, Equatable {
    let id: UUID
    var ip: String
    var hostname: String?
    var macAddress: String?
    var vendor: String?
    var isOnline: Bool
    var firstSeen: Date
    var lastSeen: Date
    var ports: [PortInfo]
    var notes: String?

    init(
        id: UUID = UUID(),
        ip: String,
        hostname: String? = nil,
        macAddress: String? = nil,
        vendor: String? = nil,
        isOnline: Bool = true,
        firstSeen: Date = Date(),
        lastSeen: Date = Date(),
        ports: [PortInfo] = [],
        notes: String? = nil
    ) {
        self.id = id
        self.ip = ip
        self.hostname = hostname
        self.macAddress = macAddress
        self.vendor = vendor
        self.isOnline = isOnline
        self.firstSeen = firstSeen
        self.lastSeen = lastSeen
        self.ports = ports
        self.notes = notes
    }

    static func == (lhs: Device, rhs: Device) -> Bool {
        lhs.id == rhs.id
    }
}