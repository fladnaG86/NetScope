import SwiftUI

enum SidebarSection: String, CaseIterable {
    case scan, metrics, tools

    var label: String {
        switch self {
        case .scan: return "Scan"
        case .metrics: return "Metrics"
        case .tools: return "Tools"
        }
    }
}

enum SidebarItem: String, CaseIterable, Identifiable {
    case devices, ports, traceroute, latency, jitter, bandwidth, dns, mtu

    var id: String { rawValue }

    var label: String {
        switch self {
        case .devices: return "Devices"
        case .ports: return "Ports"
        case .traceroute: return "Traceroute"
        case .latency: return "Latency"
        case .jitter: return "Jitter"
        case .bandwidth: return "Bandwidth"
        case .dns: return "DNS Lookup"
        case .mtu: return "MTU Discovery"
        }
    }

    var icon: String {
        switch self {
        case .devices: return "desktopcomputer"
        case .ports: return "bolt.horizontal"
        case .traceroute: return "point.topleft.down.to.point.bottomright.curvepath"
        case .latency: return "clock"
        case .jitter: return "waveform.path"
        case .bandwidth: return "gauge.with.dots.needle.67percent"
        case .dns: return "globe"
        case .mtu: return "arrow.up.and.down.text.horizontal"
        }
    }

    var section: SidebarSection {
        switch self {
        case .devices, .ports, .traceroute: return .scan
        case .latency, .jitter: return .metrics
        case .bandwidth, .dns, .mtu: return .tools
        }
    }
}