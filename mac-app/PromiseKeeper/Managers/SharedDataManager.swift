import Foundation
import WidgetKit

// MARK: - Widget Promise Model (shared between app and widget)
struct WidgetPromise: Identifiable, Codable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool?
    
    // Convenience properties
    var createdAt: Date { created_at }
    var isResolved: Bool { resolved ?? false }
    
    // Direct initializer for widget data
    init(id: String, created_at: Date, updated_at: Date, content: String, owner_id: String, resolved: Bool?) {
        self.id = id
        self.created_at = created_at
        self.updated_at = updated_at
        self.content = content
        self.owner_id = owner_id
        self.resolved = resolved
    }
}

// MARK: - Shared Data Storage (for widget communication)
class SharedDataManager {
    static let shared = SharedDataManager()
    
    // App Group identifier - must match in both targets
    static let appGroupIdentifier = "group.TX645N2QBW.com.example.mac.PromiseKeeper"
    
    // Keys for UserDefaults
    private struct Keys {
        static let promises = "widget_promises"
        static let promisesUpdated = "widget_promises_updated"
        static let userId = "widget_user_id"
        static let isAuthenticated = "widget_is_authenticated"
        static let lastSyncTime = "widget_last_sync_time"
        static let appVersion = "widget_app_version"
        static let debugTestKey = "widget_debug_test"
    }
    
    private init() {
        verifyAppGroupAccess()
    }
    
    private var userDefaults: UserDefaults? {
        let identifier = SharedDataManager.appGroupIdentifier
        let defaults = UserDefaults(suiteName: identifier)
        if defaults == nil {
            print("❌ SharedDataManager: Failed to access App Group '\(identifier)'")
            print("❌ Make sure:")
            print("   1. App Group is enabled in both app and widget targets in Xcode")
            print("   2. App Group identifier matches in both entitlements files")
            print("   3. Clean build folder (Cmd+Shift+K) and rebuild")
            print("   4. Check Signing & Capabilities in Xcode for both targets")
            
            // Try to provide more specific guidance
            if identifier.contains("TX645N2QBW") {
                print("   5. In Xcode, add App Group: \(identifier)")
            }
        }
        return defaults
    }
    
    // MARK: - Verification Methods
    
    func verifyAppGroupAccess() {
        guard let defaults = userDefaults else {
            print("❌ App Group not accessible!")
            return
        }
        
        // Write test value
        let testValue = "test_\(Date().timeIntervalSince1970)"
        defaults.set(testValue, forKey: Keys.debugTestKey)
        
        // Force synchronization (though deprecated, still works)
        defaults.synchronize()
        
        // Read back immediately
        let readValue = defaults.string(forKey: Keys.debugTestKey)
        
        if readValue == testValue {
            print("✅ App Group access verified successfully")
            print("✅ App Group ID: \(SharedDataManager.appGroupIdentifier)")
        } else {
            print("❌ App Group read/write test failed!")
            print("   Wrote: \(testValue)")
            print("   Read: \(readValue ?? "nil")")
        }
    }
    
    // MARK: - Promise Storage
    
    func storePromises(_ promises: [WidgetPromise]) {
        guard let defaults = userDefaults else {
            print("❌ Cannot store promises - App Group not accessible")
            return
        }
        
        print("🔄 SharedDataManager: Storing \(promises.count) promises...")
        
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(promises)
            
            // Store with explicit key names
            defaults.set(data, forKey: Keys.promises)
            defaults.set(Date(), forKey: Keys.promisesUpdated)
            defaults.set(Date(), forKey: Keys.lastSyncTime)
            
            // Force synchronization - CRITICAL for widget data
            let syncResult = defaults.synchronize()
            print("   Sync result: \(syncResult)")
            
            print("✅ Stored \(promises.count) promises for widget")
            print("   Data size: \(data.count) bytes")
            print("   Keys used: \(Keys.promises)")
            
            // Verify storage immediately
            if let verifyData = defaults.data(forKey: Keys.promises) {
                print("✅ Verification: Data stored successfully (\(verifyData.count) bytes)")
                
                // Double-check by trying to decode
                if let decoded = try? JSONDecoder().decode([WidgetPromise].self, from: verifyData) {
                    print("✅ Can decode \(decoded.count) promises")
                }
            } else {
                print("❌ CRITICAL ERROR: Data was not persisted to UserDefaults!")
                print("   This is why the widget shows no data!")
            }
            
            // Trigger widget update with a slight delay to ensure data is written
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                WidgetCenter.shared.reloadAllTimelines()
                print("🔄 Widget timelines reloaded")
            }
            
        } catch {
            print("❌ Failed to encode promises: \(error)")
        }
    }
    
    func loadPromises() -> [WidgetPromise] {
        guard let defaults = userDefaults else {
            print("❌ Cannot load promises - App Group not accessible")
            return []
        }
        
        guard let data = defaults.data(forKey: Keys.promises) else {
            print("📱 No promises found in shared storage")
            return []
        }
        
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let promises = try decoder.decode([WidgetPromise].self, from: data)
            print("✅ Loaded \(promises.count) promises from shared storage")
            return promises
        } catch {
            print("❌ Failed to decode promises: \(error)")
            return []
        }
    }
    
    // MARK: - User Info Storage
    
    func storeUserInfo(userId: String?, isAuthenticated: Bool) {
        guard let defaults = userDefaults else {
            print("❌ Cannot store user info - App Group not accessible")
            return
        }
        
        print("👤 Storing user info:")
        print("   - Authenticated: \(isAuthenticated)")
        print("   - User ID: \(userId ?? "nil")")
        
        // Store values with explicit types to ensure proper storage
        if let userId = userId {
            defaults.set(userId, forKey: Keys.userId)
        } else {
            defaults.removeObject(forKey: Keys.userId)
        }
        
        // IMPORTANT: Store bool as NSNumber to ensure it's properly saved
        // This fixes the issue where widget reads false for non-existent keys
        defaults.set(NSNumber(value: isAuthenticated), forKey: Keys.isAuthenticated)
        defaults.set(Date(), forKey: Keys.lastSyncTime)
        defaults.set(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown", forKey: Keys.appVersion)
        
        // Force synchronization (deprecated but still helps ensure data is written)
        defaults.synchronize()
        
        // Verify storage
        let storedAuth = defaults.bool(forKey: Keys.isAuthenticated)
        let storedUserId = defaults.string(forKey: Keys.userId)
        
        if storedAuth == isAuthenticated && storedUserId == userId {
            print("✅ User info stored and verified successfully")
        } else {
            print("❌ User info verification failed!")
            print("   Expected auth: \(isAuthenticated), got: \(storedAuth)")
            print("   Expected userId: \(userId ?? "nil"), got: \(storedUserId ?? "nil")")
        }
        
        // Trigger widget update with a slight delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            WidgetCenter.shared.reloadAllTimelines()
            print("🔄 Widget timelines reloaded for auth update")
        }
    }
    
    func loadUserInfo() -> (userId: String?, isAuthenticated: Bool) {
        guard let defaults = userDefaults else {
            print("❌ Cannot load user info - App Group not accessible")
            return (nil, false)
        }
        
        let userId = defaults.string(forKey: Keys.userId)
        // IMPORTANT: Read as NSNumber to handle non-existent keys properly
        let isAuthenticated = (defaults.object(forKey: Keys.isAuthenticated) as? NSNumber)?.boolValue ?? false
        let lastSync = defaults.object(forKey: Keys.lastSyncTime) as? Date
        let appVersion = defaults.string(forKey: Keys.appVersion)
        
        print("👤 Loaded user info:")
        print("   - Authenticated: \(isAuthenticated)")
        print("   - User ID: \(userId ?? "nil")")
        print("   - Last sync: \(lastSync?.description ?? "never")")
        print("   - App version: \(appVersion ?? "unknown")")
        
        return (userId, isAuthenticated)
    }
    
    // MARK: - Debug Methods
    
    func debugPrintAllStoredData() {
        guard let defaults = userDefaults else {
            print("❌ Cannot debug - App Group not accessible")
            return
        }
        
        print("\n=== SharedDataManager Debug Info ===")
        print("App Group ID: \(SharedDataManager.appGroupIdentifier)")
        print("\nStored values:")
        
        let keys = [Keys.promises, Keys.promisesUpdated, Keys.userId, Keys.isAuthenticated, Keys.lastSyncTime, Keys.appVersion, Keys.debugTestKey]
        
        for key in keys {
            if let value = defaults.object(forKey: key) {
                print("  \(key): \(value)")
            } else {
                print("  \(key): nil")
            }
        }
        
        print("\nAll keys in UserDefaults:")
        for (key, value) in defaults.dictionaryRepresentation() {
            print("  \(key): \(type(of: value)) = \(String(describing: value).prefix(100))...")
        }
        
        print("=== End Debug Info ===\n")
    }
    
    // MARK: - Cleanup Methods
    
    func clearAllWidgetData() {
        guard let defaults = userDefaults else {
            print("❌ Cannot clear data - App Group not accessible")
            return
        }
        
        let keys = [Keys.promises, Keys.promisesUpdated, Keys.userId, Keys.isAuthenticated, Keys.lastSyncTime, Keys.appVersion, Keys.debugTestKey]
        
        for key in keys {
            defaults.removeObject(forKey: key)
        }
        
        defaults.synchronize()
        print("🗑️ Cleared all widget data")
        
        // Reload widget
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Promise Sync Methods (for use by PromiseManager)
    
    /// Sync promises from the main app using generic approach to avoid circular dependency
    /// The promises parameter accepts any type that has the required properties
    func syncPromisesFromApp<T>(_ promises: [T], userId: String?, isAuthenticated: Bool,
                                transform: (T) -> WidgetPromise) {
        print("🔄 Syncing \(promises.count) promises from main app...")
        
        // Convert Promise objects to WidgetPromise objects using the transform closure
        let widgetPromises = promises.map(transform)
        
        // Store the converted promises
        storePromises(widgetPromises)
        
        // Store user info
        storeUserInfo(userId: userId, isAuthenticated: isAuthenticated)
        
        print("✅ Sync complete: \(widgetPromises.count) promises synced to widget")
    }
}