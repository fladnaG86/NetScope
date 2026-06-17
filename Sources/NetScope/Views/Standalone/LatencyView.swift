import SwiftUI

struct StandaloneLatencyView: View {
    let pingService: (any PingServiceProtocol)?
    let metricsCollector: MetricsCollectorActor?

    @State private var targetHost = ""
    @State private var currentMetrics: NetworkMetrics?
    @State private var isRunning = false
    @State private var error: String?
    @State private var jitterValue: Double = 0
    @State private var sampleCount = 0

    var body: some View {
        VStack(spacing: 16) {
            // Input
            HStack {
                TextField("Target hostname or IP", text: $targetHost)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)

                Button { Task { await runLatencyTest() } } label: {
                    if isRunning {
                        ProgressValueView()
                        Text("Testing…")
                    } else {
                        Label("Run Test", systemImage: "clock")
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isRunning || targetHost.trimmingCharacters(in: .whitespaces).isEmpty)
            }

            if let error {
                Text(error)
                    .foregroundStyle(.red)
                    .font(.caption)
            }

            // Results
            if let metrics = currentMetrics {
                QualityGauge(qualityScore: metrics.qualityScore)

                Grid(horizontalSpacing: 20, verticalSpacing: 8) {
                    GridRow {
                        Text("Average Latency").gridColumnAlignment(.trailing)
                        Text(String(format: "%.1f ms", metrics.latency.average))
                    }
                    GridRow {
                        Text("Min Latency").gridColumnAlignment(.trailing)
                        Text(String(format: "%.1f ms", metrics.latency.min))
                    }
                    GridRow {
                        Text("Max Latency").gridColumnAlignment(.trailing)
                        Text(String(format: "%.1f ms", metrics.latency.max))
                    }
                    GridRow {
                        Text("Jitter").gridColumnAlignment(.trailing)
                        Text(String(format: "%.2f ms", metrics.jitter))
                    }
                    GridRow {
                        Text("Packet Loss").gridColumnAlignment(.trailing)
                        Text(String(format: "%.1f%%", metrics.packetLoss * 100))
                    }
                    GridRow {
                        Text("Samples").gridColumnAlignment(.trailing)
                        Text("\(sampleCount)")
                    }
                }
                .padding()
            } else {
                ContentUnavailableView(
                    "No Data",
                    systemImage: "clock",
                    description: Text("Enter a target host and run a latency test (10 pings)")
                )
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    private func runLatencyTest() async {
        let host = targetHost.trimmingCharacters(in: .whitespaces)
        guard let ping = pingService else {
            error = "Ping service not available"
            return
        }
        guard let collector = metricsCollector else {
            error = "Metrics collector not available"
            return
        }

        isRunning = true
        error = nil
        currentMetrics = nil
        sampleCount = 0
        jitterValue = 0

        await collector.clear()
        await collector.setDeviceId(UUID())

        var failCount = 0
        let samples = 10

        for i in 0..<samples {
            if Task.isCancelled { break }

            do {
                let result = try await ping.ping(host: host, timeout: 5.0)
                if result.isReachable, let latency = result.latencyMs {
                    await collector.addSample(latency)
                    sampleCount += 1
                } else {
                    failCount += 1
                    await collector.addFailedPing()
                }
            } catch {
                failCount += 1
                await collector.addFailedPing()
            }

            if i < samples - 1 {
                try? await Task.sleep(for: .seconds(1))
            }
        }

        if await collector.sampleCount > 0,
           let metrics = await collector.calculateMetrics(deviceId: UUID()) {
            let packetLoss = Double(failCount) / Double(samples)
            currentMetrics = NetworkMetrics(
                id: metrics.id,
                deviceId: metrics.deviceId,
                timestamp: metrics.timestamp,
                latency: metrics.latency,
                jitter: metrics.jitter,
                packetLoss: packetLoss,
                qualityScore: metrics.qualityScore
            )
        } else {
            error = "No successful ping samples collected"
        }

        isRunning = false
    }
}

// MARK: - Progress Display

struct ProgressValueView: View {
    var body: some View {
        ProgressView()
            .controlSize(.small)
            .transition(.opacity)
    }
}
