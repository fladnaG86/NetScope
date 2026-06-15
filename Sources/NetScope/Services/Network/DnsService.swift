import Foundation

struct DnsService: DnsServiceProtocol {
    func reverseLookup(ip: String) async -> DnsResult {
        await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let hostname = self.performReverseLookup(ip: ip)
                continuation.resume(returning: DnsResult(ip: ip, hostname: hostname))
            }
        }
    }

    // MARK: - Private Helpers

    private func performReverseLookup(ip: String) -> String? {
        var hints = addrinfo()
        hints.ai_family = AF_INET
        hints.ai_socktype = SOCK_STREAM

        var result: UnsafeMutablePointer<addrinfo>?

        // First, resolve the IP to get the sockaddr
        let ret = getaddrinfo(ip, nil, &hints, &result)
        guard ret == 0, let addrInfo = result else {
            return nil
        }
        defer { freeaddrinfo(result) }

        // Perform reverse DNS lookup
        let addr = addrInfo.pointee.ai_addr
        var hostBuffer = [CChar](repeating: 0, count: Int(NI_MAXHOST))
        let nameRet = getnameinfo(
            addr,
            addrInfo.pointee.ai_addrlen,
            &hostBuffer,
            socklen_t(hostBuffer.count),
            nil,
            0,
            0 // no flags — attempt reverse lookup
        )

        guard nameRet == 0 else {
            return nil
        }

        let resolvedHost = String(cString: hostBuffer)

        // If the resolved hostname is the same as the IP, there's no PTR record
        if resolvedHost == ip {
            return nil
        }

        return resolvedHost
    }
}