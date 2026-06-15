import SwiftUI

@main
struct NetScopeApp: App {
    // Services
    let subnetService = SubnetService()
    let pingService = PingService()
    let arpService = ArpService()
    let dnsService = DnsService()
    let portService = PortService()
    let macVendorService = MacVendorService()

    // Actors
    let scanState = ScanStateActor()
    let deviceCache = DeviceCacheActor()

    // Database
    let dbManager: DatabaseManager
    let deviceRepository: DeviceRepository

    // Controller
    let scanController: ScanController

    init() {
        do {
            let db = try DatabaseManager()
            dbManager = db
            deviceRepository = try DeviceRepository(dbManager: db)
        } catch {
            fatalError("Failed to initialize database: \(error)")
        }
        scanController = ScanController(
            subnetService: subnetService,
            pingService: pingService,
            arpService: arpService,
            dnsService: dnsService,
            portService: portService,
            macVendorService: macVendorService,
            scanState: scanState,
            deviceCache: deviceCache,
            deviceRepository: deviceRepository
        )
    }

    var body: some Scene {
        WindowGroup {
            MainWindow(scanController: scanController, scanState: scanState)
        }
        .defaultSize(width: 900, height: 600)
    }
}