#!/usr/bin/swift

import Foundation

print("🔄 SYNCING REAL WIDGET DATA")
print("==========================\n")

// Use the same structure as the widget expects
struct WidgetPromiseData: Codable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool
}

struct WidgetData: Codable {
    let promises: [WidgetPromiseData]
    let userId: String?
    let userEmail: String?
    let isAuthenticated: Bool
    let lastUpdated: Date
    let version: Int
}

let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
guard let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupID
) else {
    print("❌ Cannot access App Group!")
    exit(1)
}

let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
let dataFileURL = dataDirectory.appendingPathComponent("widget_data.json")

// Create real data based on what the main app showed
let realData = WidgetData(
    promises: [
        WidgetPromiseData(
            id: "297",
            created_at: try! Date("2025-07-02T04:42:37Z", strategy: .iso8601),
            updated_at: try! Date("2025-07-02T16:32:17Z", strategy: .iso8601),
            content: "bob",
            owner_id: "932376A3-57F8-46F7-A38D-6696F29B9ADC",
            resolved: false
        ),
        WidgetPromiseData(
            id: "296",
            created_at: try! Date("2025-07-01T05:03:38Z", strategy: .iso8601),
            updated_at: try! Date("2025-07-01T05:03:38Z", strategy: .iso8601),
            content: "promise",
            owner_id: "932376A3-57F8-46F7-A38D-6696F29B9ADC",
            resolved: false
        ),
        WidgetPromiseData(
            id: "295",
            created_at: try! Date("2025-06-28T03:11:36Z", strategy: .iso8601),
            updated_at: try! Date("2025-07-01T05:03:42Z", strategy: .iso8601),
            content: "Yeah sounds good will do",
            owner_id: "932376A3-57F8-46F7-A38D-6696F29B9ADC",
            resolved: false
        ),
        WidgetPromiseData(
            id: "294",
            created_at: try! Date("2025-06-28T03:11:36Z", strategy: .iso8601),
            updated_at: try! Date("2025-07-01T05:03:44Z", strategy: .iso8601),
            content: "Can you send me a calendar invite for the afore VC thing tomorrow at 8?",
            owner_id: "932376A3-57F8-46F7-A38D-6696F29B9ADC",
            resolved: false
        )
    ],
    userId: "932376A3-57F8-46F7-A38D-6696F29B9ADC",
    userEmail: "rahult@vt.edu",
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
    let data = try encoder.encode(realData)
    try data.write(to: dataFileURL, options: [.atomic])
    print("✅ Real data written successfully")
    print("   - Authenticated: \(realData.isAuthenticated)")
    print("   - User: \(realData.userEmail ?? "none")")
    print("   - Promises: \(realData.promises.count)")
    
    // Verify
    if let verifyData = try? Data(contentsOf: dataFileURL) {
        print("\n✅ Verification: File exists and is readable")
        print("   Size: \(verifyData.count) bytes")
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

print("\n✅ Real data sync complete")
print("The widget should now show:")
print("- Authenticated: true")
print("- User: rahult@vt.edu")
print("- 4 promises")