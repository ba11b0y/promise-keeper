import SwiftUI

struct AuthenticatedView<Content: View>: View {
    @ObservedObject private var supabaseManager: SupabaseManager
    let content: () -> Content
    
    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
        // Get the shared instance
        self.supabaseManager = SupabaseManager.shared
    }
    
    var body: some View {
        let isAuth = supabaseManager.isAuthenticated
        let currentUser = supabaseManager.currentUser
        print("🔄 AuthenticatedView body evaluation - isAuthenticated: \(isAuth)")
        NSLog("🔄 AuthenticatedView body evaluation - isAuthenticated: \(isAuth)")
        print("🔄 AuthenticatedView currentUser: \(currentUser?.email ?? "nil")")
        NSLog("🔄 AuthenticatedView currentUser: \(currentUser?.email ?? "nil")")
        
        return Group {
            if isAuth {
                content()
                    .environmentObject(supabaseManager)
                    .onAppear {
                        print("🎯 Authenticated content appeared!")
                    }
            } else {
                AuthView()
                    .environmentObject(supabaseManager)
                    .onAppear {
                        print("🔐 Auth view appeared!")
                    }
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isAuth)
    }
}

struct AuthenticatedView_Previews: PreviewProvider {
    static var previews: some View {
        AuthenticatedView {
            Text("Authenticated Content")
        }
    }
} 