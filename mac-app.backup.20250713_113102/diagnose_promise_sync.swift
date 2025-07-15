#!/usr/bin/swift

import Foundation

// Diagnostic script to trace promise sync issues

print("🔍 PROMISE SYNC DIAGNOSTIC")
print("=========================\n")

// 1. Check Widget Data
let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
let dataFileName = "widget_data.json"

guard let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupID
) else {
    print("❌ Cannot access App Group!")
    exit(1)
}

let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
let dataFileURL = dataDirectory.appendingPathComponent(dataFileName)

struct DiagWidgetPromiseData: Codable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool
}

struct DiagWidgetData: Codable {
    let promises: [DiagWidgetPromiseData]
    let userId: String?
    let userEmail: String?
    let isAuthenticated: Bool
    let lastUpdated: Date
    let version: Int
}

print("1️⃣ WIDGET DATA STATUS")
print("---------------------")

if FileManager.default.fileExists(atPath: dataFileURL.path) {
    do {
        let data = try Data(contentsOf: dataFileURL)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let widgetData = try decoder.decode(DiagWidgetData.self, from: data)
        
        print("✅ Widget data found:")
        print("   - Authenticated: \(widgetData.isAuthenticated)")
        print("   - User: \(widgetData.userEmail ?? "none")")
        print("   - UserID: \(widgetData.userId ?? "none")")
        print("   - Promises: \(widgetData.promises.count)")
        print("   - Last Updated: \(widgetData.lastUpdated)")
        
        if widgetData.promises.isEmpty && widgetData.isAuthenticated {
            print("\n⚠️  PROBLEM IDENTIFIED: User is authenticated but has NO promises!")
            print("   This suggests promises are not being synced from Supabase.")
        }
        
        if !widgetData.promises.isEmpty {
            print("\n   Promise Details:")
            for (i, promise) in widgetData.promises.prefix(3).enumerated() {
                print("   [\(i)] \(promise.content.prefix(50))... (resolved: \(promise.resolved))")
            }
        }
        
    } catch {
        print("❌ Error reading widget data: \(error)")
    }
} else {
    print("❌ No widget data file exists")
}

// 2. Check Keychain Session
print("\n2️⃣ KEYCHAIN SESSION STATUS")
print("-------------------------")

let keychainKey = "com.promisekeeper.session"
let keychainQuery: [String: Any] = [
    kSecClass as String: kSecClassGenericPassword,
    kSecAttrAccount as String: keychainKey,
    kSecReturnData as String: kCFBooleanTrue!,
    kSecMatchLimit as String: kSecMatchLimitOne
]

var item: CFTypeRef?
let status = SecItemCopyMatching(keychainQuery as CFDictionary, &item)

if status == errSecSuccess, let data = item as? Data {
    do {
        let sessionData = try JSONDecoder().decode([String: String].self, from: data)
        print("✅ Keychain session found:")
        print("   - UserID: \(sessionData["userId"] ?? "none")")
        print("   - Email: \(sessionData["email"] ?? "none")")
        if let expiresAt = sessionData["expiresAt"] {
            print("   - Expires: \(expiresAt)")
        }
    } catch {
        print("❌ Error decoding session: \(error)")
    }
} else {
    print("❌ No session in Keychain (status: \(status))")
}

// 3. Check UserDefaults (Legacy)
print("\n3️⃣ USERDEFAULTS STATUS (Legacy)")
print("-------------------------------")

if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
    let userId = sharedDefaults.string(forKey: "userId")
    let isAuth = sharedDefaults.object(forKey: "isAuthenticated") as? NSNumber
    
    print("Legacy UserDefaults:")
    print("   - UserID: \(userId ?? "none")")
    print("   - Authenticated: \(isAuth?.boolValue ?? false)")
}

// 4. Diagnosis Summary
print("\n4️⃣ DIAGNOSIS SUMMARY")
print("-------------------")

print("""
Based on the data above, here are the possible issues:

1. If authenticated but no promises:
   → PromiseManager.fetchPromises() may not be getting called
   → Supabase query might be failing silently
   → Promise sync to widget might not be triggered

2. If no auth data at all:
   → User is not signed in
   → Auth state is not being shared properly

3. Next debugging steps:
   → Check if fetchPromises() is being called in the main app
   → Add logging to see if Supabase returns any promises
   → Verify updateSharedData() is called after fetch
   → Check Supabase dashboard for actual promise data
""")

// 5. Try to simulate a promise sync
print("\n5️⃣ SIMULATING PROMISE SYNC")
print("-------------------------")

if let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupID
) {
    // Read current data
    if let data = try? Data(contentsOf: dataFileURL),
       let current = try? JSONDecoder().decode(DiagWidgetData.self, from: data) {
        
        if current.isAuthenticated && current.promises.isEmpty {
            print("⚠️  Creating test promise to verify sync mechanism...")
            
            let testPromise = DiagWidgetPromiseData(
                id: "test-\(Int(Date().timeIntervalSince1970))",
                created_at: Date(),
                updated_at: Date(),
                content: "TEST: Diagnostic promise created at \(Date())",
                owner_id: current.userId ?? "unknown",
                resolved: false
            )
            
            let updatedData = DiagWidgetData(
                promises: [testPromise],
                userId: current.userId,
                userEmail: current.userEmail,
                isAuthenticated: current.isAuthenticated,
                lastUpdated: Date(),
                version: 1
            )
            
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            if let encoded = try? encoder.encode(updatedData) {
                try? encoded.write(to: dataFileURL, options: [.atomic])
                print("✅ Test promise written. Widget should now show 1 promise.")
                
                // Post notification
                CFNotificationCenterPostNotification(
                    CFNotificationCenterGetDarwinNotifyCenter(),
                    CFNotificationName("com.promisekeeper.widget.datachanged" as CFString),
                    nil,
                    nil,
                    true
                )
                print("📢 Notification sent to widget")
            }
        }
    }
}

print("\n✅ Diagnostic complete")