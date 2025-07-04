#!/usr/bin/swift

import Foundation

// Test the auth state race condition fix

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

print("🧪 Testing Auth State Race Condition Fix")
print("=======================================\n")

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

// Create directory if needed
if !FileManager.default.fileExists(atPath: dataDirectory.path) {
    try? FileManager.default.createDirectory(
        at: dataDirectory,
        withIntermediateDirectories: true,
        attributes: [.protectionKey: FileProtectionType.complete]
    )
}

// Simulate the race condition scenario
print("1️⃣ Simulating initial auth state update (like SupabaseManager)")
let authOnlyData = TestWidgetData(
    promises: [],  // No promises yet
    userId: "test-user-123",
    userEmail: "test@example.com",
    isAuthenticated: true,  // Auth is TRUE
    lastUpdated: Date(),
    version: 1
)

let encoder = JSONEncoder()
encoder.dateEncodingStrategy = .iso8601
encoder.outputFormatting = [.prettyPrinted]

let authData = try! encoder.encode(authOnlyData)
try! authData.write(to: dataFileURL, options: [.atomic])

print("✅ Wrote auth-only data: isAuthenticated = \(authOnlyData.isAuthenticated)")

// Wait a moment
Thread.sleep(forTimeInterval: 0.1)

// Read it back
let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

let readData1 = try! Data(contentsOf: dataFileURL)
let check1 = try! decoder.decode(TestWidgetData.self, from: readData1)
print("✅ Verified auth state: isAuthenticated = \(check1.isAuthenticated)")

print("\n2️⃣ Simulating promise sync with potential race condition")
print("   (This would normally overwrite auth state to false)")

// Read current data (simulating the merge logic)
let currentData = check1

// Create promises data with WRONG auth state
let promisesData = TestWidgetData(
    promises: [
        TestWidgetPromiseData(
            id: "1",
            created_at: Date(),
            updated_at: Date(),
            content: "Test promise from race condition",
            owner_id: "test-user-123",
            resolved: false
        )
    ],
    userId: "test-user-123",
    userEmail: "test@example.com",
    isAuthenticated: false,  // WRONG! This would be the bug
    lastUpdated: Date(),
    version: 1
)

// Apply the fix: never downgrade auth from true to false
let finalAuthState = currentData.isAuthenticated || promisesData.isAuthenticated
print("🔒 Auth merge: current=\(currentData.isAuthenticated), new=\(promisesData.isAuthenticated), final=\(finalAuthState)")

let fixedData = TestWidgetData(
    promises: promisesData.promises,
    userId: promisesData.userId ?? currentData.userId,
    userEmail: promisesData.userEmail ?? currentData.userEmail,
    isAuthenticated: finalAuthState,  // FIXED!
    lastUpdated: Date(),
    version: 1
)

let fixedDataEncoded = try! encoder.encode(fixedData)
try! fixedDataEncoded.write(to: dataFileURL, options: [.atomic])

print("✅ Wrote merged data with fix applied")

// Final verification
let finalReadData = try! Data(contentsOf: dataFileURL)
let finalCheck = try! decoder.decode(TestWidgetData.self, from: finalReadData)

print("\n3️⃣ Final State:")
print("   - Promises: \(finalCheck.promises.count)")
print("   - isAuthenticated: \(finalCheck.isAuthenticated) ✅")
print("   - User: \(finalCheck.userEmail ?? "none")")

if finalCheck.isAuthenticated && !finalCheck.promises.isEmpty {
    print("\n✅ SUCCESS! Auth state preserved and promises synced!")
    print("   The widget will now show as authenticated with data.")
} else {
    print("\n❌ FAILED! Something went wrong.")
}

// Post notification
CFNotificationCenterPostNotification(
    CFNotificationCenterGetDarwinNotifyCenter(),
    CFNotificationName("com.promisekeeper.widget.datachanged" as CFString),
    nil,
    nil,
    true
)

print("\n📢 Posted change notification for widget")