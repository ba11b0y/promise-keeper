import SwiftUI

// You may see the error message:
//
// `onChange(of: Bool) action tried to update multiple times per frame.`
//
// It seems to be a SwiftUI bug, as it can be reproduced with a minimal list.

struct Sidebar: View {
        
    @State var selection: SidebarPane? = .electronPromises
    @State var searchText: String = ""
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    var body: some View {
        List {
            GeneralSidebarSection(selection: $selection)
            
            // User Profile Section
            Section("Account") {
                NavigationLink(
                    destination: UserProfileView(),
                    tag: SidebarPane.userProfile,
                    selection: $selection
                ) {
                    Label("Profile", systemImage: "person.crop.circle")
                }
            }
        }
        .listStyle(SidebarListStyle())
        .frame(minWidth: 180, idealWidth: 180, maxWidth: 300)
        .safeAreaInset(edge: .bottom, spacing: 0) {
            SidebarFooter()
        }
        .searchable(text: $searchText, placement: .sidebar)
        .toolbar {
            ToolbarItem {
                Button(action: toggleSidebar, label: {
                    Image(systemName: "sidebar.left")
                })
            }
        }
    }
}

private func toggleSidebar() {
    NSApp.keyWindow?
        .firstResponder?
        .tryToPerform(#selector(NSSplitViewController.toggleSidebar(_:)), with: nil)
}

struct Sidebar_Previews: PreviewProvider {
    static var previews: some View {
        Sidebar()
    }
}
