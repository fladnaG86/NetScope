import Foundation

enum ScanError: Error, LocalizedError, Equatable {
    case networkUnavailable
    case subnetInvalid(String)
    case permissionDenied
    case timeout(UUID)
    case cancelled

    var errorDescription: String? {
        switch self {
        case .networkUnavailable: return "Network unavailable"
        case .subnetInvalid(let subnet): return "Invalid subnet: \(subnet)"
        case .permissionDenied: return "Permission denied"
        case .timeout(let id): return "Scan timed out for device \(id)"
        case .cancelled: return "Scan cancelled"
        }
    }
}

enum MetricsError: Error, LocalizedError {
    case deviceNotFound
    case pingFailed(String)
    case insufficientSamples

    var errorDescription: String? {
        switch self {
        case .deviceNotFound: return "Device not found"
        case .pingFailed(let host): return "Ping failed for \(host)"
        case .insufficientSamples: return "Insufficient samples for metrics"
        }
    }
}

enum ExportError: Error, LocalizedError {
    case fileWriteFailed(URL)
    case noData
    case unsupportedFormat

    var errorDescription: String? {
        switch self {
        case .fileWriteFailed(let url): return "Failed to write file: \(url.path)"
        case .noData: return "No data to export"
        case .unsupportedFormat: return "Unsupported export format"
        }
    }
}