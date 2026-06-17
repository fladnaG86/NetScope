import Foundation

struct ArpService: ArpServiceProtocol {
    func resolve(ip: String) async -> ArpResult {
        let table = await resolveAll()
        return ArpResult(ip: ip, macAddress: table[ip])
    }

    func resolveAll() async -> [String: String] {
        // Primary: read ARP table directly from kernel via sysctl (works in GUI apps)
        let sysctlResult = readArpTableViaSysctl()
        if !sysctlResult.isEmpty {
            writeDebug("[sysctl] \(sysctlResult.count) entries")
            return sysctlResult
        }

        // Fallback: try arp command via Process (works in CLI context)
        let processResult = await runArpViaProcess()
        if !processResult.isEmpty {
            writeDebug("[process] \(processResult.count) entries")
            return processResult
        }

        writeDebug("[all] 0 entries - both methods failed")
        return [:]
    }

    // MARK: - Sysctl (direct kernel access, no Process needed)

    private func readArpTableViaSysctl() -> [String: String] {
        // MIB for ARP table: CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_LLINFO
        var mib: [Int32] = [CTL_NET, PF_ROUTE, 0, AF_INET, NET_RT_FLAGS, RTF_LLINFO]

        // First call: get buffer size
        var size: size_t = 0
        var result = sysctl(&mib, UInt32(mib.count), nil, &size, nil, 0)
        guard result == 0, size > 0 else {
            writeDebug("[sysctl] size query failed: errno=\(errno)")
            return [:]
        }

        // Allocate buffer and get data
        var buffer = [UInt8](repeating: 0, count: size)
        result = sysctl(&mib, UInt32(mib.count), &buffer, &size, nil, 0)
        guard result == 0 else {
            writeDebug("[sysctl] data query failed: errno=\(errno)")
            return [:]
        }

        writeDebug("[sysctl] got \(size) bytes")
        return parseSysctlArpData(buffer, size: size)
    }

    private func parseSysctlArpData(_ buffer: [UInt8], size: size_t) -> [String: String] {
        var table: [String: String] = [:]
        var offset = 0

        // Alignment for sockaddr in routing messages: round up to sizeof(long) = 8 on 64-bit
        func roundUp(_ saLen: UInt8) -> Int {
            if saLen == 0 { return 8 }
            return (Int(saLen) + 7) & ~7
        }

        while offset < size {
            // Read the message header
            guard offset + MemoryLayout<rt_msghdr>.size <= size else { break }

            let hdr = buffer.withUnsafeBytes { rawBuf in
                rawBuf.baseAddress!.advanced(by: offset)
                    .assumingMemoryBound(to: rt_msghdr.self).pointee
            }

            let msgLen = Int(hdr.rtm_msglen)
            let rtmAddrs = UInt32(hdr.rtm_addrs)
            let rtmType = hdr.rtm_type

            guard msgLen > 0, offset + msgLen <= size else { break }

            // We only care about RTM_GET responses with LLINFO (ARP entries)
            guard rtmType == RTM_GET || rtmType == RTM_ADD else {
                offset += msgLen
                continue
            }

            // Parse sockaddr entries after the header
            var ipAddr: String? = nil
            var macAddr: String? = nil
            var addrOffset = offset + MemoryLayout<rt_msghdr>.size

            for i in 0..<RTAX_MAX {
                guard rtmAddrs & (1 << i) != 0 else { continue }
                guard addrOffset + MemoryLayout<sockaddr>.size <= size else { break }

                let saLen: UInt8 = buffer[addrOffset] // sa_len is first byte
                let saFamily: UInt8 = buffer[addrOffset + 1] // sa_family is second byte

                guard saLen > 0 else { break }

                switch Int32(saFamily) {
                case AF_INET:
                    if ipAddr == nil {
                        // Extract IP from sockaddr_in
                        buffer.withUnsafeBytes { rawBuf in
                            let ptr = rawBuf.baseAddress!.advanced(by: addrOffset)
                                .assumingMemoryBound(to: sockaddr_in.self)
                            var sin = ptr.pointee
                            var ipBuf = [CChar](repeating: 0, count: Int(INET_ADDRSTRLEN))
                            inet_ntop(AF_INET, &sin.sin_addr, &ipBuf, socklen_t(INET_ADDRSTRLEN))
                            ipAddr = String(cString: ipBuf)
                        }
                    }
                case AF_LINK:
                    // Extract MAC from sockaddr_dl
                    buffer.withUnsafeBytes { rawBuf in
                        let baseAddr = rawBuf.baseAddress!.advanced(by: addrOffset)
                        let sdl = baseAddr.assumingMemoryBound(to: sockaddr_dl.self).pointee
                        if sdl.sdl_type == IFT_ETHER && sdl.sdl_alen == 6 {
                            // sdl_data starts at offset 8 within sockaddr_dl
                            // MAC starts at sdl_data[sdl_nlen ..< sdl_nlen+6]
                            let macOffset = addrOffset + 8 + Int(sdl.sdl_nlen)
                            guard macOffset + 6 <= size else { return }
                            var macParts = [String]()
                            for j in 0..<6 {
                                macParts.append(String(format: "%02X", buffer[macOffset + j]))
                            }
                            macAddr = macParts.joined(separator: ":")
                        }
                    }
                default:
                    break
                }

                addrOffset += roundUp(saLen)
            }

            if let ip = ipAddr, let mac = macAddr {
                table[ip] = mac
            }

            offset += msgLen
        }

        return table
    }

    // MARK: - Process fallback

    private func runArpViaProcess() async -> [String: String] {
        let process = Process()
        let pipe = Pipe()
        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", "/usr/sbin/arp -a 2>/dev/null"]
        process.standardOutput = pipe
        process.standardError = Pipe()

        let exitStatus = await AsyncProcess.run(process)
        guard let exitStatus, exitStatus == 0 else { return [:] }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8), !output.isEmpty else { return [:] }

        writeDebug("[process] exit=\(exitStatus) len=\(output.count)")
        return parseArpTable(output)
    }

    // MARK: - Debug

    private func writeDebug(_ msg: String) {
        let path = "/tmp/netscope_arp.log"
        let line = msg + "\n"
        guard let data = line.data(using: .utf8) else { return }
        if FileManager.default.fileExists(atPath: path) {
            if let h = FileHandle(forWritingAtPath: path) { h.seekToEndOfFile(); h.write(data); h.closeFile() }
        } else {
            try? data.write(to: URL(fileURLWithPath: path))
        }
    }

    // MARK: - Text parsing (fallback)

    private func parseArpTable(_ output: String) -> [String: String] {
        var table: [String: String] = [:]
        for line in output.components(separatedBy: "\n") {
            if line.contains("(incomplete)") { continue }
            guard let openParen = line.firstIndex(of: "("),
                  let closeParen = line.firstIndex(of: ")"),
                  openParen < closeParen else { continue }
            let ipStart = line.index(after: openParen)
            let ip = String(line[ipStart..<closeParen])
            let ipParts = ip.split(separator: ".")
            guard ipParts.count == 4, ipParts.allSatisfy({ Int($0) != nil }) else { continue }
            guard let atRange = line.range(of: " at ") else { continue }
            let afterAt = line[atRange.upperBound...]
            let macStr = afterAt.split(separator: " ").first.map(String.init) ?? ""
            let macParts = macStr.split(separator: ":")
            guard macParts.count == 6, macParts.allSatisfy({ p in p.count >= 1 && p.count <= 2 && p.allSatisfy { $0.isHexDigit } }) else { continue }
            let normalized = macParts.map { p in let u = p.uppercased(); return u.count == 1 ? "0\(u)" : u }.joined(separator: ":")
            table[ip] = normalized
        }
        return table
    }
}