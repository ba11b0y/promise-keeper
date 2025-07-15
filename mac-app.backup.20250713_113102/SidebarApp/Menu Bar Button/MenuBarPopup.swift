import SwiftUI

struct MenuBarPopup: View {
    @StateObject private var autoPromiseManager = AutoPromiseManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
        
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Image(systemName: "sparkles")
                    .foregroundColor(.blue)
                Text("Promise Keeper")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }
            
            // Quick stats
            if supabaseManager.isAuthenticated {
                HStack {
                    Text("Quick Actions")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Spacer()
                }
                
                VStack(spacing: 8) {
                    Button("Take Screenshot Now") {
                        Task {
                            await autoPromiseManager.processManualScreenshot()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    
                    Button("Show Main Window") {
                        NSApp.activate(ignoringOtherApps: true)
                        if let window = NSApp.windows.first {
                            window.makeKeyAndOrderFront(nil)
                        }
                    }
                    .buttonStyle(.bordered)
                }
            } else {
                Text("Sign in to Promise Keeper")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Button("Open App") {
                    NSApp.activate(ignoringOtherApps: true)
                }
                .buttonStyle(.borderedProminent)
            }
            
            Divider()
            
            Button {
                AboutWindow.show()
            } label: {
                Text("About...")
            }
            .buttonStyle(.plain)
            .font(.caption)
        }
        .padding(16)
        .frame(width: 220)
    }
}

struct MenuBarPopup_Previews: PreviewProvider {
    static var previews: some View {
        MenuBarPopup()
    }
}
