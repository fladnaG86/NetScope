import SwiftUI

struct SettingsView: View {
    @State private var vm = SettingsViewModel()

    var body: some View {
        TabView {
            GeneralSettingsTab(vm: vm)
                .tabItem { Label("General", systemImage: "gear") }
            NetworkSettingsTab(vm: vm)
                .tabItem { Label("Network", systemImage: "network") }
        }
        .frame(width: 450, height: 280)
    }
}

// MARK: - General Settings Tab

struct GeneralSettingsTab: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Form {
            Picker("Language", selection: $vm.language) {
                ForEach(AppLanguage.allCases, id: \.self) { lang in
                    Text(lang.displayName).tag(lang)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }
}

// MARK: - Network Settings Tab

struct NetworkSettingsTab: View {
    @Bindable var vm: SettingsViewModel

    var body: some View {
        Form {
            Stepper(
                "Scan Timeout: \(String(format: "%.0f", vm.scanTimeout)) seconds",
                value: $vm.scanTimeout,
                in: 1...60,
                step: 1
            )
            Stepper(
                "Max Concurrent Scans: \(vm.maxConcurrentScans)",
                value: $vm.maxConcurrentScans,
                in: 10...200,
                step: 10
            )
        }
        .formStyle(.grouped)
        .padding()
    }
}