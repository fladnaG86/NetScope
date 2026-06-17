import SwiftUI

struct StandaloneMtuView: View {
    let mtuService: MtuService?

    @State private var targetHost = ""
    @State private var result: MtuResult?
    @State private var isRunning = false
    @State private var error: String?

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                TextField("Target hostname or IP", text: $targetHost)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 280)

                Button { Task { await runMtuDiscovery() } } label: {
                    if isRunning {
                        ProgressView().controlSize(.small)
                        Text("Testing…")
                    } else {
                        Label("Discover", systemImage: "arrow.up.arrow.down.circle")
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

            if let result {
                GroupBox("MTU Path Discovery") {
                    VStack(alignment: .trailing, spacing: 8) {
                        LabeledContent("Target") { Text(result.host) }
                        LabeledContent("Path MTU") {
                            Text("\(result.mtu) bytes")
                                .font(.title2)
                                .foregroundStyle(.blue)
                        }
                    }
                    .padding()
                }
            }

            Spacer()
        }
        .padding()
        .frame(minWidth: 600, minHeight: 400)
    }

    private func runMtuDiscovery() async {
        let host = targetHost.trimmingCharacters(in: .whitespaces)
        guard let service = mtuService else {
            error = "MTU service not available"
            return
        }

        isRunning = true
        error = nil
        result = nil

        result = await service.discover(host: host)

        isRunning = false

        if result?.mtu == 0 {
            error = "Could not determine MTU for \(host)"
        }
    }
}