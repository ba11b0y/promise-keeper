import SwiftUI

struct NotificationsSidebarSection: View {
    @Binding var selection: SidebarPane?
    
    var body: some View {
        Section(header: Text("Notifications")) {
            NavigationLink(
                destination: NotificationsPane(),
                tag: .notifications,
                selection: $selection
            ) {
                Label("Notifications", systemImage: "bell")
            }
        }
    }
} 