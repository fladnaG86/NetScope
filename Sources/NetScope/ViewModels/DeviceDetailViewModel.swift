import Foundation
import Observation

@Observable
final class DeviceDetailViewModel {
    var device: Device
    var metrics: NetworkMetrics?
    var traceRouteResult: TraceRouteResult?
    var mtuResult: MtuResult?
    var dnsDiagResult: DnsDiagResult?
    var isRunningDiagnostics = false
    var diagnosticsError: String?

    private let metricsController: MetricsController?
    private let traceRouteService: TraceRouteService?
    private let mtuService: MtuService?
    private let dnsDiagService: DnsDiagService?

    init(
        device: Device,
        metricsController: MetricsController? = nil,
        traceRouteService: TraceRouteService? = nil,
        mtuService: MtuService? = nil,
        dnsDiagService: DnsDiagService? = nil
    ) {
        self.device = device
        self.metricsController = metricsController
        self.traceRouteService = traceRouteService
        self.mtuService = mtuService
        self.dnsDiagService = dnsDiagService
    }

    func runMetrics() async {
        guard let controller = metricsController else {
            diagnosticsError = "Metrics service not available"
            return
        }
        isRunningDiagnostics = true
        diagnosticsError = nil
        do {
            metrics = try await controller.collectMetrics(
                for: device.ip,
                deviceId: device.id
            )
        } catch {
            diagnosticsError = error.localizedDescription
        }
        isRunningDiagnostics = false
    }

    func runTraceroute() async {
        guard let service = traceRouteService else {
            diagnosticsError = "Traceroute service not available"
            return
        }
        isRunningDiagnostics = true
        diagnosticsError = nil
        traceRouteResult = await service.trace(host: device.ip)
        isRunningDiagnostics = false
    }

    func runMtuDiscovery() async {
        guard let service = mtuService else {
            diagnosticsError = "MTU service not available"
            return
        }
        isRunningDiagnostics = true
        diagnosticsError = nil
        mtuResult = await service.discover(host: device.ip)
        isRunningDiagnostics = false
    }

    func runDnsDiag() async {
        guard let service = dnsDiagService else {
            diagnosticsError = "DNS diagnostics service not available"
            return
        }
        isRunningDiagnostics = true
        diagnosticsError = nil
        dnsDiagResult = await service.diagnose(host: device.ip)
        isRunningDiagnostics = false
    }
}