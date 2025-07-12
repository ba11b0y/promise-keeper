import SwiftUI
import WidgetKit

struct WidgetSyncDebugView: View {
    @StateObject private var promiseManager = PromiseManager()
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var debugOutput = ""
    @State private var isRefreshing = false
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Widget Sync Debug")
                .font(.largeTitle)
                .padding()
            
            // Status indicators
            HStack(spacing: 30) {
                VStack {
                    Image(systemName: supabaseManager.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(supabaseManager.isAuthenticated ? .green : .red)
                        .font(.system(size: 40))
                    Text("Authenticated")
                }
                
                VStack {
                    Image(systemName: promiseManager.promises.isEmpty ? "xmark.circle.fill" : "checkmark.circle.fill")
                        .foregroundColor(promiseManager.promises.isEmpty ? .red : .green)
                        .font(.system(size: 40))
                    Text("\(promiseManager.promises.count) Promises")
                }
            }
            .padding()
            
            // Action buttons
            HStack(spacing: 20) {
                Button("Force Sync to Widget") {
                    Task {
                        await forceSyncToWidget()
                    }
                }
                .buttonStyle(.borderedProminent)
                
                Button("Check Widget Data") {
                    checkWidgetData()
                }
                
                Button("Clear Widget Data") {
                    SharedDataManager.shared.clearAllWidgetData()
                    checkWidgetData()
                }
                .foregroundColor(.red)
            }
            
            // Debug output
            ScrollView {
                Text(debugOutput)
                    .font(.system(.body, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
            }
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
            .padding()
            
            Button("Refresh") {
                Task {
                    isRefreshing = true
                    await promiseManager.fetchPromises()
                    checkWidgetData()
                    isRefreshing = false
                }
            }
            .disabled(isRefreshing)
        }
        .frame(width: 600, height: 700)
        .padding()
        .onAppear {
            Task {
                await promiseManager.fetchPromises()
                checkWidgetData()
            }
        }
    }
    
    private func forceSyncToWidget() async {
        debugOutput = "🔄 Starting force sync...\n"
        
        // Fetch latest promises
        await promiseManager.fetchPromises()
        
        // Force sync using the generic method
        let userId = supabaseManager.currentUser?.id.uuidString
        SharedDataManager.shared.syncPromisesFromApp(
            promiseManager.promises,
            userId: userId,
            isAuthenticated: supabaseManager.isAuthenticated
        ) { promise in
            WidgetPromise(
                id: String(promise.id ?? 0),
                created_at: promise.created_at,
                updated_at: promise.updated_at,
                content: promise.content,
                owner_id: promise.owner_id.uuidString,
                resolved: promise.resolved
            )
        }
        
        // Debug print
        SharedDataManager.shared.debugPrintAllStoredData()
        
        // Check results
        checkWidgetData()
        
        debugOutput += "\n✅ Force sync complete!"
    }
    
    private func checkWidgetData() {
        debugOutput = "🔍 Checking Widget Data:\n"
        debugOutput += "========================\n\n"
        
        let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
        
        // Check App Group access
        if let defaults = UserDefaults(suiteName: appGroupID) {
            debugOutput += "✅ App Group accessible\n\n"
            
            // Check each key
            let keys = [
                "widget_promises",
                "widget_promises_updated", 
                "widget_user_id",
                "widget_is_authenticated",
                "widget_last_sync_time"
            ]
            
            for key in keys {
                if let value = defaults.object(forKey: key) {
                    debugOutput += "✅ \(key): "
                    
                    switch key {
                    case "widget_promises":
                        if let data = value as? Data {
                            debugOutput += "\(data.count) bytes"
                            if let promises = try? JSONDecoder().decode([WidgetPromise].self, from: data) {
                                debugOutput += " (\(promises.count) promises)"
                            }
                        }
                    case "widget_is_authenticated":
                        debugOutput += "\(defaults.bool(forKey: key))"
                    case "widget_promises_updated", "widget_last_sync_time":
                        if let date = value as? Date {
                            let formatter = DateFormatter()
                            formatter.dateStyle = .short
                            formatter.timeStyle = .medium
                            debugOutput += formatter.string(from: date)
                        }
                    default:
                        debugOutput += "\(value)"
                    }
                } else {
                    debugOutput += "❌ \(key): NOT FOUND"
                }
                debugOutput += "\n"
            }
        } else {
            debugOutput += "❌ Cannot access App Group!\n"
        }
        
        // Check Keychain
        debugOutput += "\n📱 Keychain Data:\n"
        let accessToken = SharedSupabaseManager.getAccessTokenForWidget()
        debugOutput += "Access Token Present: \(accessToken != nil)\n"
        debugOutput += "Is Authenticated: \(SharedSupabaseManager.isAuthenticated)\n"
        debugOutput += "User Email: \(SharedSupabaseManager.userEmail ?? "nil")\n"
    }
}

// Add to your app's debug menu
struct WidgetSyncDebugMenuItem: View {
    @State private var showingDebugWindow = false
    
    var body: some View {
        Button("Widget Sync Debug") {
            showingDebugWindow = true
        }
        .sheet(isPresented: $showingDebugWindow) {
            WidgetSyncDebugView()
        }
    }
}