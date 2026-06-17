import SwiftUI

struct DeviceListView: View {
    @Bindable var viewModel: DeviceListViewModel

    @State private var scanConfig = ScanConfigViewModel()
    @State private var subnet: String = ""
    @State private var showError = false
    @State private var sortOrder = [KeyPathComparator(\Device.ip)]
    @State private var selectedDeviceID: UUID?

    private var openPortCount: Int {
        viewModel.devices.reduce(0) { $0 + $1.ports.filter { $0.state == .open }.count }
    }

    private var progressPercent: Int {
        Int(viewModel.scanProgress * 100)
    }

    private var errorMessage: String {
        viewModel.error?.errorDescription ?? "Unknown error"
    }

    private var scanModeDescription: String {
        switch scanConfig.scanMode {
        case .quick:
            return "Quick — Ping + ARP + DNS (no port scan)"
        case .deep:
            return "Deep — Includes 18-port scan (slower)"
        }
    }

    private var scanModeColor: Color {
        switch scanConfig.scanMode {
        case .quick: return .green
        case .deep: return .orange
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with scan button / progress
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    TextField("192.168.1.1-254", text: $subnet)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 220)

                    Picker("Mode", selection: $scanConfig.scanMode) {
                        ForEach(ScanMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue.capitalized).tag(mode)
                        }
                    }
                    .frame(width: 110)

                    // Mode badge
                    Text(scanModeDescription)
                        .font(.caption2)
                        .foregroundStyle(scanModeColor)
                        .lineLimit(1)

                    if viewModel.isScanning {
                        ProgressView(value: viewModel.scanProgress)
                            .frame(width: 120)
                        Text("\(progressPercent)%")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 40)

                        Button(role: .destructive) {
                            viewModel.cancelScan()
                        } label: {
                            Label("Stop", systemImage: "stop.fill")
                        }
                        .buttonStyle(.bordered)
                        .tint(.red)
                    } else {
                        Button("Scan") {
                            viewModel.startScan(subnet: subnet, mode: scanConfig.scanMode)
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(!scanConfig.isValid(subnet: subnet))
                    }

                    Spacer()
                }

                Text("Formats: 192.168.1.1-254  ·  192.168.1.1-192.168.1.254  ·  192.168.1.0/24  ·  single IP")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
            .padding()

            // Search/filter bar
            if !viewModel.devices.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Filter by IP, hostname, MAC, vendor...", text: $viewModel.filterText)
                        .textFieldStyle(.roundedBorder)
                    if !viewModel.filterText.isEmpty {
                        Button {
                            viewModel.filterText = ""
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 4)
            }

            Divider()

            // Device table or empty state
            if viewModel.devices.isEmpty && !viewModel.isScanning {
                ContentUnavailableView(
                    "No Devices",
                    systemImage: "desktopcomputer",
                    description: Text("Run a scan to discover devices")
                )
            } else {
                deviceTable
            }

            // Status bar
            HStack {
                Text("\(viewModel.devices.count) devices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                if !viewModel.filterText.isEmpty {
                    Text("(\(viewModel.filteredDevices.count) shown)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                if !viewModel.devices.isEmpty {
                    Text("\(openPortCount) open ports")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if viewModel.isScanning {
                    Text("Scanning...")
                        .font(.caption)
                        .foregroundStyle(.blue)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 6)
            .background(.bar)
        }
        .onAppear {
            if subnet.isEmpty {
                subnet = viewModel.defaultSubnet
            }
        }
        .onChange(of: viewModel.defaultSubnet) { _, newValue in
            if subnet.isEmpty || subnet == "192.168.1.0/24" {
                subnet = newValue
            }
        }
        .onChange(of: viewModel.error) { _, newError in
            showError = newError != nil
        }
        .alert("Scan Error", isPresented: $showError) {
            Button("OK") { viewModel.error = nil }
        } message: {
            Text(errorMessage)
        }
    }

    // MARK: - Device Table

    private var deviceTable: some View {
        let sorted = viewModel.sortedDevices(using: sortOrder)
        return Table(sorted, selection: $selectedDeviceID, sortOrder: $sortOrder) {
            TableColumn("IP", value: \.ip) { device in
                ipCell(device)
            }
            .width(min: 130, ideal: 140)

            TableColumn("Hostname", value: \.sortHostname) { device in
                hostnameCell(device)
            }
            .width(min: 120, ideal: 150)

            TableColumn("MAC Address", value: \.sortMacAddress) { device in
                macCell(device)
            }
            .width(min: 150, ideal: 160)

            TableColumn("Vendor", value: \.sortVendor) { device in
                vendorCell(device)
            }
            .width(min: 100, ideal: 140)

            TableColumn("Ports", value: \.sortOpenPorts) { device in
                portsCell(device)
            }
            .width(min: 70, ideal: 80)

            TableColumn("Status", value: \.sortStatus) { device in
                statusCell(device)
            }
            .width(min: 80, ideal: 90)
        }
        .tableStyle(.inset(alternatesRowBackgrounds: true))
        .onChange(of: selectedDeviceID) { _, newID in
            if let newID,
               let device = viewModel.devices.first(where: { $0.id == newID }) {
                viewModel.selectDevice(device)
            }
        }
    }

    private func ipCell(_ device: Device) -> some View {
        Text(device.ip)
            .font(.system(.body, design: .monospaced))
    }

    private func hostnameCell(_ device: Device) -> some View {
        Text(device.hostname ?? "—")
            .foregroundStyle(device.hostname != nil ? .primary : .tertiary)
    }

    private func macCell(_ device: Device) -> some View {
        Text(device.macAddress ?? "—")
            .font(.system(.body, design: .monospaced))
            .foregroundStyle(device.macAddress != nil ? .primary : .tertiary)
    }

    private func vendorCell(_ device: Device) -> some View {
        Text(device.vendor ?? "—")
            .foregroundStyle(device.vendor != nil ? .primary : .tertiary)
    }

    private func portsCell(_ device: Device) -> some View {
        let openCount = device.ports.filter { $0.state == .open }.count
        return Group {
            if openCount > 0 {
                Text("\(openCount) open")
                    .foregroundStyle(.green)
            } else {
                Text("—")
                    .foregroundStyle(.tertiary)
            }
        }
    }

    private func statusCell(_ device: Device) -> some View {
        HStack(spacing: 4) {
            Circle()
                .fill(device.isOnline ? Color.green : Color.gray)
                .frame(width: 8, height: 8)
            Text(device.isOnline ? "Online" : "Offline")
                .foregroundStyle(device.isOnline ? .green : .secondary)
        }
    }
}