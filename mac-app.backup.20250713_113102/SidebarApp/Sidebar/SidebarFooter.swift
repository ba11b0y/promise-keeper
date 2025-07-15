import SwiftUI

struct SidebarFooter: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    var body: some View {
        VStack(spacing: 6) {
            if let user = supabaseManager.currentUser {
                HStack(spacing: 8) {
                    Image(systemName: "person.crop.circle.fill")
                        .foregroundColor(.accentColor)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(user.email ?? "Unknown")
                            .font(.caption)
                            .fontWeight(.medium)
                            .lineLimit(1)
                        Text("Signed in")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            } else {
                Text("Loading user...")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(NSColor.controlBackgroundColor))
        .cornerRadius(8)
        .padding(.horizontal)
    }
}

struct SidebarFooter_Previews: PreviewProvider {
    static var previews: some View {
        SidebarFooter()
    }
}
