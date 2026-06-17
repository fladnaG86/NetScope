<img width="1254" height="1254" alt="image" src="https://github.com/user-attachments/assets/da1185de-461a-4be3-8894-9685372301f1" />

<img width="1012" height="712" alt="Screenshot 2026-06-17 alle 18 54 13" src="https://github.com/user-attachments/assets/61e35c14-b9b7-4c80-85d3-4b8513aecdd4" />



# NetScope

A native macOS network scanner built with SwiftUI. Discover devices on your local network, scan ports, measure link quality in real time, and run network diagnostics — all in a single Mac app.


## Features

### Network discovery
- **Ping sweep** across an IP range, CIDR, or a single host
- **ARP table resolution** (batch `arp -a` read after the ping sweep) for MAC addresses
- **DNS reverse lookup** for hostnames
- **MAC vendor** identification (OUI)
- **Port scanning** (18 common ports in Deep mode)
- **Quick** (Ping + ARP + DNS) and **Deep** (adds port scan) scan modes
- **Auto-detected subnet** via `getifaddrs` (no hardcoded ranges)

### Real-time metrics
- Per-device latency, jitter, packet loss
- Composite quality score (factors in packet loss)
- Live progress during scans

### Diagnostics (per device and standalone)
- Traceroute
- MTU discovery
- Bandwidth test (requires `iperf3`; falls back to placeholder)
- DNS lookup + diagnostics
- Latency / jitter view
- All-ports view

### UI
- Sortable, filterable SwiftUI `Table` for devices and ports
- Device detail with 4 tabs (Overview, Ports, Metrics, Diagnostics)
- Standalone diagnostic windows
- Settings with English / Italian language switch

### Export & persistence
- Export results to **CSV**, **JSON**, or **HTML**
- SQLite persistence via GRDB (device + metrics history, WAL mode)

## Requirements
- macOS 14.0+ (Sonoma / Sequoia)
- Xcode 16+ (the project is built with Xcode-beta) — run `sudo xcode-select -s /Applications/Xcode-beta.app/Contents/Developer` if needed
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) (`brew install xcodegen`)
- Homebrew (for `gh`, `xcodegen`)

## Build & run

**Always build the `.app` bundle and launch it via `open`.** Do not run the bare SPM executable directly — a bare executable launched from Terminal is not registered as a key GUI app, so the window appears but keystrokes never reach text fields.

```bash
bash build.sh
open ./DerivedData/Build/Products/Debug/NetScope.app
```

`build.sh` runs `xcodegen generate`, `xcodebuild` (produces `NetScope.app`), and ad-hoc codesigns the bundle with the network entitlements.

## Tests

```bash
swift test
```

76 tests covering database, repositories, view models, actors, controllers, and services (with protocol-based mocks). Integration tests run real ping/ARP/DNS operations.

## Architecture

- **SwiftUI** + **@Observable** view models (no Combine)
- **Actors** for shared mutable state (`ScanStateActor`, `DeviceCacheActor`, `MetricsCollectorActor`)
- **async/await** for all I/O services (ping, ARP, DNS, ports, traceroute, MTU, bandwidth)
- **Protocol-based dependency injection** — zero singletons; wiring at the `@main` app entry point
- **GRDB.swift 7** for SQLite (in-memory for tests, WAL for production)
- **Network.framework** + shell process helpers (`AsyncProcess` — non-blocking `Process` with continuation-based `waitUntilExit`)
- **Swift Charts** for metrics

### Project layout
```
Sources/NetScope/
  App/          @main entry point, DI wiring
  Models/       Device, PortInfo, NetworkMetrics, NetworkInterface, ScanMode, Errors
  Actors/       ScanState, DeviceCache, MetricsCollector
  Controllers/  Scan, Metrics, Export
  ViewModels/   DeviceList, DeviceDetail, ScanConfig, Settings
  Views/        MainWindow, Sidebar, DeviceList, DeviceDetail, Settings, Standalone diagnostics
  Services/     Network/, Diagnostics/, Export/, Config/
  Database/     DatabaseManager + repositories (GRDB)
Tests/NetScopeTests/
```

## Known limitations
- String Catalog localization not wired (English strings in code)
- OUI database not bundled (MAC vendor gracefully degrades)
- Bandwidth test needs `iperf3` on the target
- No continuous monitoring (intentionally excluded)
- Subnet scan silently caps at 1024 hosts
- Sidebar diagnostics are implemented as standalone windows

## License

MIT — see [LICENSE](LICENSE).

## Acknowledgements
- [GRDB.swift](https://github.com/groue/GRDB.swift) — SQLite toolkit
