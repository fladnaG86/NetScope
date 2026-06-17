import Foundation
import Network

struct SubnetService: SubnetServiceProtocol {

    /// Parses a scan target in any supported format:
    /// - CIDR: "192.168.1.0/24"
    /// - Short range: "192.168.1.1-254" (same prefix, last octet range)
    /// - Full range: "192.168.1.1-192.168.1.254"
    /// - Single host: "192.168.1.1"
    func parseTarget(_ target: String) throws -> SubnetInfo {
        let trimmed = target.trimmingCharacters(in: .whitespaces)

        // CIDR notation: contains "/"
        if trimmed.contains("/") {
            return try calculateSubnet(cidr: trimmed)
        }

        // Range notation: contains "-"
        if let dashRange = trimmed.range(of: "-", options: .literal) {
            let startPart = String(trimmed[trimmed.startIndex..<dashRange.lowerBound])
            let endPart = String(trimmed[dashRange.upperBound..<trimmed.endIndex])

            let startOctets = startPart.split(separator: ".").compactMap { UInt32($0) }
            guard startOctets.count == 4 else {
                throw ScanError.subnetInvalid(target)
            }

            let startInt = (startOctets[0] << 24) | (startOctets[1] << 16) | (startOctets[2] << 8) | startOctets[3]

            let endInt: UInt32
            let endOctets = endPart.split(separator: ".").compactMap { UInt32($0) }

            if endOctets.count == 4 {
                // Full IP: "192.168.1.1-192.168.1.254"
                endInt = (endOctets[0] << 24) | (endOctets[1] << 16) | (endOctets[2] << 8) | endOctets[3]
            } else if endOctets.count == 1, let lastOctet = endOctets.first {
                // Short range: "192.168.1.1-254"
                let prefix = (startOctets[0] << 24) | (startOctets[1] << 16) | (startOctets[2] << 8)
                endInt = prefix | lastOctet
            } else {
                throw ScanError.subnetInvalid(target)
            }

            guard endInt >= startInt else {
                throw ScanError.subnetInvalid(target)
            }

            let hostCount = Int(endInt - startInt) + 1
            let startIP = intToIPv4String(startInt)
            let endIP = intToIPv4String(endInt)

            return SubnetInfo(
                networkAddress: startIP,
                mask: "255.255.255.255",
                broadcastAddress: endIP,
                hostRange: (start: startIP, end: endIP),
                totalHosts: hostCount,
                truncated: hostCount > 1024
            )
        }

        // Single host: just an IP
        guard IPv4Address(trimmed) != nil else {
            throw ScanError.subnetInvalid(target)
        }
        return SubnetInfo(
            networkAddress: trimmed,
            mask: "255.255.255.255",
            broadcastAddress: trimmed,
            hostRange: (start: trimmed, end: trimmed),
            totalHosts: 1
        )
    }

    func calculateSubnet(cidr: String) throws -> SubnetInfo {
        let parts = cidr.split(separator: "/")
        guard parts.count == 2,
              let ipPart = parts.first,
              let prefixLength = Int(parts[1]),
              prefixLength >= 0,
              prefixLength <= 32
        else {
            throw ScanError.subnetInvalid(cidr)
        }

        let ipString = String(ipPart)
        guard let ipv4 = IPv4Address(ipString) else {
            throw ScanError.subnetInvalid(cidr)
        }

        let ipInt = ipv4AddressToInt(ipv4)
        let maskInt: UInt32 = prefixLength == 0 ? 0 : (~UInt32(0) << (32 - prefixLength))
        let networkInt = ipInt & maskInt
        let broadcastInt = networkInt | (~maskInt)

        let networkAddress = intToIPv4String(networkInt)
        let broadcastAddress = intToIPv4String(broadcastInt)
        let mask = intToIPv4String(maskInt)

        let totalHosts: Int
        if prefixLength == 32 {
            // Single-host route: 1 usable address
            totalHosts = 1
        } else if prefixLength == 31 {
            // RFC 3021 point-to-point: 2 usable addresses
            totalHosts = 2
        } else {
            totalHosts = (1 << (32 - prefixLength)) - 2
        }

        let firstHostInt: UInt32 = prefixLength >= 31 ? networkInt : networkInt + 1
        let lastHostInt: UInt32 = prefixLength >= 31 ? broadcastInt : broadcastInt - 1
        let hostRange = (start: intToIPv4String(firstHostInt), end: intToIPv4String(lastHostInt))

        return SubnetInfo(
            networkAddress: networkAddress,
            mask: mask,
            broadcastAddress: broadcastAddress,
            hostRange: hostRange,
            totalHosts: totalHosts
        )
    }

    func enumerateHosts(subnet: SubnetInfo) -> [String] {
        let startInt = ipv4StringToInt(subnet.hostRange.start)
        let endInt = ipv4StringToInt(subnet.hostRange.end)

        var hosts: [String] = []
        let maxHosts: UInt32 = 1024
        let totalRange = endInt - startInt + 1
        let count = min(totalRange, maxHosts)

        for i in 0..<Int(count) {
            hosts.append(intToIPv4String(startInt + UInt32(i)))
        }

        return hosts
    }

    /// Returns whether the subnet was truncated (more than 1024 hosts)
    func isTruncated(subnet: SubnetInfo) -> Bool {
        let startInt = ipv4StringToInt(subnet.hostRange.start)
        let endInt = ipv4StringToInt(subnet.hostRange.end)
        return (endInt - startInt + 1) > 1024
    }

    // MARK: - Private Helpers

    private func ipv4AddressToInt(_ addr: IPv4Address) -> UInt32 {
        // IPv4Address.debugDescription returns the IP string
        let parts = addr.debugDescription.split(separator: ".").compactMap { UInt32($0) }
        guard parts.count == 4 else { return 0 }
        return (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]
    }

    private func ipv4StringToInt(_ s: String) -> UInt32 {
        let parts = s.split(separator: ".").compactMap { UInt32($0) }
        guard parts.count == 4 else { return 0 }
        return (parts[0] << 24) | (parts[1] << 16) | (parts[2] << 8) | parts[3]
    }

    private func intToIPv4String(_ n: UInt32) -> String {
        let a = (n >> 24) & 0xFF
        let b = (n >> 16) & 0xFF
        let c = (n >> 8) & 0xFF
        let d = n & 0xFF
        return "\(a).\(b).\(c).\(d)"
    }
}