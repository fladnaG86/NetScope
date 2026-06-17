import Foundation
import Network

struct NetworkInterfaceInfo {
    let interfaceName: String
    let ipAddress: String
    let prefixLength: Int
    var cidr: String { "\(ipAddress)/\(prefixLength)" }
    var subnetCIDR: String {
        let ipParts = ipAddress.split(separator: ".").compactMap { UInt32($0) }
        guard ipParts.count == 4 else { return cidr }
        let ipInt = (ipParts[0] << 24) | (ipParts[1] << 16) | (ipParts[2] << 8) | ipParts[3]
        let mask: UInt32 = prefixLength == 0 ? 0 : (~UInt32(0) << (32 - prefixLength))
        let networkInt = ipInt & mask
        return "\(networkInt >> 24 & 0xFF).\(networkInt >> 16 & 0xFF).\(networkInt >> 8 & 0xFF).\(networkInt & 0xFF)/\(prefixLength)"
    }
}

protocol NetworkInterfaceServiceProtocol: Sendable {
    func detectDefaultSubnet() -> String
}

struct NetworkInterfaceService: NetworkInterfaceServiceProtocol {
    func detectDefaultSubnet() -> String {
        // Use getifaddrs to find the first non-loopback IPv4 interface
        var addrList: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&addrList) == 0, addrList != nil else {
            return "192.168.1.0/24"
        }
        defer { freeifaddrs(addrList) }

        var bestInterface: (name: String, ip: String, netmask: String)?

        var ptr: UnsafeMutablePointer<ifaddrs>? = addrList
        while let current = ptr {
            let name = String(cString: current.pointee.ifa_name)
            let flags = current.pointee.ifa_flags

            // Skip loopback
            guard flags & UInt32(IFF_LOOPBACK) == 0 else {
                ptr = current.pointee.ifa_next
                continue
            }

            // Must be up and running
            guard flags & UInt32(IFF_UP) != 0, flags & UInt32(IFF_RUNNING) != 0 else {
                ptr = current.pointee.ifa_next
                continue
            }

            let addr = current.pointee.ifa_addr
            if let addr, addr.pointee.sa_family == AF_INET {
                if let ip = socketAddrToIPv4(addr),
                   let netmask = socketAddrToIPv4(current.pointee.ifa_netmask) {
                    // Prefer en0, then any en* interface
                    if name == "en0" {
                        bestInterface = (name, ip, netmask)
                        break // en0 is the most likely Wi-Fi/Ethernet on macOS
                    }
                    if bestInterface == nil {
                        bestInterface = (name, ip, netmask)
                    }
                }
            }

            ptr = current.pointee.ifa_next
        }

        guard let best = bestInterface else {
            return "192.168.1.0/24"
        }

        let prefixLen = maskToPrefixLength(best.netmask)
        let networkAddr = applyMask(ip: best.ip, mask: best.netmask)
        // Return user-friendly range format: "192.168.1.1-254"
        let networkParts = networkAddr.split(separator: ".").compactMap { UInt32($0) }
        guard networkParts.count == 4 else {
            return "\(networkAddr)/\(prefixLen)"
        }
        let prefix = "\(networkParts[0]).\(networkParts[1]).\(networkParts[2])"
        let firstHost: UInt32 = 1
        let lastHost: UInt32
        if prefixLen >= 31 {
            return "\(networkAddr)/\(prefixLen)"
        }
        lastHost = (1 << (32 - prefixLen)) - 2
        return "\(prefix).\(firstHost)-\(lastHost)"
    }

    // MARK: - Private Helpers

    private func socketAddrToIPv4(_ sa: UnsafePointer<sockaddr>) -> String? {
        guard sa.pointee.sa_family == AF_INET else { return nil }
        let addrIn = sa.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0 }
        let ip = addrIn.pointee.sin_addr
        return String(cString: inet_ntoa(ip))
    }

    private func maskToPrefixLength(_ mask: String) -> Int {
        let parts = mask.split(separator: ".").compactMap { UInt32($0) }
        guard parts.count == 4 else { return 24 }
        let maskInt = (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]
        return UInt32(maskInt).nonzeroBitCount
    }

    private func applyMask(ip: String, mask: String) -> String {
        let ipParts = ip.split(separator: ".").compactMap { UInt32($0) }
        let maskParts = mask.split(separator: ".").compactMap { UInt32($0) }
        guard ipParts.count == 4, maskParts.count == 4 else { return ip }
        let ipInt = (ipParts[0] << 24) | (ipParts[1] << 16) | (ipParts[2] << 8) | ipParts[3]
        let maskInt = (maskParts[0] << 24) | (maskParts[1] << 16) | (maskParts[2] << 8) | maskParts[3]
        let network = ipInt & maskInt
        return "\(network >> 24 & 0xFF).\(network >> 16 & 0xFF).\(network >> 8 & 0xFF).\(network & 0xFF)"
    }
}