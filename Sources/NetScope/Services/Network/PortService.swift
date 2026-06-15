import Foundation
import Network

struct PortService: PortServiceProtocol {
    static let commonPorts: [Int: String] = [
        21: "FTP",
        22: "SSH",
        23: "Telnet",
        25: "SMTP",
        53: "DNS",
        80: "HTTP",
        110: "POP3",
        143: "IMAP",
        443: "HTTPS",
        445: "SMB",
        993: "IMAPS",
        995: "POP3S",
        3306: "MySQL",
        3389: "RDP",
        5432: "PostgreSQL",
        5900: "VNC",
        6379: "Redis",
        8080: "HTTP-Alt",
        8443: "HTTPS-Alt",
        27017: "MongoDB",
    ]

    func scan(host: String, ports: [Int], timeout: TimeInterval) async -> PortScanResult {
        let results = await withTaskGroup(of: PortInfo.self) { group in
            for port in ports {
                group.addTask {
                    await self.checkPort(host: host, port: port, timeout: timeout)
                }
            }

            var portInfos: [PortInfo] = []
            for await info in group {
                portInfos.append(info)
            }

            return portInfos.sorted { $0.number < $1.number }
        }

        return PortScanResult(host: host, ports: results)
    }

    // MARK: - Private Helpers

    private final class ResolvedFlag: @unchecked Sendable {
        private var _value = false
        private let lock = NSLock()

        /// Atomically sets the flag to true. Returns true if this call was the
        /// one that actually flipped the flag, false if it was already set.
        func trySetTrue() -> Bool {
            lock.lock()
            defer { lock.unlock() }
            if _value { return false }
            _value = true
            return true
        }
    }

    private func checkPort(host: String, port: Int, timeout: TimeInterval) async -> PortInfo {
        let hostEndpoint = NWEndpoint.Host(host)
        guard let portEndpoint = NWEndpoint.Port(rawValue: UInt16(port)) else {
            return PortInfo(
                id: port,
                number: port,
                transport: .tcp,
                service: Self.commonPorts[port],
                state: .closed
            )
        }
        let endpoint = NWEndpoint.hostPort(host: hostEndpoint, port: portEndpoint)

        let connection = NWConnection(to: endpoint, using: .tcp)
        let state = await withCheckedContinuation { (continuation: CheckedContinuation<PortState, Never>) in
            let resolved = ResolvedFlag()

            let timeoutTimer = DispatchSource.makeTimerSource(queue: .global())
            timeoutTimer.schedule(deadline: .now() + timeout)
            timeoutTimer.setEventHandler {
                guard resolved.trySetTrue() else { return }
                connection.cancel()
                continuation.resume(returning: PortState.filtered)
            }
            timeoutTimer.resume()

            connection.stateUpdateHandler = { newState in
                switch newState {
                case .ready:
                    guard resolved.trySetTrue() else { return }
                    timeoutTimer.cancel()
                    connection.cancel()
                    continuation.resume(returning: PortState.open)

                case .failed(let error):
                    guard resolved.trySetTrue() else { return }
                    timeoutTimer.cancel()
                    connection.cancel()

                    // ECONNREFUSED means the port is actively closed
                    let posixCode = error.errorCode
                    if posixCode == ECONNREFUSED {
                        continuation.resume(returning: PortState.closed)
                    } else {
                        continuation.resume(returning: PortState.filtered)
                    }

                case .cancelled:
                    // Already handled above
                    break

                default:
                    break
                }
            }

            connection.start(queue: .global())
        }

        return PortInfo(
            id: port,
            number: port,
            transport: .tcp,
            service: Self.commonPorts[port],
            state: state
        )
    }
}