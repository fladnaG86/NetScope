import Foundation
import Network

struct SubnetService: SubnetServiceProtocol {
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
        let count = min(endInt - startInt + 1, maxHosts)

        for i in 0..<Int(count) {
            hosts.append(intToIPv4String(startInt + UInt32(i)))
        }

        return hosts
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