import SwiftUI

struct MainWindow: View {
    @State private var selectedSidebarItem: SidebarItem? = .devices
    @State private var viewModel: DeviceListViewModel
    @State private var detailViewModel: DeviceDetailViewModel?

    private let scanController: ScanController
    private let scanState: ScanStateActor
    private let metricsController: MetricsController?
    private let traceRouteService: TraceRouteService?
    private let mtuService: MtuService?
    private let dnsDiagService: DnsDiagService?

    init(
        scanController: ScanController,
        scanState: ScanStateActor,
        metricsController: MetricsController? = nil,
        traceRouteService: TraceRouteService? = nil,
        mtuService: MtuService? = nil,
        dnsDiagService: DnsDiagService? = nil
    ) {
        self.scanController = scanController
        self.scanState = scanState
        self.metricsController = metricsController
        self.traceRouteService = traceRouteService
        self.mtuService = mtuService
        self.dnsDiagService = dnsDiagService
        self._viewModel = State(initialValue: DeviceListViewModel(
            scanController: scanController,
            scanState: scanState
        ))
    }

    var body: some View {
        NavigationSplitView {
            SidebarView(selectedItem: $selectedSidebarItem)
                .navigationTitle("NetScope")
        } detail: {
            switch selectedSidebarItem {
            case .devices:
                DeviceListView(viewModel: viewModel) { subnet, mode in
                    Task { await viewModel.startScan(subnet: subnet, mode: mode) }
                }
            case .ports, .traceroute, .latency, .jitter, .bandwidth, .dns, .mtu:
                Text("Coming soon")
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
        }
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