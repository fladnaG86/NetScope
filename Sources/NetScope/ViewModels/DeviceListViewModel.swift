import Foundation
import Observation

@Observable
final class DeviceListViewModel {
    var devices: [Device] = []
    var isScanning: Bool = false
    var error: ScanError?
    var scanProgress: Double = 0
    var selectedDevice: Device?
    var defaultSubnet: String
    var filterText: String = ""

    var filteredDevices: [Device] {
        let base: [Device]
        if filterText.isEmpty {
            base = devices
        } else {
            let query = filterText.lowercased()
            base = devices.filter { device in
                device.ip.lowercased().contains(query)
                    || (device.hostname?.lowercased().contains(query) ?? false)
                    || (device.macAddress?.lowercased().contains(query) ?? false)
                    || (device.vendor?.lowercased().contains(query) ?? false)
            }
        }
        return base
    }

    func sortedDevices(using comparators: [KeyPathComparator<Device>]) -> [Device] {
        filteredDevices.sorted(using: comparators)
    }

    private let scanController: ScanController?
    private let scanState: ScanStateActor?
    private var pollTask: Task<Void, Never>?
    private var scanTask: Task<Void, Never>?

    init(scanController: ScanController? = nil, scanState: ScanStateActor? = nil, defaultSubnet: String = "192.168.1.0/24") {
        self.scanController = scanController
        self.scanState = scanState
        self.defaultSubnet = defaultSubnet
    }

    func startScan(subnet: String, mode: ScanMode) {
        guard let controller = scanController, let state = scanState else { return }
        self.isScanning = true
        self.error = nil
        self.devices = []
        self.scanProgress = 0

        startPolling(state)

        scanTask = Task { [weak self] in
            guard let self else { return }
            do {
                try await controller.scan(subnet: subnet, mode: mode)
            } catch let scanError as ScanError {
                if scanError != .cancelled {
                    self.error = scanError
                }
            } catch {
                self.error = ScanError.networkUnavailable
            }

            self.stopPolling()

            // Final state sync
            self.devices = await state.devices
            self.scanProgress = await state.progress
            self.isScanning = false
            self.scanTask = nil
        }
    }

    func cancelScan() {
        scanTask?.cancel()
        scanTask = nil
        Task { [weak self] in
            guard let self, let scanState else { return }
            await scanState.cancel()
            self.stopPolling()
            self.devices = await scanState.devices
            self.scanProgress = await scanState.progress
            self.isScanning = false
        }
    }

    func selectDevice(_ device: Device?) {
        self.selectedDevice = device
    }

    // MARK: - Real-time Polling

    private func startPolling(_ state: ScanStateActor) {
        pollTask?.cancel()
        pollTask = Task { [weak self] in
            while !Task.isCancelled {
                guard let self else { return }
                self.devices = await state.devices
                self.scanProgress = await state.progress
                try? await Task.sleep(for: .milliseconds(200))
            }
        }
    }

    private func stopPolling() {
        pollTask?.cancel()
        pollTask = nil
    }
}