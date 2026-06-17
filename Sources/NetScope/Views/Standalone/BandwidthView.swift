import SwiftUI

struct StandaloneBandwidthView: View {
    let bandwidthService: BandwidthService?

    @State private var targetHost = "localhost"
    @State private var result: BandwidthResult?
    @State private var isRunning = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Target host (iperf3 server)", text: $targetHost)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)

                Button { Task { await runBandwidthTest() } } label: {
                    if isRunning {
                        ProgressView().controlSize(.small)
                        Text("Testing…")
                    } else {
                        Label("Test", systemImage: "gauge.with.dots.needle.67percent")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning || targetHost.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            Text("Note: Requires iperf3 running on the target host (default port 5201)")
                .font(.caption2)
                .foregroundStyle(.secondary)

            if let error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            if let result {
                GroupBox("Bandwidth Test Results") {
                    Grid(horizontalSpacing: 20, verticalSpacing: 8) {
                        GridRow {
                            Text("Target").gridColumnAlignment(.trailing)
                            Text(result.host)
                        }
                        GridRow {
                            Text("Duration").gridColumnAlignment(.trailing)
                            Text(String(format: "%.1f s", result.duration))
                        }
                        GridRow {
                            Text("Speed").gridColumnAlignment(.trailing)
                            Text(formatBytes(result.bytesPerSecond))
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                }
            } else {
                ContentUnavailableView(
                    "No Results",
                    systemImage: "gauge.with.dots.needle.67percent",
                    description: Text("Requires iperf3 server on the target host")
                )
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    private func formatBytes(_ bytes: Double) -> String {
        if bytes >= 1e9 {
            return String(format: "%.2f Gbps", bytes * 8 / 1e9)
        } else if bytes >= 1e6 {
            return String(format: "%.2f Mbps", bytes * 8 / 1e6)
        } else if bytes >= 1e3 {
            return String(format: "%.2f Kbps", bytes * 8 / 1e3)
        } else {
            return String(format: "%.0f bps", bytes * 8)
        }
    }

    private func runBandwidthTest() async {
        let host = targetHost.trimmingCharacters(in: .whitespaces)
        guard let service = bandwidthService else {
            error = "Bandwidth service not available"
            return
        }

        isRunning = true
        error = nil
        result = nil

        result = await service.testBandwidth(host: host)

        isRunning = false

        if result == nil {
            error = "iperf3 is not installed on this system. Install it with: brew install iperf3"
        }
    }
}
