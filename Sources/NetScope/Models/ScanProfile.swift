import Foundation

enum ScanMode: String, Codable, CaseIterable {
    case quick, deep
}

struct ScanProfile: Identifiable, Codable {
    let id: UUID
    var name: String
    var subnet: String
    var scanMode: ScanMode
    var customPorts: [Int]?
    var timeout: TimeInterval

    init(
        id: UUID = UUID(),
        name: String,
        subnet: String,
        scanMode: ScanMode = .quick,
        customPorts: [Int]? = nil,
        timeout: TimeInterval = 5.0
    ) {
        self.id = id
        self.name = name
        self.subnet = subnet
        self.scanMode = scanMode
        self.customPorts = customPorts
        self.timeout = timeout
    }
}