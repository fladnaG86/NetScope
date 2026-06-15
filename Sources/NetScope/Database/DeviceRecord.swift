import Foundation
import GRDB

struct DeviceRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "devices"

    var id: String
    var ip: String
    var hostname: String?
    var macAddress: String?
    var vendor: String?
    var isOnline: Int
    var firstSeen: Date
    var lastSeen: Date
    var notes: String?

    enum CodingKeys: String, CodingKey {
        case id, ip, hostname
        case macAddress = "mac_address"
        case vendor
        case isOnline = "is_online"
        case firstSeen = "first_seen"
        case lastSeen = "last_seen"
        case notes
    }

    init(from device: Device) {
        self.id = device.id.uuidString
        self.ip = device.ip
        self.hostname = device.hostname
        self.macAddress = device.macAddress
        self.vendor = device.vendor
        self.isOnline = device.isOnline ? 1 : 0
        self.firstSeen = device.firstSeen
        self.lastSeen = device.lastSeen
        self.notes = device.notes
    }

    func toDevice(ports: [PortInfo]) -> Device {
        Device(
            id: UUID(uuidString: id)!,
            ip: ip,
            hostname: hostname,
            macAddress: macAddress,
            vendor: vendor,
            isOnline: isOnline != 0,
            firstSeen: firstSeen,
            lastSeen: lastSeen,
            ports: ports,
            notes: notes
        )
    }
}

struct PortRecord: Codable, FetchableRecord, PersistableRecord, Sendable {
    static let databaseTableName = "ports"

    var id: Int64?
    var deviceId: String
    var portNumber: Int
    var `protocol`: String
    var service: String?
    var state: String

    enum CodingKeys: String, CodingKey {
        case id
        case deviceId = "device_id"
        case portNumber = "port_number"
        case `protocol`
        case service
        case state
    }

    init(from portInfo: PortInfo, deviceId: UUID) {
        self.id = nil // auto-incremented
        self.deviceId = deviceId.uuidString
        self.portNumber = portInfo.number
        self.protocol = portInfo.transport.rawValue
        self.service = portInfo.service
        self.state = portInfo.state.rawValue
    }

    func toPortInfo() -> PortInfo {
        PortInfo(
            id: portNumber,
            number: portNumber,
            transport: TransportProtocol(rawValue: `protocol`)!,
            service: service,
            state: PortState(rawValue: state)!
        )
    }
}