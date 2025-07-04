#!/usr/bin/swift

import Foundation

print("🧪 Testing Widget Fix")
print("===================\n")

// Test unified data structure (matching the updated types)
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

let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
let dataFileName = "widget_data.json"

// Get data location
guard let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupID
) else {
    print("❌ Cannot access App Group!")
    exit(1)
}

let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
let dataFileURL = dataDirectory.appendingPathComponent(dataFileName)

print("📁 Data location: \(dataFileURL.path)")

// Create test data that matches what the app would write
let testData = TestWidgetData(
    promises: [
        TestWidgetPromiseData(
            id: "1",
            created_at: Date().addingTimeInterval(-3600),
            updated_at: Date().addingTimeInterval(-3600),
            content: "Test widget sync - app to widget",
            owner_id: "test-user",
            resolved: false
        ),
        TestWidgetPromiseData(
            id: "2",
            created_at: Date().addingTimeInterval(-1800),
            updated_at: Date(),
            content: "Verify data synchronization works",
            owner_id: "test-user",
            resolved: true
        )
    ],
    userId: "test-user",
    userEmail: "test@example.com",
    isAuthenticated: true,
    lastUpdated: Date(),
    version: 1
)

// Create directory
if !FileManager.default.fileExists(atPath: dataDirectory.path) {
    do {
        try FileManager.default.createDirectory(
            at: dataDirectory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
        print("✅ Created data directory")
    } catch {
        print("❌ Failed to create directory: \(error)")
        exit(1)
    }
}

// Write test data
do {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    let data = try encoder.encode(testData)
    try data.write(to: dataFileURL, options: [.atomic, .completeFileProtection])
    
    print("\n✅ Test data written successfully")
    print("   - Promises: \(testData.promises.count)")
    print("   - User: \(testData.userEmail ?? "none")")
    print("   - Size: \(data.count) bytes")
    
    // Verify by reading back
    let readData = try Data(contentsOf: dataFileURL)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    let verified = try decoder.decode(TestWidgetData.self, from: readData)
    
    print("\n🔍 Verification:")
    print("   - Read back: \(verified.promises.count) promises")
    print("   - Auth state: \(verified.isAuthenticated)")
    print("   - First promise: \(verified.promises.first?.content ?? "none")")
    
    // Post notification
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("com.promisekeeper.widget.datachanged" as CFString),
        nil,
        nil,
        true
    )
    
    print("\n📢 Posted Darwin notification")
    print("\n✅ Widget fix test complete!")
    print("   The widget should now display this data if properly configured.")
    
} catch {
    print("\n❌ Error: \(error)")
    exit(1)
}