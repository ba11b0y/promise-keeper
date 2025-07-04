import SwiftUI

struct GeneralSidebarSection: View {
    
    @Binding var selection: SidebarPane?
    
    var body: some View {
        
        Section(header: Text("Promise Keeper")) {
			
			// Keeping deprecated NavigationLink for now to avoid major refactoring
			// TODO: Migrate to NavigationStack when ready
			NavigationLink(
				destination: PromisesPane(),
				tag: SidebarPane.promises,
				selection: $selection
			) {
				Label("My Promises", systemImage: "heart.text.square")
			}
			
			NavigationLink(
				destination: ElectronMatchingPromiseView()
					.environmentObject(SupabaseManager.shared),
				tag: SidebarPane.electronPromises,
				selection: $selection
			) {
				Label("Promise Widget", systemImage: "sidebar.squares.right")
			}
        }
        
        Section(header: Text("General")) {
			
			NavigationLink {
				HelloWorldPane()
			} label: {
				Label("Hello, World!", systemImage: "text.bubble")
			}
			
			NavigationLink {
				WhatsUpPane()
			} label: {
				Label("What's Up?", systemImage: "questionmark.app.dashed")
			}
        }
    }
}

struct GeneralSidebarSection_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSidebarSection(selection: .constant(.helloWorld))
    }
}
