import Foundation
import Observation

@Observable
final class ScanConfigViewModel {
    var subnet: String = "192.168.1.0/24"
    var scanMode: ScanMode = .quick
    var timeout: TimeInterval = 5.0

    var isValid: Bool {
        subnet.contains("/") && subnet.split(separator: ".").count >= 3
    }
}