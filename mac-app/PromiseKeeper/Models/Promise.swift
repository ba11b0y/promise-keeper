import Foundation
import Supabase

// MARK: - Promise Model
struct Promise: Codable, Identifiable, Equatable {
    let id: Int64?
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: UUID
    let resolved: Bool?
    let extracted_from_screenshot: Bool?
    let screenshot_id: String?
    let screenshot_timestamp: String?
    let resolved_screenshot_id: String?
    let resolved_screenshot_time: String?
    let resolved_reason: String?
    let extraction_data: String?
    let action: String?
    let metadata: String?
    let due_date: String?
    let person: String?
    let platform: String?
    
    // For Identifiable protocol - use a computed property
    var identifiableId: Int64 {
        return id ?? 0
    }
    
    // Computed properties for convenience
    var isResolved: Bool {
        return resolved ?? false
    }
    
    var isFromScreenshot: Bool {
        return extracted_from_screenshot ?? false
    }
    
    // Coding keys to match database column names
    enum CodingKeys: String, CodingKey {
        case id
        case created_at
        case updated_at
        case content
        case owner_id
        case resolved
        case extracted_from_screenshot
        case screenshot_id
        case screenshot_timestamp
        case resolved_screenshot_id
        case resolved_screenshot_time
        case resolved_reason
        case extraction_data
        case action
        case metadata
        case due_date
        case person
        case platform
    }
}

// MARK: - Promise Creation Model (without ID for new promises)
struct NewPromise: Codable {
    let content: String
    let owner_id: UUID
    
    // Coding keys to match database column names
    enum CodingKeys: String, CodingKey {
        case content
        case owner_id
    }
}

// MARK: - Promise Extensions
extension Promise {
    var formattedCreatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: created_at)
    }
    
    var formattedUpdatedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: updated_at)
    }
    
    var isRecent: Bool {
        let oneDayAgo = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date()
        return created_at > oneDayAgo
    }
    
    var formattedDueDate: String? {
        guard let due_date = due_date else { return nil }
        // Try to parse and format the due date
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: due_date) {
            formatter.dateStyle = .medium
            return formatter.string(from: date)
        }
        return due_date
    }
    
    var displayPerson: String {
        return person ?? "myself"
    }
    
    // SF Symbol names for platform icons
    var platformIconName: String {
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
        case "calendar", "google calendar", "outlook calendar":
            return "calendar"
        case "phone", "call":
            return "phone.fill"
        case "facetime":
            return "video.bubble.left.fill"
        case "notes":
            return "note.text"
        case "reminder", "reminders":
            return "checklist"
        default:
            return "bubble.left.and.bubble.right"
        }
    }
    
    // Platform brand colors
    var platformColor: String {
        guard let platform = platform else { return "#007AFF" } // Default blue
        switch platform.lowercased() {
        case "messages", "imessage":
            return "#34C759" // Green for iMessage
        case "discord":
            return "#5865F2" // Discord blurple
        case "slack":
            return "#4A154B" // Slack aubergine
        case "gmail":
            return "#EA4335" // Gmail red
        case "outlook":
            return "#0078D4" // Microsoft blue
        case "whatsapp":
            return "#25D366" // WhatsApp green
        case "teams", "microsoft teams":
            return "#5059C9" // Teams purple
        case "telegram":
            return "#0088CC" // Telegram blue
        case "signal":
            return "#3A76F0" // Signal blue
        case "facebook messenger", "messenger":
            return "#006FFF" // Messenger blue
        case "instagram":
            return "#E4405F" // Instagram pink
        case "twitter":
            return "#000000" // Twitter/X black
        case "x":
            return "#000000" // X black
        case "linkedin":
            return "#0A66C2" // LinkedIn blue
        case "zoom":
            return "#2D8CFF" // Zoom blue
        case "google meet", "meet":
            return "#00897B" // Google Meet green
        case "email", "mail":
            return "#007AFF" // Mail blue
        default:
            return "#007AFF" // Default blue
        }
    }
}

// MARK: - Promise Creation Helper
extension NewPromise {
    static func create(content: String, for userId: UUID) -> NewPromise {
        return NewPromise(content: content, owner_id: userId)
    }
} 