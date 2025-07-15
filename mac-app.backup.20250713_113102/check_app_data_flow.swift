#!/usr/bin/swift

import Foundation

// Test data structure to match widget
struct TestWidgetPromise: Codable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool?
}

// Check the complete data flow

let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"

print("🔍 Checking App Data Flow")
print("========================\n")

// 1. Check App Group access
guard let defaults = UserDefaults(suiteName: appGroupID) else {
    print("❌ Cannot access App Group!")
    exit(1)
}

print("✅ App Group accessible: \(appGroupID)\n")

// 2. Check current widget data
print("📱 Current Widget Data:")
print("---------------------")

let widgetKeys = [
    "widget_promises",
    "widget_promises_updated",
    "widget_user_id",
    "widget_is_authenticated", 
    "widget_last_sync_time"
]

var hasData = false
for key in widgetKeys {
    if let value = defaults.object(forKey: key) {
        hasData = true
        print("✅ \(key): ", terminator: "")
        
        switch key {
        case "widget_promises":
            if let data = value as? Data {
                print("\(data.count) bytes")
                // Try to decode
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                if let decoded = try? decoder.decode([TestWidgetPromise].self, from: data) {
                    print("   - Can decode: \(decoded.count) promises")
                    for (i, promise) in decoded.prefix(3).enumerated() {
                        print("   [\(i)] \(promise.content) - resolved: \(promise.resolved ?? false)")
                    }
                } else {
                    print("   - Cannot decode as promises")
                }
            }
        case "widget_is_authenticated":
            if let nsNumber = value as? NSNumber {
                print("NSNumber(\(nsNumber.boolValue))")
            } else {
                print("Bool(\(defaults.bool(forKey: key)))")
            }
        case "widget_promises_updated", "widget_last_sync_time":
            if let date = value as? Date {
                let formatter = DateFormatter()
                formatter.dateStyle = .short
                formatter.timeStyle = .medium
                print(formatter.string(from: date))
            }
        default:
            print("\(value)")
        }
    } else {
        print("❌ \(key): NOT FOUND")
    }
}

if !hasData {
    print("\n⚠️  NO WIDGET DATA FOUND!")
    print("This explains why the widget shows zeros.\n")
}

// 3. Check ALL keys in UserDefaults
print("\n🗂️  All Keys in App Group:")
print("------------------------")
let allKeys = defaults.dictionaryRepresentation().keys.sorted()
if allKeys.isEmpty {
    print("❌ NO KEYS FOUND - App Group is empty!")
} else {
    for key in allKeys {
        if let value = defaults.object(forKey: key) {
            print("- \(key): \(type(of: value))")
        }
    }
}

// 4. Test write capability
print("\n✍️  Testing Write Capability:")
print("---------------------------")
let testKey = "test_write_\(Date().timeIntervalSince1970)"
let testValue = "Hello from test script"
defaults.set(testValue, forKey: testKey)
defaults.synchronize()

if let readBack = defaults.string(forKey: testKey), readBack == testValue {
    print("✅ Can write and read data")
    defaults.removeObject(forKey: testKey)
} else {
    print("❌ Cannot write/read data!")
}

print("\n📊 Summary:")
print("----------")
if hasData {
    print("✅ Widget data exists but may be outdated")
    print("   → Check PromiseManager.updateSharedData() is being called")
    print("   → Verify WidgetDataSyncManager is working")
} else {
    print("❌ No widget data found!")
    print("   → The app is NOT syncing data to the widget")
    print("   → Check that fetchPromises() calls updateSharedData()")
    print("   → Verify WidgetDataSyncManager is initialized")
}

// Provide clear next steps
print("\n🔧 Next Steps:")
print("1. Run the app and sign in")
print("2. Check Console.app for 'PromiseManager' and 'WidgetDataSyncManager' logs")
print("3. Look for '📱 Updated shared data for widget' messages")
print("4. Verify promises are being fetched from Supabase")