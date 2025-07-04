#!/usr/bin/swift

import Foundation

// Test data structures matching the app
struct TestPromise: Codable {
    let id: Int64?
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: UUID
    let resolved: Bool?
}

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
    
    init(promises: [TestWidgetPromiseData] = [],
         userId: String? = nil,
         userEmail: String? = nil,
         isAuthenticated: Bool = false,
         lastUpdated: Date = Date(),
         version: Int = 1) {
        self.promises = promises
        self.userId = userId
        self.userEmail = userEmail
        self.isAuthenticated = isAuthenticated
        self.lastUpdated = lastUpdated
        self.version = version
    }
}

print("🔍 Testing Promise Data Transformation")
print("=====================================\n")

// 1. Read the old data from UserDefaults
let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
guard let defaults = UserDefaults(suiteName: appGroupID) else {
    print("❌ Cannot access App Group!")
    exit(1)
}

// 2. Extract old promise data
guard let oldData = defaults.data(forKey: "widget_promises") else {
    print("❌ No old promise data found!")
    exit(1)
}

let decoder = JSONDecoder()
decoder.dateDecodingStrategy = .iso8601

// Try to decode as widget promises (old format)
struct OldWidgetPromise: Codable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool?
}

do {
    let oldPromises = try decoder.decode([OldWidgetPromise].self, from: oldData)
    print("✅ Found \(oldPromises.count) old promises")
    
    // Transform to new format
    let newPromises = oldPromises.map { oldPromise in
        TestWidgetPromiseData(
            id: oldPromise.id,
            created_at: oldPromise.created_at,
            updated_at: oldPromise.updated_at,
            content: oldPromise.content,
            owner_id: oldPromise.owner_id,
            resolved: oldPromise.resolved ?? false
        )
    }
    
    // Create new widget data
    let newWidgetData = TestWidgetData(
        promises: newPromises,
        userId: defaults.string(forKey: "widget_user_id"),
        userEmail: "test@example.com",
        isAuthenticated: true,
        lastUpdated: Date(),
        version: 1
    )
    
    // 3. Try to write to the new location
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    guard let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: appGroupID
    ) else {
        print("❌ Cannot access container URL!")
        exit(1)
    }
    
    let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
    let dataFileURL = dataDirectory.appendingPathComponent("widget_data.json")
    
    // Create directory if needed
    if !FileManager.default.fileExists(atPath: dataDirectory.path) {
        try FileManager.default.createDirectory(
            at: dataDirectory,
            withIntermediateDirectories: true,
            attributes: nil
        )
    }
    
    let encodedData = try encoder.encode(newWidgetData)
    try encodedData.write(to: dataFileURL, options: [.atomic])
    
    print("✅ Successfully wrote \(newPromises.count) promises to unified data file")
    print("📁 File location: \(dataFileURL.path)")
    print("📊 Data size: \(encodedData.count) bytes")
    
    // 4. Verify by reading back
    let readBackData = try Data(contentsOf: dataFileURL)
    let readBackWidgetData = try decoder.decode(TestWidgetData.self, from: readBackData)
    
    print("✅ Verification: Read back \(readBackWidgetData.promises.count) promises")
    for (i, promise) in readBackWidgetData.promises.enumerated() {
        print("   [\(i)] \(promise.content) - resolved: \(promise.resolved)")
    }
    
} catch {
    print("❌ Error: \(error)")
    if let decodingError = error as? DecodingError {
        print("   Decoding error details: \(decodingError)")
    }
}

print("\n🔧 Solution:")
print("The issue is likely that PromiseManager.updateSharedData() is failing silently.")
print("Check Console.app for UnifiedSharedDataManager errors when promises are fetched.")