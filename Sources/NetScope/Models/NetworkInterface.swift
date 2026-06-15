import Foundation

struct NetworkInterface: Identifiable, Equatable {
    let id: UUID
    var name: String
    var ipAddress: String
    var subnetMask: String
    var gateway: String?
    var macAddress: String?
}