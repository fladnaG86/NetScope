import Foundation

protocol MacVendorServiceProtocol: Sendable {
    func lookup(macAddress: String) -> String?
}