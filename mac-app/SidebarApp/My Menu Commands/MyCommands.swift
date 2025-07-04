import SwiftUI

struct MyCommands: Commands {
    
    var body: some Commands {
        CommandMenu(Text("My Commands", comment: "My custom actions")) {
            Button {
                print("Build!")
            } label: {
                Text("Build", comment: "Build something or whatever.")
            }
            .keyboardShortcut("B", modifiers: [.command])
            
            Divider()
            
            Button {
                print("Do Stuff!")
            } label: {
                Text("Do Stuff", comment: "Do various types of stuff.")
            }
            .keyboardShortcut("D", modifiers: [.command])
            
            // Debug commands for widget sync
            Button {
                Task {
                    print("\n🔍 DEBUG: Manual Promise Fetch")
                    let promiseManager = PromiseManager.shared
                    await promiseManager.fetchPromises()
                }
            } label: {
                Text("Debug: Fetch Promises", comment: "Manually fetch promises")
            }
            .keyboardShortcut("P", modifiers: [.command, .shift])
            
            Button {
                print("\n🔍 DEBUG: Widget Data Status")
                if let data = UnifiedSharedDataManager.shared.load() {
                    print("📊 Widget Data:")
                    print("   - Authenticated: \(data.isAuthenticated)")
                    print("   - User: \(data.userEmail ?? "none")")
                    print("   - Promises: \(data.promises.count)")
                    print("   - Last Updated: \(data.lastUpdated)")
                    
                    if data.promises.isEmpty && data.isAuthenticated {
                        print("   ⚠️ WARNING: Authenticated but NO promises!")
                    }
                } else {
                    print("❌ No widget data found")
                }
            } label: {
                Text("Debug: Check Widget Data", comment: "Check current widget data")
            }
            .keyboardShortcut("W", modifiers: [.command, .shift])
            
            Button {
                print("\n🔍 DEBUG: Force Widget Sync")
                let promiseManager = PromiseManager.shared
                promiseManager.updateSharedData()
                print("✅ Forced widget data sync")
            } label: {
                Text("Debug: Force Widget Sync", comment: "Force sync to widget")
            }
            .keyboardShortcut("S", modifiers: [.command, .shift])
        }
    }
}
