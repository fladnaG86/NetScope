import SwiftUI

struct MainWindow: View {
    @State private var selectedSidebarItem: SidebarItem? = .devices
    @State private var viewModel: DeviceListViewModel

    private let scanController: ScanController
    private let scanState: ScanStateActor

    init(scanController: ScanController, scanState: ScanStateActor) {
        self.scanController = scanController
        self.scanState = scanState
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
    }
}