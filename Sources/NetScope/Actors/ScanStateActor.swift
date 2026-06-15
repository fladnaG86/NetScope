import Foundation

actor ScanStateActor {
    private(set) var devices: [Device] = []
    private(set) var totalHosts: Int = 0
    private(set) var scannedHosts: Int = 0
    private(set) var isCancelled: Bool = false
    private(set) var isScanning: Bool = false

    var progress: Double {
        guard totalHosts > 0 else { return 0 }
        return Double(scannedHosts) / Double(totalHosts)
    }

    func startScan(totalHosts: Int) {
        devices = []
        scannedHosts = 0
        isCancelled = false
        isScanning = true
        self.totalHosts = totalHosts
    }

    func addDevice(_ device: Device) {
        // Upsert by IP: if a device with the same IP exists, update it
        if let index = devices.firstIndex(where: { $0.ip == device.ip }) {
            devices[index] = device
        } else {
            devices.append(device)
        }
    }

    func incrementScanned() {
        scannedHosts += 1
    }

    func setTotalHosts(_ count: Int) {
        totalHosts = count
    }

    func cancel() {
        isCancelled = true
    }

    func finishScan() {
        isScanning = false
    }
}