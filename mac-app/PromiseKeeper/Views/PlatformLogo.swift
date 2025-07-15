import SwiftUI

struct PlatformLogo: View {
    let platform: String?
    let size: CGFloat
    
    init(platform: String?, size: CGFloat = 16) {
        self.platform = platform
        self.size = size
    }
    
    var body: some View {
        if let imageName = platformImageName {
            // Try to load custom logo image first
            if let nsImage = NSImage(named: imageName) {
                Image(nsImage: nsImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
            } else {
                // Fallback to SF Symbol if custom logo not found
                Image(systemName: platformIconName)
                    .font(.system(size: size * 0.8))
                    .foregroundColor(Color(hex: platformColor))
            }
        } else {
            // Default icon
            Image(systemName: "bubble.left.and.bubble.right")
                .font(.system(size: size * 0.8))
                .foregroundColor(.gray)
        }
    }
    
    // Platform logo image names (you'll need to add these to Assets.xcassets)
    private var platformImageName: String? {
        guard let platform = platform else { return nil }
        switch platform.lowercased() {
        case "slack":
            return "slack-logo"
        case "discord":
            return "discord-logo"
        case "zoom":
            return "zoom-logo"
        case "teams", "microsoft teams":
            return "teams-logo"
        case "whatsapp":
            return "whatsapp-logo"
        case "telegram":
            return "telegram-logo"
        case "signal":
            return "signal-logo"
        case "gmail":
            return "gmail-logo"
        case "outlook":
            return "outlook-logo"
        case "google meet", "meet":
            return "google-meet-logo"
        case "facebook messenger", "messenger":
            return "messenger-logo"
        case "instagram":
            return "instagram-logo"
        case "twitter":
            return "twitter-logo"
        case "x":
            return "x-logo"
        case "linkedin":
            return "linkedin-logo"
        default:
            return nil
        }
    }
    
    // Fallback SF Symbol names
    private var platformIconName: String {
        guard let platform = platform else { return "bubble.left.and.bubble.right" }
        switch platform.lowercased() {
        case "messages", "imessage":
            return "message.fill"
        case "discord":
            return "gamecontroller.fill"
        case "slack":
            return "number.square.fill"
        case "email", "mail":
            return "envelope.fill"
        case "gmail":
            return "envelope.circle.fill"
        case "outlook":
            return "envelope.badge.fill"
        case "whatsapp":
            return "phone.circle.fill"
        case "teams", "microsoft teams":
            return "person.3.fill"
        case "telegram":
            return "paperplane.fill"
        case "signal":
            return "lock.shield.fill"
        case "facebook messenger", "messenger":
            return "bubble.left.circle.fill"
        case "instagram":
            return "camera.fill"
        case "twitter", "x":
            return "bird.fill"
        case "linkedin":
            return "briefcase.fill"
        case "zoom":
            return "video.fill"
        case "google meet", "meet":
            return "video.circle.fill"
        default:
            return "bubble.left.and.bubble.right"
        }
    }
    
    // Platform colors
    private var platformColor: String {
        guard let platform = platform else { return "#007AFF" }
        switch platform.lowercased() {
        case "messages", "imessage":
            return "#34C759"
        case "discord":
            return "#5865F2"
        case "slack":
            return "#4A154B"
        case "gmail":
            return "#EA4335"
        case "outlook":
            return "#0078D4"
        case "whatsapp":
            return "#25D366"
        case "teams", "microsoft teams":
            return "#5059C9"
        case "telegram":
            return "#0088CC"
        case "signal":
            return "#3A76F0"
        case "facebook messenger", "messenger":
            return "#006FFF"
        case "instagram":
            return "#E4405F"
        case "twitter":
            return "#000000"
        case "x":
            return "#000000"
        case "linkedin":
            return "#0A66C2"
        case "zoom":
            return "#2D8CFF"
        case "google meet", "meet":
            return "#00897B"
        default:
            return "#007AFF"
        }
    }
}

// Helper to create logo with background
struct PlatformLogoWithBackground: View {
    let platform: String?
    let size: CGFloat
    
    init(platform: String?, size: CGFloat = 24) {
        self.platform = platform
        self.size = size
    }
    
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: size * 0.2)
                .fill(Color(hex: platformColor).opacity(0.1))
                .frame(width: size, height: size)
            
            PlatformLogo(platform: platform, size: size * 0.6)
        }
    }
    
    private var platformColor: String {
        guard let platform = platform else { return "#007AFF" }
        switch platform.lowercased() {
        case "messages", "imessage":
            return "#34C759"
        case "discord":
            return "#5865F2"
        case "slack":
            return "#4A154B"
        case "gmail":
            return "#EA4335"
        case "outlook":
            return "#0078D4"
        case "whatsapp":
            return "#25D366"
        case "teams", "microsoft teams":
            return "#5059C9"
        case "telegram":
            return "#0088CC"
        case "signal":
            return "#3A76F0"
        case "facebook messenger", "messenger":
            return "#006FFF"
        case "instagram":
            return "#E4405F"
        case "twitter", "x":
            return "#000000"
        case "linkedin":
            return "#0A66C2"
        case "zoom":
            return "#2D8CFF"
        case "google meet", "meet":
            return "#00897B"
        default:
            return "#007AFF"
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        Text("Platform Logos").font(.headline)
        
        HStack(spacing: 20) {
            PlatformLogo(platform: "Slack", size: 32)
            PlatformLogo(platform: "Discord", size: 32)
            PlatformLogo(platform: "Zoom", size: 32)
            PlatformLogo(platform: "Teams", size: 32)
        }
        
        Text("With Backgrounds").font(.headline)
        
        HStack(spacing: 20) {
            PlatformLogoWithBackground(platform: "WhatsApp", size: 40)
            PlatformLogoWithBackground(platform: "Gmail", size: 40)
            PlatformLogoWithBackground(platform: "Telegram", size: 40)
            PlatformLogoWithBackground(platform: "LinkedIn", size: 40)
        }
    }
    .padding()
}