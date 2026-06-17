import SwiftUI

struct StandaloneTracerouteView: View {
    let traceRouteService: TraceRouteService?

    @State private var targetHost = ""
    @State private var result: TraceRouteResult?
    @State private var isRunning = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {
            // Input
            HStack {
                TextField("Target hostname or IP", text: $targetHost)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)

                Button { Task { await runTraceroute() } } label: {
                    if isRunning {
                        ProgressView().controlSize(.small)
                        Text("Running…")
                    } else {
                        Label("Run", systemImage: "point.3.connected.trianglepath.dotted")
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
            if let result {
                GroupBox("Traceroute to \(result.destination)") {
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Reached:")
                            Image(systemName: result.reachedDestination ? "checkmark.circle.fill" : "xmark.circle.fill")
                                .foregroundStyle(result.reachedDestination ? .green : .red)
                        }
                        .font(.caption)
                        .padding(.bottom, 4)

                        if result.hops.isEmpty {
                            Text("No hops reachable")
                                .foregroundStyle(.secondary)
                        } else {
                            HStack(spacing: 12) {
                                Text("Hop \(result.hops.count) reached")
                                    .font(.caption)
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text("Farthest: \(result.hops.last?.ip ?? "")")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.bottom, 4)

                            ScrollView {
                                VStack(alignment: .leading, spacing: 2) {
                                    ForEach(result.hops) { hop in
                                        HStack(spacing: 16) {
                                            Text(String(format: "%2d", hop.id))
                                                .font(.system(.caption, design: .monospaced))
                                                .foregroundStyle(.secondary)
                                                .frame(width: 24, alignment: .trailing)

                                            if let host = hop.host, !host.isEmpty {
                                                Text(host)
                                                    .font(.system(.caption, design: .monospaced))
                                                    .frame(minWidth: 150, maxWidth: 200, alignment: .leading)
                                            }

                                            Text(hop.ip)
                                                .font(.system(.caption, design: .monospaced))

                                            rttText(hop.rtt1)
                                            rttText(hop.rtt2)
                                            rttText(hop.rtt3)
                                        }
                                    }
                                }
                                .padding(.top, 4)
                            }
                            .frame(maxHeight: 250)
                        }
                    }
                }
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 700, minHeight: 400)
    }

    @ViewBuilder
    private func rttText(_ rtt: Double?) -> some View {
        if let rtt {
            Text(String(format: "%.1f ms", rtt))
                .font(.system(.caption, design: .monospaced))
        } else {
            Text("*")
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
        }
    }

    private func runTraceroute() async {
        let host = targetHost.trimmingCharacters(in: .whitespaces)
        guard let service = traceRouteService else {
            error = "Traceroute service not available"
            return
        }

        isRunning = true
        error = nil
        result = nil

        result = await service.trace(host: host)

        isRunning = false

        if let result, result.hops.isEmpty {
            error = "Could not reach \(host)"
        }
    }
}
