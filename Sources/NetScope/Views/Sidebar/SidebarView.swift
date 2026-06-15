import SwiftUI

struct SidebarView: View {
    @Binding var selectedItem: SidebarItem?

    var body: some View {
        List(selection: $selectedItem) {
            ForEach(SidebarSection.allCases, id: \.self) { section in
                Section(section.label) {
                    ForEach(SidebarItem.allCases.filter { $0.section == section }) { item in
                        Label(item.label, systemImage: item.icon)
                            .tag(item)
                    }
                }
            }
        }
        .listStyle(.sidebar)
    }
}