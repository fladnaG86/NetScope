import SwiftUI

struct DeviceListView: View {
    @Bindable var viewModel: DeviceListViewModel
    let onStartScan: (String, ScanMode) -> Void

    @State private var subnet: String = "192.168.1.0/24"
    @State private var scanMode: ScanMode = .quick

    private var openPortCount: Int {
        viewModel.devices.reduce(0) { $0 + $1.ports.filter { $0.state == .open }.count }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Toolbar with scan button / progress
            HStack {
                TextField("Subnet", text: $subnet)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 200)

                Picker("Mode", selection: $scanMode) {
                    ForEach(ScanMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue.capitalized).tag(mode)
                    }
                }
                .frame(width: 100)

                if viewModel.isScanning {
                    ProgressView(value: viewModel.scanProgress)
                        .frame(width: 120)
                    Text("\(Int(viewModel.scanProgress * 100))%")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .frame(width: 40)

                    Button("Cancel") {
                        Task { await viewModel.cancelScan() }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Scan") {
                        onStartScan(subnet, scanMode)
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(!subnet.contains("/"))
                }

                Spacer()
            }
            .padding()

            Divider()

            // Device list or empty state
            if viewModel.devices.isEmpty && !viewModel.isScanning {
                ContentUnavailableView(
                    "No Devices",
                    systemImage: "desktopcomputer",
                    description: Text("Run a scan to discover devices")
                )
            } else {
                List(viewModel.devices) { device in
                    DeviceRow(device: device)
                        .contentShape(Rectangle())
                        .onTapGesture { viewModel.selectDevice(device) }
                }
            }

            // Status bar
            HStack {
                Text("\(viewModel.devices.count) devices")
                    .font(.caption)
                    .foregroundStyle(.secondary)
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
        .alert("Scan Error", isPresented: .constant(viewModel.error != nil), presenting: viewModel.error) { _ in
            Button("OK") { viewModel.error = nil }
        } message: { error in
            Text(error?.errorDescription ?? "")
        }
    }
}