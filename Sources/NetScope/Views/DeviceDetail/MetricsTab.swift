import SwiftUI

struct MetricsTab: View {
    @Bindable var viewModel: DeviceDetailViewModel

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Spacer()
                Button {
                    Task { await viewModel.runMetrics() }
                } label: {
                    if viewModel.isRunningDiagnostics {
                        ProgressView()
                            .controlSize(.small)
                        Text("Collecting...")
                    } else {
                        Label("Run Metrics", systemImage: "play.fill")
                    }
                }
                .disabled(viewModel.isRunningDiagnostics)
                .buttonStyle(.borderedProminent)
                Spacer()
            }

            if let error = viewModel.diagnosticsError {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            if let metrics = viewModel.metrics {
                QualityGauge(qualityScore: metrics.qualityScore)

                Grid(horizontalSpacing: 20, verticalSpacing: 8) {
                    GridRow {
                        Text("Min Latency").gridColumnAlignment(.trailing)
                        Text("\(String(format: "%.1f", metrics.latency.min)) ms")
                    }
                    GridRow {
                        Text("Max Latency")
                        Text("\(String(format: "%.1f", metrics.latency.max)) ms")
                    }
                    GridRow {
                        Text("Avg Latency")
                        Text("\(String(format: "%.1f", metrics.latency.average)) ms")
                    }
                    GridRow {
                        Text("Median")
                        Text("\(String(format: "%.1f", metrics.latency.median)) ms")
                    }
                    GridRow {
                        Text("Jitter")
                        Text("\(String(format: "%.2f", metrics.jitter)) ms")
                    }
                    GridRow {
                        Text("Packet Loss")
                        Text("\(String(format: "%.1f", metrics.packetLoss * 100))%")
                    }
                }
                .padding()
            } else {
                Spacer()
                ContentUnavailableView(
                    "No Metrics",
                    systemImage: "chart.line.flattrend.xyaxis",
                    description: Text("Run metrics collection to measure network performance")
                )
                Spacer()
            }
        }
        .padding()
    }
}