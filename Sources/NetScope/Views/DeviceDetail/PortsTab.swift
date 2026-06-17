import SwiftUI

struct PortsTab: View {
    let device: Device
    @State private var filterText = ""
    @State private var sortOrder = [KeyPathComparator(\PortInfo.number)]

    private var filteredPorts: [PortInfo] {
        guard !filterText.isEmpty else { return device.ports }
        let query = filterText.lowercased()
        return device.ports.filter { port in
            "\(port.number)".contains(query)
                || port.transport.rawValue.lowercased().contains(query)
                || (port.service?.lowercased().contains(query) ?? false)
                || port.state.rawValue.lowercased().contains(query)
        }
    }

    var body: some View {
        Group {
            if device.ports.isEmpty {
                ContentUnavailableView(
                    "No Ports",
                    systemImage: "externaldrive.connected.to.line.below",
                    description: Text("Run a Deep scan to discover open ports")
                )
            } else {
                VStack(spacing: 0) {
                    // Filter bar
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundStyle(.secondary)
                        TextField("Filter port, service, state...", text: $filterText)
                            .textFieldStyle(.roundedBorder)
                        if !filterText.isEmpty {
                            Button {
                                filterText = ""
                            } label: {
                                Image(systemName: "xmark.circle.fill")
                            }
                            .buttonStyle(.plain)
                            .foregroundStyle(.secondary)
                        }
                        Text("\(filteredPorts.count) of \(device.ports.count)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 6)

                    let sorted = filteredPorts.sorted(using: sortOrder)
                    Table(sorted, sortOrder: $sortOrder) {
                        TableColumn("Port", value: \.number) { port in
                            Text("\(port.number)")
                                .font(.system(.body, design: .monospaced))
                        }
                        .width(min: 60, ideal: 70)

                        TableColumn("Protocol", value: \.transport) { port in
                            Text(port.transport.rawValue.uppercased())
                        }
                        .width(min: 70, ideal: 80)

                        TableColumn("Service", value: \.sortService) { port in
                            Text(port.service ?? "—")
                                .foregroundStyle(port.service != nil ? .primary : .tertiary)
                        }
                        .width(min: 100, ideal: 120)

                        TableColumn("State") { port in
                            Text(port.state.rawValue.capitalized)
                                .foregroundStyle(colorForState(port.state))
                        }
                        .width(min: 70, ideal: 80)
                    }
                    .tableStyle(.inset(alternatesRowBackgrounds: true))
                }
            }
        }
        .padding()
    }

    private func colorForState(_ state: PortState) -> Color {
        switch state {
        case .open: return .green
        case .closed: return .red
        case .filtered: return .orange
        }
    }
}