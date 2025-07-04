#!/usr/bin/swift

import Foundation

// App Group identifier
let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"

print("🔍 Testing Widget Data Access")
print("============================\n")

// Test 1: Can we access the App Group?
print("1️⃣ Testing App Group Access:")
if let defaults = UserDefaults(suiteName: appGroupID) {
    print("✅ Can access App Group: \(appGroupID)")
    
    // Test write/read
    let testKey = "test_\(Date().timeIntervalSince1970)"
    defaults.set("test_value", forKey: testKey)
    if defaults.string(forKey: testKey) == "test_value" {
        print("✅ Can write and read from App Group")
        defaults.removeObject(forKey: testKey)
    } else {
        print("❌ Cannot write/read from App Group")
    }
} else {
    print("❌ Cannot access App Group!")
}

print("\n2️⃣ Checking Widget Data:")

// Check authentication state
if let defaults = UserDefaults(suiteName: appGroupID) {
    // Check all widget keys
    let widgetKeys = [
        "widget_is_authenticated",
        "widget_user_id", 
        "widget_promises",
        "widget_promises_updated",
        "widget_last_sync_time"
    ]
    
    for key in widgetKeys {
        if let value = defaults.object(forKey: key) {
            print("✅ \(key): \(type(of: value))")
            
            // Special handling for different types
            switch key {
            case "widget_is_authenticated":
                // Check both as Bool and NSNumber
                let boolValue = defaults.bool(forKey: key)
                let nsNumberValue = value as? NSNumber
                print("   Bool value: \(boolValue)")
                print("   NSNumber value: \(nsNumberValue?.boolValue ?? false)")
                
            case "widget_promises":
                if let data = value as? Data {
                    print("   Data size: \(data.count) bytes")
                    // Try to decode
                    do {
                        let decoder = JSONDecoder()
                        decoder.dateDecodingStrategy = .iso8601
                        if let jsonObject = try? JSONSerialization.jsonObject(with: data, options: []) {
                            print("   JSON structure: \(jsonObject)")
                        }
                    }
                }
                
            case "widget_promises_updated", "widget_last_sync_time":
                if let date = value as? Date {
                    print("   Date: \(date)")
                    print("   Time ago: \(Date().timeIntervalSince(date)) seconds")
                }
                
            default:
                print("   Value: \(value)")
            }
        } else {
            print("❌ \(key): NOT FOUND")
        }
    }
}

print("\n3️⃣ Checking Keychain Data:")

// Check keychain for session
let keychainKeys = [
    "supabase_session",
    "supabase_user_id",
    "supabase_user_email",
    "supabase_session_expiry"
]

for key in keychainKeys {
    let query: [String: Any] = [
        kSecClass as String: kSecClassGenericPassword,
        kSecAttrAccount as String: key,
        kSecAttrAccessGroup as String: "TX645N2QBW.com.example.mac.SidebarApp",
        kSecReturnData as String: true,
        kSecMatchLimit as String: kSecMatchLimitOne
    ]
    
    var dataTypeRef: AnyObject?
    let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
    
    if status == errSecSuccess, let data = dataTypeRef as? Data {
        print("✅ \(key): Found (\(data.count) bytes)")
        if let string = String(data: data, encoding: .utf8) {
            print("   String value: \(string)")
        }
    } else {
        print("❌ \(key): NOT FOUND (status: \(status))")
    }
}

print("\n4️⃣ All UserDefaults Keys in App Group:")
if let defaults = UserDefaults(suiteName: appGroupID) {
    let allKeys = defaults.dictionaryRepresentation().keys.sorted()
    for key in allKeys {
        if let value = defaults.object(forKey: key) {
            print("   \(key): \(type(of: value))")
        }
    }
}

print("\n✅ Test complete!")