import Foundation
import Observation

@Observable
final class DeviceListViewModel {
    var devices: [Device] = []
    var isScanning: Bool = false
    var error: ScanError?
    var scanProgress: Double = 0
    var selectedDevice: Device?

    private let scanController: ScanController?
    private let scanState: ScanStateActor?

    init(scanController: ScanController? = nil, scanState: ScanStateActor? = nil) {
        self.scanController = scanController
        self.scanState = scanState
    }

    func startScan(subnet: String, mode: ScanMode) async {
        guard let controller = scanController, let state = scanState else { return }
        self.isScanning = true
        self.error = nil
        self.devices = []
        do {
            try await controller.scan(subnet: subnet, mode: mode)
        } catch let scanError as ScanError {
            self.error = scanError
        } catch {
            self.error = ScanError.networkUnavailable
        }
        self.devices = await state.devices
        self.scanProgress = await state.progress
        self.isScanning = false
    }

    func cancelScan() async {
        await scanController?.cancelScan()
    }

    func selectDevice(_ device: Device?) {
        self.selectedDevice = device
    }
}