import Foundation

protocol ExporterProtocol: Sendable {
    var formatName: String { get }
    var fileExtension: String { get }
    func export(devices: [Device], metrics: [NetworkMetrics], to url: URL) throws -> URL
}