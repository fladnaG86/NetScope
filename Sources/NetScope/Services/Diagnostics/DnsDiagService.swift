import Foundation

struct DnsDiagResult: Sendable {
    let host: String
    let resolutionTimeMs: Double
    let addresses: [String]
    let dnsServer: String?
}

struct DnsDiagService: Sendable {
    /// Diagnoses DNS resolution for a given host using POSIX getaddrinfo.
    func diagnose(host: String) async -> DnsDiagResult {
        let startTime = CFAbsoluteTimeGetCurrent()

        var addresses: [String] = []

        var hints = addrinfo()
        hints.ai_family = AF_UNSPEC
        hints.ai_socktype = SOCK_STREAM

        var result: UnsafeMutablePointer<addrinfo>?
        let status = getaddrinfo(host, nil, &hints, &result)

        let elapsed = (CFAbsoluteTimeGetCurrent() - startTime) * 1000.0

        if status == 0, let resultPtr = result {
            defer { freeaddrinfo(resultPtr) }

            var current: UnsafeMutablePointer<addrinfo>? = resultPtr
            while let ptr = current {
                var addressBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                let nameStatus = getnameinfo(
                    ptr.pointee.ai_addr,
                    socklen_t(ptr.pointee.ai_addrlen),
                    &addressBuffer,
                    socklen_t(addressBuffer.count),
                    nil,
                    0,
                    NI_NUMERICHOST
                )
                if nameStatus == 0 {
                    let addressStr = String(cString: addressBuffer)
                    if !addresses.contains(addressStr) {
                        addresses.append(addressStr)
                    }
                }
                current = ptr.pointee.ai_next
            }
        }

        return DnsDiagResult(
            host: host,
            resolutionTimeMs: elapsed,
            addresses: addresses,
            dnsServer: nil
        )
    }
}