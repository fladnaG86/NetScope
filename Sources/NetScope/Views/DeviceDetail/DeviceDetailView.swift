import SwiftUI

struct DeviceDetailView: View {
    @Bindable var viewModel: DeviceDetailViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(viewModel.device.hostname ?? viewModel.device.ip)
                        .font(.headline)
                    Text(viewModel.device.ip)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                        .font(.title2)
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.bar)

            Divider()

            TabView {
                OverviewTab(viewModel: viewModel)
                    .tabItem { Label("Overview", systemImage: "info.circle") }
                PortsTab(device: viewModel.device)
                    .tabItem { Label("Ports", systemImage: "externaldrive.connected.to.line.below") }
                MetricsTab(viewModel: viewModel)
                    .tabItem { Label("Metrics", systemImage: "chart.line.flattrend.xyaxis") }
                DiagnosticsTab(viewModel: viewModel)
                    .tabItem { Label("Diagnostics", systemImage: "stethoscope") }
            }
        }
        .frame(minWidth: 550, minHeight: 450)
    }
}

// MARK: - Overview Tab

struct OverviewTab: View {
    let viewModel: DeviceDetailViewModel
    let device: Device

    init(viewModel: DeviceDetailViewModel) {
        self.viewModel = viewModel
        self.device = viewModel.device
    }

    var body: some View {
        Form {
            Section("Device Information") {
                LabeledContent("IP Address") {
                    Text(device.ip)
                        .textSelection(.enabled)
                }
                if let hostname = device.hostname {
                    LabeledContent("Hostname") {
                        Text(hostname)
                            .textSelection(.enabled)
                    }
                }
                if let mac = device.macAddress {
                    LabeledContent("MAC Address") {
                        Text(mac)
                            .textSelection(.enabled)
                    }
                }
                if let vendor = device.vendor {
                    LabeledContent("Vendor") {
                        Text(vendor)
                            .textSelection(.enabled)
                    }
                }
            }

            Section("Status") {
                LabeledContent("Status") {
                    Label(
                        device.isOnline ? "Online" : "Offline",
                        systemImage: device.isOnline ? "circle.fill" : "circle"
                    )
                    .foregroundStyle(device.isOnline ? .green : .gray)
                }
                LabeledContent("First Seen") {
                    Text(device.firstSeen, style: .relative)
                }
                LabeledContent("Last Seen") {
                    Text(device.lastSeen, style: .relative)
                }
            }

            if let notes = device.notes, !notes.isEmpty {
                Section("Notes") {
                    Text(notes)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}