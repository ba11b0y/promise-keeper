#!/usr/bin/swift

import Foundation

// Mirror the unified data structures
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

print("🧪 Testing Unified Widget System")
print("==============================\n")

let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
let dataFileName = "widget_data.json"

// Get unified data file location
guard let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupID
) else {
    print("❌ Cannot access App Group!")
    exit(1)
}

let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
let dataFileURL = dataDirectory.appendingPathComponent(dataFileName)

print("📁 Unified data location: \(dataFileURL.path)")

// Create realistic test data
let testData = TestWidgetData(
    promises: [
        TestWidgetPromise(
            id: "1",
            created_at: Date().addingTimeInterval(-86400), // 1 day ago
            updated_at: Date().addingTimeInterval(-86400),
            content: "Finish quarterly report by end of week",
            owner_id: "user-123-456",
            resolved: false
        ),
        TestWidgetPromise(
            id: "2",
            created_at: Date().addingTimeInterval(-7200), // 2 hours ago
            updated_at: Date().addingTimeInterval(-3600), // 1 hour ago
            content: "Call dentist to schedule appointment",
            owner_id: "user-123-456",
            resolved: true
        ),
        TestWidgetPromise(
            id: "3",
            created_at: Date().addingTimeInterval(-1800), // 30 min ago
            updated_at: Date().addingTimeInterval(-1800),
            content: "Review pull request from team member",
            owner_id: "user-123-456",
            resolved: false
        ),
        TestWidgetPromise(
            id: "4",
            created_at: Date().addingTimeInterval(-300), // 5 min ago
            updated_at: Date().addingTimeInterval(-300),
            content: "Buy groceries on way home",
            owner_id: "user-123-456",
            resolved: false
        )
    ],
    userId: "user-123-456",
    userEmail: "user@company.com",
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
        print("✅ Created unified data directory")
    } catch {
        print("❌ Failed to create directory: \(error)")
        exit(1)
    }
}

// Encode and save atomically
do {
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    let data = try encoder.encode(testData)
    
    print("\n📝 Writing unified test data:")
    print("   - Promises: \(testData.promises.count)")
    print("   - Completed: \(testData.promises.filter { $0.resolved }.count)")
    print("   - Pending: \(testData.promises.filter { !$0.resolved }.count)")
    print("   - User: \(testData.userEmail ?? "none")")
    print("   - Authenticated: \(testData.isAuthenticated)")
    print("   - Data size: \(data.count) bytes")
    
    // Write atomically with file protection
    try data.write(to: dataFileURL, options: [.atomic, .completeFileProtection])
    
    print("\n✅ Unified data written successfully!")
    
    // Verify by reading back
    let readData = try Data(contentsOf: dataFileURL)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    let verified = try decoder.decode(TestWidgetData.self, from: readData)
    
    print("\n🔍 Verification:")
    print("   - Read back: \(verified.promises.count) promises")
    print("   - Completion rate: \(Int((Double(verified.promises.filter { $0.resolved }.count) / Double(verified.promises.count)) * 100))%")
    
    for (i, promise) in verified.promises.enumerated() {
        let status = promise.resolved ? "✅" : "⏳"
        print("   [\(i+1)] \(status) \(promise.content)")
    }
    
    // Post Darwin notification for cross-process communication
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("com.promisekeeper.widget.datachanged" as CFString),
        nil,
        nil,
        true
    )
    
    print("\n📢 Posted unified change notification")
    
    // Show file details
    let attributes = try FileManager.default.attributesOfItem(atPath: dataFileURL.path)
    if let fileSize = attributes[.size] as? Int64,
       let modDate = attributes[.modificationDate] as? Date {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .medium
        
        print("\n📊 File Details:")
        print("   - Size: \(fileSize) bytes")
        print("   - Modified: \(formatter.string(from: modDate))")
        print("   - Protection: Complete file protection")
    }
    
    print("\n✅ Unified widget system test complete!")
    print("   The widget should now display this realistic data.")
    print("   Check the widget to verify it's working correctly.")
    
} catch {
    print("\n❌ Error: \(error)")
    exit(1)
}