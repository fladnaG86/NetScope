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

    // Sort-friendly computed properties (nil → empty string so they're Comparable)
    var sortHostname: String { hostname ?? "" }
    var sortMacAddress: String { macAddress ?? "" }
    var sortVendor: String { vendor ?? "" }
    var sortOpenPorts: Int { ports.filter { $0.state == .open }.count }
    var sortStatus: Int { isOnline ? 1 : 0 }
}