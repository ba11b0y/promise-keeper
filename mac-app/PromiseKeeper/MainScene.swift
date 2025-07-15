import SwiftUI

struct MainScene: Scene {
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    // Access the app delegate to get the updater controller
    private var appDelegate: AppDelegate? {
        NSApplication.shared.delegate as? AppDelegate
    }
    
    var body: some Scene {
        WindowGroup {
            Group {
                let isAuth = supabaseManager.isAuthenticated
                let currentUser = supabaseManager.currentUser
                let _ = print("🏛️ MainScene: isAuthenticated=\(isAuth), currentUser=\(currentUser?.email ?? "nil")")
                let _ = NSLog("🏛️ MainScene: isAuthenticated=\(isAuth), currentUser=\(currentUser?.email ?? "nil")")
                
                if isAuth {
                    // Show sidebar interface with promises widget when authenticated
                    MainView()
                        .frame(minWidth: 1000, minHeight: 700)
                        .environmentObject(supabaseManager)
                        .onAppear {
                            print("✅ MainView appeared - user is authenticated!")
                            NSLog("✅ MainView appeared - user is authenticated!")
                        }
                } else {
                    // Show full auth interface when not authenticated (matching Electron)
                    AuthView()
                        .frame(width: 800, height: 600)
                        .environmentObject(supabaseManager)
                        .onAppear {
                            print("🔐 AuthView appeared - user needs to sign in")
                            NSLog("🔐 AuthView appeared - user needs to sign in")
                        }
                }
            }
        }
        .windowStyle(.hiddenTitleBar)
        .windowResizability(supabaseManager.isAuthenticated ? .contentMinSize : .contentSize)
        .commands {
            AboutCommand()
            SidebarCommands()
            ExportCommands()
            AlwaysOnTopCommand()
            
            // Add Sparkle update commands
            if let updaterController = appDelegate?.updaterController {
                UpdateCommands(updaterController: updaterController)
            }
                        
            // Remove the "New Window" option from the File menu.
            CommandGroup(replacing: .newItem, addition: { })
        }
        Settings {
            SettingsWindow()
        }
    }
}
