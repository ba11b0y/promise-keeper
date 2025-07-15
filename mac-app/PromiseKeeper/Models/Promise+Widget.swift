import Foundation
import PromiseKeeperShared

// MARK: - Promise Widget Conversion
extension Promise: AppPromiseConvertible {
    var promiseId: String {
        String(id ?? 0)
    }
    
    var promiseCreatedAt: Date {
        created_at
    }
    
    var promiseUpdatedAt: Date {
        updated_at
    }
    
    var promiseContent: String {
        content
    }
    
    var promiseOwnerId: String {
        owner_id.uuidString
    }
    
    var promiseResolved: Bool {
        resolved ?? false
    }
}