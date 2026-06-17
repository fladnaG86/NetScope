import SwiftUI

struct DiagnosticsTab: View {
    @Bindable var viewModel: DeviceDetailViewModel
    @State private var hopFilterText = ""
    @State private var hopSortOrder = [KeyPathComparator(\TraceRouteHop.id)]

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
                                hopFilterSection(hops: result.hops)
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

    // MARK: - Hop Filter

    private var filteredHops: [TraceRouteHop] {
        guard let result = viewModel.traceRouteResult else { return [] }
        guard !hopFilterText.isEmpty else { return result.hops }
        let query = hopFilterText.lowercased()
        return result.hops.filter { hop in
            "\(hop.id)".contains(query)
                || (hop.host?.lowercased().contains(query) ?? false)
                || hop.ip.lowercased().contains(query)
        }
    }

    private func hopFilterSection(hops: [TraceRouteHop]) -> some View {
        VStack(spacing: 0) {
            // Filter bar
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Filter hop, host, IP...", text: $hopFilterText)
                    .textFieldStyle(.roundedBorder)
                if !hopFilterText.isEmpty {
                    Button {
                        hopFilterText = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.secondary)
                }
                Text("\(filteredHops.count) of \(hops.count)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.horizontal)
            .padding(.vertical, 6)

            let sorted = filteredHops.sorted(using: hopSortOrder)
            Table(sorted, sortOrder: $hopSortOrder) {
                TableColumn("Hop", value: \.id) { hop in
                    Text("\(hop.id)")
                }
                .width(min: 40, ideal: 50)

                TableColumn("Host") { hop in
                    Text(hop.host ?? "—")
                        .foregroundStyle(hop.host != nil ? .primary : .tertiary)
                }
                .width(min: 120, ideal: 150)

                TableColumn("IP") { hop in
                    Text(hop.ip)
                        .font(.system(.body, design: .monospaced))
                }
                .width(min: 120, ideal: 140)

                TableColumn("RTT 1") { hop in
                    if let rtt = hop.rtt1 {
                        Text("\(String(format: "%.1f", rtt)) ms")
                    } else {
                        Text("*")
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 70, ideal: 80)

                TableColumn("RTT 2") { hop in
                    if let rtt = hop.rtt2 {
                        Text("\(String(format: "%.1f", rtt)) ms")
                    } else {
                        Text("*")
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 70, ideal: 80)

                TableColumn("RTT 3") { hop in
                    if let rtt = hop.rtt3 {
                        Text("\(String(format: "%.1f", rtt)) ms")
                    } else {
                        Text("*")
                            .foregroundStyle(.secondary)
                    }
                }
                .width(min: 70, ideal: 80)
            }
            .tableStyle(.inset(alternatesRowBackgrounds: true))
            .frame(minHeight: 100)
        }
    }
}