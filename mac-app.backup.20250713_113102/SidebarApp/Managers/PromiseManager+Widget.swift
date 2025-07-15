import Foundation
import PromiseKeeperShared

// MARK: - PromiseManager Widget Extension
extension PromiseManager {
    
    /// Update widget data using the unified data manager
    func updateWidgetData() {
        let widgetPromises = PromiseConverter.toWidgetPromises(from: promises)
        
        let widgetData = WidgetData(
            promises: widgetPromises,
            userId: supabaseManager.currentUser?.id.uuidString,
            userEmail: supabaseManager.currentUser?.email,
            isAuthenticated: supabaseManager.isAuthenticated,
            lastUpdated: Date()
        )
        
        let success = UnifiedDataManager.shared.save(widgetData)
        
        if success {
            print("✅ Widget data updated: \(widgetPromises.count) promises")
        } else {
            print("❌ Failed to update widget data")
        }
    }
}