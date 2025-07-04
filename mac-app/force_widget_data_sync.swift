#!/usr/bin/swift

import Foundation

print("🔄 FORCING WIDGET DATA SYNC")
print("==========================\n")

// Direct test of UnifiedSharedDataManager
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

// Create test data that matches what the widget expects
struct TestWidgetPromiseData: Codable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool
}

struct TestWidgetData: Codable {
    let promises: [TestWidgetPromiseData]
    let userId: String?
    let userEmail: String?
    let isAuthenticated: Bool
    let lastUpdated: Date
    let version: Int
}

// Create test data
let testData = TestWidgetData(
    promises: [
        TestWidgetPromiseData(
            id: "test-1",
            created_at: Date(),
            updated_at: Date(),
            content: "TEST: This is a test promise to verify widget sync",
            owner_id: "test-user",
            resolved: false
        )
    ],
    userId: "test-user-id",
    userEmail: "test@example.com",
    isAuthenticated: true,
    lastUpdated: Date(),
    version: 1
)

// Ensure directory exists
try? FileManager.default.createDirectory(
    at: dataDirectory,
    withIntermediateDirectories: true,
    attributes: [.protectionKey: FileProtectionType.complete]
)

// Write data
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
encoder.outputFormatting = .prettyPrinted

do {
    let data = try encoder.encode(testData)
    try data.write(to: dataFileURL, options: [.atomic])
    print("✅ Test data written successfully")
    print("   File: \(dataFileURL.path)")
    print("   Size: \(data.count) bytes")
    
    // Verify
    if let verifyData = try? Data(contentsOf: dataFileURL) {
        print("\n✅ Verification: File exists and is readable")
        print("   Size: \(verifyData.count) bytes")
        
        if let json = try? JSONSerialization.jsonObject(with: verifyData) as? [String: Any] {
            print("   Authenticated: \(json["isAuthenticated"] ?? "?")")
            print("   Promises: \((json["promises"] as? [[String: Any]])?.count ?? 0)")
        }
    }
    
    // Post notification
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("com.promisekeeper.widget.datachanged" as CFString),
        nil,
        nil,
        true
    )
    print("\n📢 Widget notification posted")
    
} catch {
    print("❌ Error: \(error)")
}

print("\n✅ Force sync complete")
print("The widget should now show test data")