import Foundation
import WidgetKit

/// Debug manager to help diagnose widget authentication issues
class WidgetDebugManager {
    static let shared = WidgetDebugManager()
    
    private init() {}
    
    /// Comprehensive debug function to test App Group access
    func runComprehensiveDiagnostics() {
        print("\n========== WIDGET DEBUG DIAGNOSTICS ==========")
        print("Date: \(Date())")
        print("App Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")")
        
        // 1. Test App Group Access
        testAppGroupAccess()
        
        // 2. Test Data Storage and Retrieval
        testDataStorageAndRetrieval()
        
        // 3. Check Current Stored Values
        checkCurrentStoredValues()
        
        // 4. Test Widget Communication
        testWidgetCommunication()
        
        print("========== END DIAGNOSTICS ==========\n")
    }
    
    private func testAppGroupAccess() {
        print("\n--- Testing App Group Access ---")
        let appGroupId = SharedDataManager.appGroupIdentifier
        print("App Group ID: \(appGroupId)")
        
        guard let defaults = UserDefaults(suiteName: appGroupId) else {
            print("❌ CRITICAL: Cannot create UserDefaults with App Group ID!")
            print("   This means the App Group is not properly configured.")
            print("   Check that:")
            print("   1. Both app and widget have the App Group capability enabled")
            print("   2. The App Group ID matches exactly in both entitlements")
            print("   3. The provisioning profiles include the App Group")
            return
        }
        
        print("✅ UserDefaults created successfully")
        
        // Test write
        let testKey = "debug_test_\(Date().timeIntervalSince1970)"
        let testValue = "test_value_\(UUID().uuidString)"
        defaults.set(testValue, forKey: testKey)
        
        // Force sync (though deprecated)
        defaults.synchronize()
        
        // Test immediate read
        if let readValue = defaults.string(forKey: testKey) {
            if readValue == testValue {
                print("✅ Write/Read test passed")
            } else {
                print("❌ Write/Read test failed - values don't match")
                print("   Written: \(testValue)")
                print("   Read: \(readValue)")
            }
        } else {
            print("❌ Write/Read test failed - couldn't read value")
        }
        
        // Clean up
        defaults.removeObject(forKey: testKey)
    }
    
    private func testDataStorageAndRetrieval() {
        print("\n--- Testing Data Storage and Retrieval ---")
        
        // Test authentication storage
        print("Testing authentication storage...")
        SharedDataManager.shared.storeUserInfo(userId: "test-user-123", isAuthenticated: true)
        
        // Small delay to ensure write completes
        Thread.sleep(forTimeInterval: 0.1)
        
        let (userId, isAuth) = SharedDataManager.shared.loadUserInfo()
        
        if userId == "test-user-123" && isAuth == true {
            print("✅ Authentication storage test passed")
        } else {
            print("❌ Authentication storage test failed")
            print("   Expected: userId='test-user-123', isAuthenticated=true")
            print("   Got: userId='\(userId ?? "nil")', isAuthenticated=\(isAuth)")
        }
        
        // Test promise storage
        print("\nTesting promise storage...")
        let testPromises = [
            WidgetPromise(
                id: "test-1",
                created_at: Date(),
                updated_at: Date(),
                content: "Test Promise 1",
                owner_id: "test-user-123",
                resolved: false
            )
        ]
        
        SharedDataManager.shared.storePromises(testPromises)
        Thread.sleep(forTimeInterval: 0.1)
        
        let loadedPromises = SharedDataManager.shared.loadPromises()
        if loadedPromises.count == 1 && loadedPromises[0].id == "test-1" {
            print("✅ Promise storage test passed")
        } else {
            print("❌ Promise storage test failed")
            print("   Expected: 1 promise with id='test-1'")
            print("   Got: \(loadedPromises.count) promises")
        }
    }
    
    private func checkCurrentStoredValues() {
        print("\n--- Current Stored Values ---")
        SharedDataManager.shared.debugPrintAllStoredData()
    }
    
    private func testWidgetCommunication() {
        print("\n--- Testing Widget Communication ---")
        
        // Store test data
        SharedDataManager.shared.storeUserInfo(userId: "widget-test-user", isAuthenticated: true)
        
        print("Triggering widget reload...")
        WidgetCenter.shared.reloadAllTimelines()
        print("✅ Widget reload triggered")
        
        print("\nTo verify widget is receiving data:")
        print("1. Check Console.app for logs from 'PromiseWidget' process")
        print("2. Look for messages starting with '📱 Widget:'")
        print("3. The widget should show authentication state within 5 seconds")
    }
    
    /// Call this when user signs in to debug the flow
    func debugAuthenticationFlow(userId: String) {
        print("\n🔐 DEBUG: Authentication Flow Started")
        print("User ID: \(userId)")
        print("Time: \(Date())")
        
        // Check before storage
        let (beforeUserId, beforeAuth) = SharedDataManager.shared.loadUserInfo()
        print("Before - userId: \(beforeUserId ?? "nil"), isAuthenticated: \(beforeAuth)")
        
        // Store new auth state
        SharedDataManager.shared.storeUserInfo(userId: userId, isAuthenticated: true)
        
        // Check immediately after
        Thread.sleep(forTimeInterval: 0.1)
        let (afterUserId, afterAuth) = SharedDataManager.shared.loadUserInfo()
        print("After - userId: \(afterUserId ?? "nil"), isAuthenticated: \(afterAuth)")
        
        // Check if values persisted
        if afterUserId == userId && afterAuth == true {
            print("✅ Authentication successfully stored")
        } else {
            print("❌ Authentication storage failed!")
        }
        
        // Trigger widget update
        WidgetCenter.shared.reloadAllTimelines()
        print("🔄 Widget reload triggered")
    }
}