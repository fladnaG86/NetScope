import SwiftUI

struct AllPortsView: View {
    let devices: [Device]

    private struct PortWithDevice: Identifiable, Equatable {
        let id = UUID()
        let deviceIp: String
        let port: PortInfo
        var portNumber: Int { port.number }
        var sortService: String { port.service ?? "" }
        var sortTransport: String { port.transport.rawValue }
    }

    @State private var filterText = ""
    @State private var sortOrder = [KeyPathComparator(\PortWithDevice.portNumber, order: .forward)]

    private var allOpenPorts: [PortWithDevice] {
        devices.flatMap { device in
            device.ports.filter { $0.state == .open }.map { PortWithDevice(deviceIp: device.ip, port: $0) }
        }
    }

    private var filteredPorts: [PortWithDevice] {
        guard !filterText.isEmpty else { return allOpenPorts }
        let query = filterText.lowercased()
        return allOpenPorts.filter { item in
            item.deviceIp.lowercased().contains(query)
                || (item.port.service?.lowercased().contains(query) ?? false)
                || String(item.port.number).contains(query)
                || item.sortTransport.lowercased().contains(query)
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Open Ports")
                    .font(.headline)
                Spacer()
                if !allOpenPorts.isEmpty {
                    Text("\(allOpenPorts.count) open ports")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)

            // Filter bar
            if !allOpenPorts.isEmpty {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundStyle(.secondary)
                    TextField("Filter by IP, service, port…", text: $filterText)
                        .textFieldStyle(.roundedBorder)
                    if !filterText.isEmpty {
                        Button { filterText = "" } label: {
                            Image(systemName: "xmark.circle.fill")
                        }
                        .buttonStyle(.plain)
                        .foregroundStyle(.secondary)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 4)
            }

            Divider()

            // Content
            if allOpenPorts.isEmpty {
                ContentUnavailableView(
                    "No Open Ports",
                    systemImage: "bolt.horizontal",
                    description: Text("Run a deep scan to discover open ports on devices")
                )
            } else {
                let sorted = filteredPorts.sorted(using: sortOrder)
                Table(sorted, sortOrder: $sortOrder) {
                    TableColumn("Device") { item in
                        Text(item.deviceIp)
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(min: 130, ideal: 140)

                    TableColumn("Port", value: \.portNumber) { item in
                        Text("\(item.port.number)")
                            .font(.system(.body, design: .monospaced))
                    }
                    .width(min: 60, ideal: 70)

                    TableColumn("Protocol", value: \.sortTransport) { item in
                        Text(item.port.transport.rawValue.uppercased())
                    }
                    .width(min: 70, ideal: 80)

                    TableColumn("Service", value: \.sortService) { item in
                        Text(item.port.service ?? "unknown")
                            .foregroundStyle(.primary)
                    }
                    .width(min: 100, ideal: 120)
                }
                .tableStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
        .frame(minWidth: 700, minHeight: 400)
    }
}
