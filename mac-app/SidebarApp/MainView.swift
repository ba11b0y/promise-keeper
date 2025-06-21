import SwiftUI

struct MainView: View {
    
    var body: some View {
        AuthenticatedView {
            NavigationView {
                Sidebar()
                EmptyPane()
            }
            .onAppear {
                print("🏠 Main NavigationView appeared!")
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
