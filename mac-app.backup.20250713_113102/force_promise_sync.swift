#!/usr/bin/swift

import Foundation

print("🔄 FORCING PROMISE SYNC TO WIDGET")
print("=================================\n")

// Widget data models
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

// Create promises based on what we saw before
let promises = [
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
]

// Read current data to preserve auth state
var currentAuth = true
var currentEmail = "rahult@vt.edu"
var currentUserId = "932376A3-57F8-46F7-A38D-6696F29B9ADC"

if FileManager.default.fileExists(atPath: dataFileURL.path),
   let data = try? Data(contentsOf: dataFileURL),
   let current = try? JSONDecoder().decode(WidgetData.self, from: data) {
    currentAuth = current.isAuthenticated
    currentEmail = current.userEmail ?? currentEmail
    currentUserId = current.userId ?? currentUserId
}

// Create widget data with promises
let widgetData = WidgetData(
    promises: promises,
    userId: currentUserId,
    userEmail: currentEmail,
    isAuthenticated: currentAuth,
    lastUpdated: Date(),
    version: 1
)

// Save
let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
encoder.outputFormatting = .prettyPrinted

do {
    let data = try encoder.encode(widgetData)
    try data.write(to: dataFileURL, options: [.atomic])
    print("✅ Widget data updated with \(promises.count) promises")
    print("   - Authenticated: \(widgetData.isAuthenticated)")
    print("   - User: \(widgetData.userEmail ?? "none")")
    print("   - Promises: \(widgetData.promises.count)")
    
    // Send notification
    CFNotificationCenterPostNotification(
        CFNotificationCenterGetDarwinNotifyCenter(),
        CFNotificationName("com.promisekeeper.widget.datachanged" as CFString),
        nil,
        nil,
        true
    )
    print("\n📢 Notification sent to widget")
    print("\n✅ Widget should now show promises!")
    
} catch {
    print("❌ Error: \(error)")
}

print("\nTo debug further:")
print("1. Check Console.app for 'PromiseWidgetExtension' logs")
print("2. Remove and re-add the widget")
print("3. In main app: Cmd+Shift+P to fetch, then Cmd+Shift+S to sync")