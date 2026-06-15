import Foundation

@Observable
final class MetricsViewModel {
    var metrics: NetworkMetrics?
    var isCollecting = false
    var error: MetricsError?

    private let controller: MetricsController

    init(controller: MetricsController) {
        self.controller = controller
    }

    func collect(for host: String, deviceId: UUID) async {
        self.isCollecting = true
        self.error = nil
        self.metrics = nil

        do {
            let result = try await controller.collectMetrics(for: host, deviceId: deviceId)
            self.metrics = result
        } catch let err as MetricsError {
            self.error = err
        } catch {
            self.error = MetricsError.pingFailed(host)
        }

        self.isCollecting = false
    }
}