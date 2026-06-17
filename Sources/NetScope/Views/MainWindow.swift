import SwiftUI

struct MainWindow: View {
    @State private var selectedSidebarItem: SidebarItem? = .devices
    @State private var viewModel: DeviceListViewModel
    @State private var detailViewModel: DeviceDetailViewModel?

    private let scanController: ScanController
    private let scanState: ScanStateActor
    private let defaultSubnet: String
    private let metricsController: MetricsController?
    private let traceRouteService: TraceRouteService?
    private let mtuService: MtuService?
    private let dnsDiagService: DnsDiagService?
    private let bandwidthService: BandwidthService?
    private let pingService: (any PingServiceProtocol)?
    private let metricsCollector: MetricsCollectorActor?
    private let dnsService: (any DnsServiceProtocol)?

    init(
        scanController: ScanController,
        scanState: ScanStateActor,
        defaultSubnet: String = "192.168.1.0/24",
        metricsController: MetricsController? = nil,
        traceRouteService: TraceRouteService? = nil,
        mtuService: MtuService? = nil,
        dnsDiagService: DnsDiagService? = nil,
        bandwidthService: BandwidthService? = nil,
        pingService: (any PingServiceProtocol)? = nil,
        metricsCollector: MetricsCollectorActor? = nil,
        dnsService: (any DnsServiceProtocol)? = nil
    ) {
        self.scanController = scanController
        self.scanState = scanState
        self.defaultSubnet = defaultSubnet
        self.metricsController = metricsController
        self.traceRouteService = traceRouteService
        self.mtuService = mtuService
        self.dnsDiagService = dnsDiagService
        self.bandwidthService = bandwidthService
        self.pingService = pingService
        self.metricsCollector = metricsCollector
        self.dnsService = dnsService
        self._viewModel = State(initialValue: DeviceListViewModel(
            scanController: scanController,
            scanState: scanState,
            defaultSubnet: defaultSubnet
        ))
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedSidebarItem)
                .navigationTitle("NetScope")
        } detail: {
            switch selectedSidebarItem {
            case .devices:
                DeviceListView(viewModel: viewModel)
            case .ports:
                AllPortsView(devices: devicesFromState)
            case .traceroute:
                StandaloneTracerouteView(traceRouteService: traceRouteService)
            case .latency, .jitter:
                StandaloneLatencyView(
                    pingService: pingService,
                    metricsCollector: metricsCollector
                )
            case .bandwidth:
                StandaloneBandwidthView(bandwidthService: bandwidthService)
            case .dns:
                StandaloneDnsLookupView(
                    dnsService: dnsService,
                    dnsDiagService: dnsDiagService
                )
            case .mtu:
                StandaloneMtuView(mtuService: mtuService)
            case .none:
                ContentUnavailableView(
                    "NetScope",
                    systemImage: "network",
                    description: Text("Select an item from the sidebar")
                )
            }
        }
        .frame(minWidth: 800, minHeight: 500)
        .sheet(item: $viewModel.selectedDevice) { device in
            DeviceDetailView(viewModel: makeDetailViewModel(for: device))
                .frame(minWidth: 600, minHeight: 450)
        }
    }

    private var devicesFromState: [Device] {
        // We read devices from the ViewModel since it polls scanState
        viewModel.devices
    }

    private func makeDetailViewModel(for device: Device) -> DeviceDetailViewModel {
        DeviceDetailViewModel(
            device: device,
            metricsController: metricsController,
            traceRouteService: traceRouteService,
            mtuService: mtuService,
            dnsDiagService: dnsDiagService
        )
    }
}