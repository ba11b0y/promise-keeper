import Foundation
import Supabase

// MARK: - Promise Model
struct Promise: Codable, Identifiable, Equatable {
    let id: Int64?
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: UUID
    
    // For Identifiable protocol - use a computed property
    var identifiableId: Int64 {
        return id ?? 0
    }
    
    // Coding keys to match database column names
    enum CodingKeys: String, CodingKey {
        case id
        case created_at
        case updated_at
        case content
        case owner_id
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
}

// MARK: - Promise Creation Helper
extension NewPromise {
    static func create(content: String, for userId: UUID) -> NewPromise {
        return NewPromise(content: content, owner_id: userId)
    }
} 