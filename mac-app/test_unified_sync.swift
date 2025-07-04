#!/usr/bin/swift

import Foundation

// Mirror the structures from the shared framework for testing
struct TestWidgetPromise: Codable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool
}

struct TestWidgetData: Codable {
    let promises: [TestWidgetPromise]
    let userId: String?
    let userEmail: String?
    let isAuthenticated: Bool
    let lastUpdated: Date
    let version: Int
}

let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
let dataFileName = "widget_data.json"

print("🧪 Testing Unified Data Sync")
print("===========================\n")

// Get data file URL
guard let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupID
) else {
    print("❌ Cannot access App Group!")
    exit(1)
}

let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
let dataFileURL = dataDirectory.appendingPathComponent(dataFileName)

print("📁 Data location: \(dataFileURL.path)")

// Create test data
let testData = TestWidgetData(
    promises: [
        TestWidgetPromise(
            id: "test-1",
            created_at: Date().addingTimeInterval(-7200),
            updated_at: Date().addingTimeInterval(-7200),
            content: "Test promise 1 - From unified sync",
            owner_id: "test-user-123",
            resolved: false
        ),
        TestWidgetPromise(
            id: "test-2",
            created_at: Date().addingTimeInterval(-3600),
            updated_at: Date().addingTimeInterval(-3600),
            content: "Test promise 2 - Already completed",
            owner_id: "test-user-123",
            resolved: true
        ),
        TestWidgetPromise(
            id: "test-3",
            created_at: Date(),
            updated_at: Date(),
            content: "Test promise 3 - Just created",
            owner_id: "test-user-123",
            resolved: false
        )
    ],
    userId: "test-user-123",
    userEmail: "test@example.com",
    isAuthenticated: true,
    lastUpdated: Date(),
    version: 1
)

// Create directory if needed
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

// Encode and save
do {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    let data = try encoder.encode(testData)
    
    print("\n📝 Writing test data:")
    print("   - Promises: \(testData.promises.count)")
    print("   - User: \(testData.userEmail ?? "none")")
    print("   - Authenticated: \(testData.isAuthenticated)")
    print("   - Data size: \(data.count) bytes")
    
    // Write atomically
    try data.write(to: dataFileURL, options: [.atomic, .completeFileProtection])
    
    print("\n✅ Data written successfully!")
    
    // Verify by reading back
    let readData = try Data(contentsOf: dataFileURL)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    let verified = try decoder.decode(TestWidgetData.self, from: readData)
    
    print("\n🔍 Verification:")
    print("   - Read back: \(verified.promises.count) promises")
    print("   - First promise: \(verified.promises.first?.content ?? "none")")
    
    // Post notification
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("com.promisekeeper.widget.datachanged" as CFString),
        nil,
        nil,
        true
    )
    
    print("\n📢 Posted change notification")
    
    print("\n✅ Unified sync test complete!")
    print("   The widget should now display this test data.")
    
} catch {
    print("\n❌ Error: \(error)")
}