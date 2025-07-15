import SwiftUI

struct UserProfileView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    var body: some View {
        VStack(spacing: 20) {
            // User Avatar
            Image(systemName: "person.crop.circle.fill")
                .font(.system(size: 60))
                .foregroundColor(.accentColor)
            
            // User Info
            VStack(spacing: 8) {
                if let user = supabaseManager.currentUser {
                    Text(user.email ?? "Unknown")
                        .font(.headline)
                        .fontWeight(.medium)
                    
                    Text("User ID: \(user.id.uuidString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .textSelection(.enabled)
                } else {
                    Text("Loading user info...")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            }
            
            Divider()
            
            // Sign Out Button
            Button("Sign Out") {
                Task {
                    await supabaseManager.signOut()
                }
            }
            .buttonStyle(SecondaryButtonStyle())
        }
        .padding(30)
        .background(Color(NSColor.windowBackgroundColor))
        .cornerRadius(12)
        .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 8)
            .padding(.horizontal, 16)
            .background(configuration.isPressed ? Color(NSColor.controlBackgroundColor).opacity(0.8) : Color(NSColor.controlBackgroundColor))
            .foregroundColor(.primary)
            .cornerRadius(6)
            .overlay(
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct UserProfileView_Previews: PreviewProvider {
    static var previews: some View {
        UserProfileView()
            .environmentObject(SupabaseManager.shared)
    }
} 