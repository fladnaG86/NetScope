import SwiftUI

struct DiagnosticsTab: View {
    @Bindable var viewModel: DeviceDetailViewModel

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Action buttons
                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.runTraceroute() }
                    } label: {
                        Label("Run Traceroute", systemImage: "point.3.connected.trianglepath.dotted")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(viewModel.isRunningDiagnostics)

                    Button {
                        Task { await viewModel.runMtuDiscovery() }
                    } label: {
                        Label("MTU Discovery", systemImage: "arrow.up.arrow.down.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(viewModel.isRunningDiagnostics)

                    Button {
                        Task { await viewModel.runDnsDiag() }
                    } label: {
                        Label("DNS Diagnostics", systemImage: "globe")
                            .frame(maxWidth: .infinity)
                    }
                    .disabled(viewModel.isRunningDiagnostics)
                }
                .buttonStyle(.bordered)
                .padding(.horizontal)

                if viewModel.isRunningDiagnostics {
                    HStack {
                        ProgressView()
                            .controlSize(.small)
                        Text("Running diagnostics...")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                if let error = viewModel.diagnosticsError {
                    Text(error)
                        .foregroundStyle(.red)
                        .font(.caption)
                }

                // Traceroute results
                if let result = viewModel.traceRouteResult {
                    GroupBox("Traceroute to \(result.destination)") {
                        VStack(alignment: .leading) {
                            HStack {
                                Text("Reached destination:")
                                if result.reachedDestination {
                                    Image(systemName: "checkmark.circle.fill")
                                        .foregroundStyle(.green)
                                } else {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.red)
                                }
                            }
                            .font(.caption)
                            .padding(.bottom, 4)

                            if result.hops.isEmpty {
                                Text("No hops found")
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                            } else {
                                Table(result.hops) {
                                    TableColumn("Hop") { hop in
                                        Text("\(hop.id)")
                                    }
                                    TableColumn("Host") { hop in
                                        Text(hop.host ?? hop.ip)
                                    }
                                    TableColumn("IP") { hop in
                                        Text(hop.ip)
                                    }
                                    TableColumn("RTT 1") { hop in
                                        if let rtt = hop.rtt1 {
                                            Text("\(String(format: "%.1f", rtt)) ms")
                                        } else {
                                            Text("*")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    TableColumn("RTT 2") { hop in
                                        if let rtt = hop.rtt2 {
                                            Text("\(String(format: "%.1f", rtt)) ms")
                                        } else {
                                            Text("*")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    TableColumn("RTT 3") { hop in
                                        if let rtt = hop.rtt3 {
                                            Text("\(String(format: "%.1f", rtt)) ms")
                                        } else {
                                            Text("*")
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                }
                                .frame(minHeight: 100)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // MTU results
                if let result = viewModel.mtuResult {
                    GroupBox("MTU Discovery") {
                        LabeledContent("Host") {
                            Text(result.host)
                        }
                        LabeledContent("Path MTU") {
                            Text("\(result.mtu) bytes")
                        }
                    }
                    .padding(.horizontal)
                }

                // DNS diagnostics results
                if let result = viewModel.dnsDiagResult {
                    GroupBox("DNS Diagnostics") {
                        LabeledContent("Host") {
                            Text(result.host)
                        }
                        LabeledContent("Resolution Time") {
                            Text("\(String(format: "%.1f", result.resolutionTimeMs)) ms")
                        }
                        if let server = result.dnsServer {
                            LabeledContent("DNS Server") {
                                Text(server)
                            }
                        }
                        LabeledContent("Addresses") {
                            VStack(alignment: .trailing) {
                                ForEach(result.addresses, id: \.self) { addr in
                                    Text(addr)
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer()
            }
            .padding(.vertical)
        }
    }
}