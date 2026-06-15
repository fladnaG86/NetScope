import SwiftUI

struct PortsTab: View {
    let device: Device

    var body: some View {
        Group {
            if device.ports.isEmpty {
                ContentUnavailableView(
                    "No Ports",
                    systemImage: "externaldrive.connected.to.line.below",
                    description: Text("No port information available for this device")
                )
            } else {
                Table(device.ports) {
                    TableColumn("Port") { port in
                        Text("\(port.number)")
                    }
                    TableColumn("Protocol") { port in
                        Text(port.transport.rawValue.uppercased())
                    }
                    TableColumn("Service") { port in
                        Text(port.service ?? "unknown")
                    }
                    TableColumn("State") { port in
                        Text(port.state.rawValue.capitalized)
                            .foregroundStyle(colorForState(port.state))
                    }
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