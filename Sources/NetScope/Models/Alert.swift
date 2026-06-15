import Foundation

enum AlertSeverity: String, Codable, CaseIterable {
    case info, warning, critical
}

enum AlertType: String, Codable {
    case highLatency, packetLoss, deviceOffline, newDevice
}

struct DeviceAlert: Identifiable, Codable {
    let id: UUID
    let deviceId: UUID
    let type: AlertType
    let severity: AlertSeverity
    let message: String
    let timestamp: Date
    var isAcknowledged: Bool
}