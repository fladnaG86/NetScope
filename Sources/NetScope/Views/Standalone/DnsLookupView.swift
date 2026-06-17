import SwiftUI

struct StandaloneDnsLookupView: View {
    let dnsService: (any DnsServiceProtocol)?
    let dnsDiagService: DnsDiagService?

    @State private var targetHost = ""
    @State private var reverseResult: DnsResult?
    @State private var diagResult: DnsDiagResult?
    @State private var isRunning = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {
            // Input
            HStack {
                TextField("IP address or hostname", text: $targetHost)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)

                Button { Task { await runDnsLookup() } } label: {
                    if isRunning {
                        ProgressView().controlSize(.small)
                        Text("Resolving…")
                    } else {
                        Label("Lookup", systemImage: "globe")
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

            // Forward resolution (DNS diag — resolves addresses)
            if let diag = diagResult {
                GroupBox("Resolution (\(diag.host))") {
                    VStack(alignment: .leading, spacing: 8) {
                        LabeledContent("Time") {
                            Text(String(format: "%.1f ms", diag.resolutionTimeMs))
                        }
                        LabeledContent("Addresses") {
                            VStack(alignment: .trailing) {
                                ForEach(diag.addresses, id: \.self) { addr in
                                    Text(addr)
                                        .font(.system(.body, design: .monospaced))
                                        .textSelection(.enabled)
                                }
                            }
                        }
                    }
                }
            }

            // Reverse lookup (hostname from IP)
            if let reverse = reverseResult, let hostname = reverse.hostname {
                GroupBox("Reverse Lookup") {
                    LabeledContent("Hostname") {
                        Text(hostname)
                            .textSelection(.enabled)
                    }
                }
            }

            if reverseResult != nil || diagResult != nil {
                HStack {
                    Button("Clear") {
                        diagResult = nil
                        reverseResult = nil
                        error = nil
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    private func runDnsLookup() async {
        let host = targetHost.trimmingCharacters(in: .whitespaces)
        isRunning = true
        error = nil
        diagResult = nil
        reverseResult = nil

        // Run both diag and reverse lookup
        async let diagTask = dnsDiagService?.diagnose(host: host)

        // For reverse lookup, try parsing as IP first
        let reverse: DnsResult? = await dnsService?.reverseLookup(ip: host)

        diagResult = await diagTask
        reverseResult = reverse

        isRunning = false

        if diagResult?.addresses.isEmpty == true && reverse == nil {
            error = "Could not resolve \(host)"
        }
    }
}
