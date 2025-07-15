import Foundation
import WidgetKit

/// Dedicated manager for syncing data with the widget
/// This ensures all promise data is properly shared with the widget extension
@MainActor
class WidgetDataSyncManager: ObservableObject {
    static let shared = WidgetDataSyncManager()
    
    private let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
    
    private init() {
        print("📱 WidgetDataSyncManager initialized")
    }
    
    /// Sync all promise data with the widget
    func syncPromises(_ promises: [Promise], userId: String?, isAuthenticated: Bool) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("❌ Cannot access App Group for widget sync!")
            return
        }
        
        print("🔄 Syncing \(promises.count) promises to widget...")
        
        // Convert Promise objects to WidgetPromise objects
        let widgetPromises = promises.map { promise in
            WidgetPromise(
                id: String(promise.id ?? 0),
                created_at: promise.created_at,
                updated_at: promise.updated_at,
                content: promise.content,
                owner_id: promise.owner_id.uuidString,
                resolved: promise.resolved
            )
        }
        
        // Encode promises
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(widgetPromises)
            
            // Store all widget data
            defaults.set(data, forKey: "widget_promises")
            defaults.set(Date(), forKey: "widget_promises_updated")
            defaults.set(userId, forKey: "widget_user_id")
            defaults.set(NSNumber(value: isAuthenticated), forKey: "widget_is_authenticated")
            defaults.set(Date(), forKey: "widget_last_sync_time")
            
            // Force synchronization
            let success = defaults.synchronize()
            
            print("✅ Widget sync complete:")
            print("   - Promises: \(widgetPromises.count)")
            print("   - Data size: \(data.count) bytes")
            print("   - Authenticated: \(isAuthenticated)")
            print("   - Sync success: \(success)")
            
            // Verify the data was written
            if let verifyData = defaults.data(forKey: "widget_promises") {
                print("✅ Verified: Data exists in UserDefaults (\(verifyData.count) bytes)")
                
                // Double-check by decoding
                if let decoded = try? JSONDecoder().decode([WidgetPromise].self, from: verifyData) {
                    print("✅ Verified: Can decode \(decoded.count) promises")
                }
            } else {
                print("❌ ERROR: Data was not persisted!")
            }
            
            // Reload widget timelines
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 Widget timeline reload triggered")
            
        } catch {
            print("❌ Failed to encode promises for widget: \(error)")
        }
    }
    
    /// Clear all widget data (on sign out)
    func clearWidgetData() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("❌ Cannot access App Group to clear widget data!")
            return
        }
        
        print("🗑️ Clearing widget data...")
        
        defaults.removeObject(forKey: "widget_promises")
        defaults.removeObject(forKey: "widget_promises_updated")
        defaults.removeObject(forKey: "widget_user_id")
        defaults.removeObject(forKey: "widget_is_authenticated")
        defaults.removeObject(forKey: "widget_last_sync_time")
        
        defaults.synchronize()
        
        // Reload widget timelines
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ Widget data cleared")
    }
    
    /// Debug method to check what's stored
    func debugPrintStoredData() {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("❌ Cannot access App Group for debug!")
            return
        }
        
        print("\n🔍 Widget Data Debug:")
        print("=====================")
        
        let keys = [
            "widget_promises",
            "widget_promises_updated",
            "widget_user_id",
            "widget_is_authenticated",
            "widget_last_sync_time"
        ]
        
        for key in keys {
            if let value = defaults.object(forKey: key) {
                print("✅ \(key): \(type(of: value))")
                
                switch key {
                case "widget_promises":
                    if let data = value as? Data {
                        print("   Size: \(data.count) bytes")
                        if let promises = try? JSONDecoder().decode([WidgetPromise].self, from: data) {
                            print("   Count: \(promises.count) promises")
                            for (index, promise) in promises.prefix(3).enumerated() {
                                print("   [\(index)] \(promise.content) - Resolved: \(promise.resolved ?? false)")
                            }
                        }
                    }
                case "widget_is_authenticated":
                    print("   Bool: \(defaults.bool(forKey: key))")
                    if let nsNumber = value as? NSNumber {
                        print("   NSNumber: \(nsNumber.boolValue)")
                    }
                default:
                    print("   Value: \(value)")
                }
            } else {
                print("❌ \(key): NOT FOUND")
            }
        }
        
        print("=====================\n")
    }
}