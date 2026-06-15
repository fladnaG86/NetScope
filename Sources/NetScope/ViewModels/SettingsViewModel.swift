import Foundation
import Observation

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case italian = "it"

    var displayName: String {
        switch self {
        case .english: return "English"
        case .italian: return "Italiano"
        }
    }
}

@Observable
final class SettingsViewModel {
    var language: AppLanguage {
        didSet { UserDefaults.standard.set(language.rawValue, forKey: "app_language") }
    }

    var scanTimeout: TimeInterval {
        didSet { UserDefaults.standard.set(scanTimeout, forKey: "scan_timeout") }
    }

    var maxConcurrentScans: Int {
        didSet { UserDefaults.standard.set(maxConcurrentScans, forKey: "max_concurrent_scans") }
    }

    init() {
        let storedLanguage = UserDefaults.standard.string(forKey: "app_language")
        self.language = AppLanguage(rawValue: storedLanguage ?? "") ?? .english

        let storedTimeout = UserDefaults.standard.double(forKey: "scan_timeout")
        self.scanTimeout = storedTimeout > 0 ? storedTimeout : 5.0

        let storedConcurrent = UserDefaults.standard.integer(forKey: "max_concurrent_scans")
        self.maxConcurrentScans = storedConcurrent > 0 ? storedConcurrent : 50
    }
}