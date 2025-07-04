#!/usr/bin/swift

import Foundation

// Test data
struct TestWidgetPromise: Codable {
    let id: String
    let created_at: Date
    let updated_at: Date  
    let content: String
    let owner_id: String
    let resolved: Bool?
}

let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"

print("🔄 Force Widget Sync")
print("===================\n")

// Create test promises
let testPromises = [
    TestWidgetPromise(
        id: "1",
        created_at: Date().addingTimeInterval(-3600),
        updated_at: Date().addingTimeInterval(-3600),
        content: "Test promise 1 - Complete project",
        owner_id: "932376A3-57F8-46F7-A38D-6696F29B9ADC",
        resolved: false
    ),
    TestWidgetPromise(
        id: "2", 
        created_at: Date().addingTimeInterval(-7200),
        updated_at: Date().addingTimeInterval(-7200),
        content: "Test promise 2 - Call mom",
        owner_id: "932376A3-57F8-46F7-A38D-6696F29B9ADC",
        resolved: true
    ),
    TestWidgetPromise(
        id: "3",
        created_at: Date().addingTimeInterval(-10800),
        updated_at: Date().addingTimeInterval(-10800),
        content: "Test promise 3 - Finish reading book",
        owner_id: "932376A3-57F8-46F7-A38D-6696F29B9ADC",
        resolved: false
    )
]

// Access App Group
guard let defaults = UserDefaults(suiteName: appGroupID) else {
    print("❌ Cannot access App Group!")
    exit(1)
}

print("✅ App Group accessible")

// Encode and store promises
do {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    let data = try encoder.encode(testPromises)
    
    print("📦 Storing widget data:")
    print("   - Promises: \(testPromises.count)")
    print("   - Data size: \(data.count) bytes")
    
    // Store all widget keys
    defaults.set(data, forKey: "widget_promises")
    defaults.set(Date(), forKey: "widget_promises_updated")
    defaults.set("932376A3-57F8-46F7-A38D-6696F29B9ADC", forKey: "widget_user_id")
    defaults.set(NSNumber(value: true), forKey: "widget_is_authenticated")
    defaults.set(Date(), forKey: "widget_last_sync_time")
    
    // Force sync
    let syncSuccess = defaults.synchronize()
    print("   - Sync: \(syncSuccess ? "✅ Success" : "❌ Failed")")
    
    // Verify each key
    print("\n🔍 Verifying stored data:")
    
    if let storedData = defaults.data(forKey: "widget_promises") {
        print("✅ widget_promises: \(storedData.count) bytes")
        if let decoded = try? JSONDecoder().decode([TestWidgetPromise].self, from: storedData) {
            print("   Can decode \(decoded.count) promises")
            for promise in decoded {
                print("   - \(promise.content) (resolved: \(promise.resolved ?? false))")
            }
        }
    } else {
        print("❌ widget_promises: NOT FOUND")
    }
    
    if let userId = defaults.string(forKey: "widget_user_id") {
        print("✅ widget_user_id: \(userId)")
    } else {
        print("❌ widget_user_id: NOT FOUND")
    }
    
    let isAuth = defaults.bool(forKey: "widget_is_authenticated")
    print("✅ widget_is_authenticated: \(isAuth)")
    
    if let updated = defaults.object(forKey: "widget_promises_updated") as? Date {
        print("✅ widget_promises_updated: \(updated)")
    } else {
        print("❌ widget_promises_updated: NOT FOUND")
    }
    
    if let lastSync = defaults.object(forKey: "widget_last_sync_time") as? Date {
        print("✅ widget_last_sync_time: \(lastSync)")
    } else {
        print("❌ widget_last_sync_time: NOT FOUND")
    }
    
    print("\n✅ Force sync complete!")
    print("   Now check if the widget displays this data.")
    
} catch {
    print("❌ Error: \(error)")
}