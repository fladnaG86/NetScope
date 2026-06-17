import SwiftUI

@main
struct NetScopeApp: App {
    // Services
    let subnetService = SubnetService()
    let networkInterfaceService = NetworkInterfaceService()
    let pingService = PingService()
    let arpService = ArpService()
    let dnsService = DnsService()
    let portService = PortService()
    let macVendorService = MacVendorService()

    // Diagnostic services
    let traceRouteService = TraceRouteService()
    let mtuService = MtuService()
    let dnsDiagService = DnsDiagService()

    // Actors
    let scanState = ScanStateActor()
    let deviceCache = DeviceCacheActor()
    let metricsCollector = MetricsCollectorActor()

    // Database
    let dbManager: DatabaseManager
    let deviceRepository: DeviceRepository
    let metricsRepository: MetricsRepository

    // Controllers
    let scanController: ScanController
    let metricsController: MetricsController

    init() {
        do {
            let db = try DatabaseManager()
            dbManager = db
            deviceRepository = try DeviceRepository(dbManager: db)
            metricsRepository = try MetricsRepository(dbManager: db)
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
            deviceRepository: deviceRepository,
            settings: UserDefaultsSettingsProvider()
        )
        metricsController = MetricsController(
            pingService: pingService,
            collector: metricsCollector,
            metricsRepository: metricsRepository
        )
    }

    var body: some Scene {
        WindowGroup {
            MainWindow(
                scanController: scanController,
                scanState: scanState,
                defaultSubnet: networkInterfaceService.detectDefaultSubnet(),
                metricsController: metricsController,
                traceRouteService: traceRouteService,
                mtuService: mtuService,
                dnsDiagService: dnsDiagService,
                bandwidthService: BandwidthService(),
                pingService: pingService,
                metricsCollector: metricsCollector,
                dnsService: dnsService
            )
        }
        .defaultSize(width: 900, height: 600)

        Settings {
            SettingsView()
        }
    }
}