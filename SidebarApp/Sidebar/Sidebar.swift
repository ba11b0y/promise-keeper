import SwiftUI

struct Sidebar: View {
    @Binding var selection: String?
    @State private var filter: String = ""
    
    var body: some View {
        List(selection: $selection) {
            GeneralSidebarSection(selection: $selection)
            NotificationsSidebarSection(selection: $selection)
            MoreSidebarSection(selection: $selection)
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 200)
    }
} 