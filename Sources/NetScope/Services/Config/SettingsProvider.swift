import Foundation

// MARK: - Protocol

protocol SettingsProviderProtocol: Sendable {
    var scanTimeout: TimeInterval { get }
    var maxConcurrentScans: Int { get }
}

// MARK: - UserDefaults-backed implementation

final class UserDefaultsSettingsProvider: SettingsProviderProtocol {
    var scanTimeout: TimeInterval {
        let v = UserDefaults.standard.double(forKey: "scan_timeout")
        return v > 0 ? v : 5.0
    }

    var maxConcurrentScans: Int {
        let v = UserDefaults.standard.integer(forKey: "max_concurrent_scans")
        return v > 0 ? v : 50
    }
}

// MARK: - In-memory implementation (for tests)

struct TestSettingsProvider: SettingsProviderProtocol {
    var scanTimeout: TimeInterval
    var maxConcurrentScans: Int

    static let quick: Self = .init(scanTimeout: 3.0, maxConcurrentScans: 100)
    static let slow: Self = .init(scanTimeout: 10.0, maxConcurrentScans: 10)
}
