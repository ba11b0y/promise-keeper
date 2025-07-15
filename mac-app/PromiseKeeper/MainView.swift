import SwiftUI

struct MainView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    var body: some View {
        print("🎭 MainView.body being evaluated")
        NSLog("🎭 MainView.body being evaluated")
        
        return AuthenticatedView {
            print("🎭 MainView creating NavigationView content")
            NSLog("🎭 MainView creating NavigationView content")
            
            return NavigationView {
                Sidebar()
                    .onAppear {
                        print("📦 Sidebar appeared!")
                        NSLog("📦 Sidebar appeared!")
                    }
                ElectronMatchingPromiseView()
                    .environmentObject(supabaseManager)
                    .onAppear {
                        print("🎯 ElectronMatchingPromiseView in NavigationView appeared!")
                        NSLog("🎯 ElectronMatchingPromiseView in NavigationView appeared!")
                    }
            }
            .onAppear {
                print("🏠 Main NavigationView appeared!")
                NSLog("🏠 Main NavigationView appeared!")
            }
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
