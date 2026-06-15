import SwiftUI

struct DeviceRow: View {
    let device: Device

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(device.isOnline ? Color.green : Color.gray)
                .frame(width: 8, height: 8)

            VStack(alignment: .leading, spacing: 2) {
                Text(device.hostname ?? device.ip)
                    .font(.body)
                if device.hostname != nil {
                    Text(device.ip)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let vendor = device.vendor {
                Text(vendor)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text("\(device.ports.filter { $0.state == .open }.count) ports")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
    }
}