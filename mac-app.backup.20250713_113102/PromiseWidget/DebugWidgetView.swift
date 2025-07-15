import SwiftUI
import WidgetKit

// Debug view to show exactly what the widget sees
struct DebugWidgetView: View {
    let entry: PromiseEntry
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("🔍 Widget Debug Info")
                .font(.caption.bold())
            
            Divider()
            
            Text("Auth: \(entry.isAuthenticated ? "✅" : "❌")")
                .font(.caption)
            
            Text("Promises: \(entry.promises.count)")
                .font(.caption)
            
            Text("User: \(entry.currentUserId ?? "nil")")
                .font(.caption)
                .lineLimit(1)
            
            if entry.isAuthenticated && entry.promises.isEmpty {
                Text("⚠️ Authenticated but no promises!")
                    .font(.caption)
                    .foregroundColor(.orange)
            }
            
            if !entry.isAuthenticated {
                Text("❌ Not authenticated!")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Divider()
            
            Text("Updated: \(entry.date, style: .time)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(8)
        .containerBackground(for: .widget) {
            Color.yellow.opacity(0.2)
        }
    }
}