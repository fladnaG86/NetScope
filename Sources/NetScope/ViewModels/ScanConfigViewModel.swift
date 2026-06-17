import Foundation
import Observation

@Observable
final class ScanConfigViewModel {
    var scanMode: ScanMode = .quick
    var timeout: TimeInterval = 5.0

    func isValid(subnet: String) -> Bool {
        let trimmed = subnet.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }

        // CIDR: 192.168.1.0/24
        if trimmed.contains("/") {
            let parts = trimmed.split(separator: "/")
            guard parts.count == 2,
                  let prefix = Int(parts[1]),
                  prefix >= 0, prefix <= 32,
                  parts[0].split(separator: ".").count == 4
            else { return false }
            return parts[0].split(separator: ".").allSatisfy { Int($0) != nil }
        }

        // Range: 192.168.1.1-254 or 192.168.1.1-192.168.1.254
        if let dashRange = trimmed.range(of: "-", options: .literal) {
            let startPart = String(trimmed[trimmed.startIndex..<dashRange.lowerBound])
            let endPart = String(trimmed[dashRange.upperBound..<trimmed.endIndex])
            let startOctets = startPart.split(separator: ".").compactMap { Int($0) }
            guard startOctets.count == 4,
                  startOctets.allSatisfy({ $0 >= 0 && $0 <= 255 })
            else { return false }
            let endOctets = endPart.split(separator: ".").compactMap { Int($0) }
            if endOctets.count == 1 {
                return endOctets[0] >= 0 && endOctets[0] <= 255
            } else if endOctets.count == 4 {
                return endOctets.allSatisfy { $0 >= 0 && $0 <= 255 }
            }
            return false
        }

        // Single IP: 192.168.1.1
        let octets = trimmed.split(separator: ".").compactMap { Int($0) }
        return octets.count == 4 && octets.allSatisfy { $0 >= 0 && $0 <= 255 }
    }
}