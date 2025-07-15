#!/usr/bin/swift

import Foundation

// Simulate the exact structures used in the app
struct MockPromise: Codable {
    let id: Int64?
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: UUID
    let resolved: Bool?
}

struct MockWidgetPromiseData: Codable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool
}

struct MockWidgetData: Codable {
    let promises: [MockWidgetPromiseData]
    let userId: String?
    let userEmail: String?
    let isAuthenticated: Bool
    let lastUpdated: Date
    let version: Int
}

print("🧪 Testing Exact PromiseManager.updateSharedData() Logic")
print("======================================================\n")

// 1. Create mock promises like the app would have
let mockPromises = [
    MockPromise(
        id: 1,
        created_at: Date(),
        updated_at: Date(),
        content: "Mock promise 1",
        owner_id: UUID(),
        resolved: false
    ),
    MockPromise(
        id: 2,
        created_at: Date().addingTimeInterval(-3600),
        updated_at: Date().addingTimeInterval(-3600),
        content: "Mock promise 2",
        owner_id: UUID(),
        resolved: true
    ),
    MockPromise(
        id: nil, // Test nil ID case
        created_at: Date().addingTimeInterval(-7200),
        updated_at: Date().addingTimeInterval(-7200),
        content: "Mock promise with nil ID",
        owner_id: UUID(),
        resolved: false
    )
]

// 2. Transform promises exactly like PromiseManager does
let transformedPromises = mockPromises.map { promise in
    MockWidgetPromiseData(
        id: String(promise.id ?? 0),
        created_at: promise.created_at,
        updated_at: promise.updated_at,
        content: promise.content,
        owner_id: promise.owner_id.uuidString,
        resolved: promise.resolved ?? false
    )
}

print("✅ Transformed \(transformedPromises.count) promises:")
for (i, promise) in transformedPromises.enumerated() {
    print("   [\(i)] ID: \(promise.id), Content: \(promise.content), Resolved: \(promise.resolved)")
}

// 3. Create widget data like UnifiedSharedDataManager.syncPromisesFromApp does
let widgetData = MockWidgetData(
    promises: transformedPromises,
    userId: "test-user-id",
    userEmail: "test@example.com",
    isAuthenticated: true,
    lastUpdated: Date(),
    version: 1
)

// 4. Try to save it like UnifiedSharedDataManager.save() does
let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
guard let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupID
) else {
    print("❌ Cannot access App Group!")
    exit(1)
}

let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
let dataFileURL = dataDirectory.appendingPathComponent("widget_data.json")

do {
    // Create directory if needed
    if !FileManager.default.fileExists(atPath: dataDirectory.path) {
        try FileManager.default.createDirectory(
            at: dataDirectory,
            withIntermediateDirectories: true,
            attributes: [.protectionKey: FileProtectionType.complete]
        )
    }
    
    // Encode and save
    let encoder = JSONEncoder()
    encoder.dateEncodingStrategy = .iso8601
    encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
    
    let encoded = try encoder.encode(widgetData)
    try encoded.write(to: dataFileURL, options: [.atomic, .completeFileProtection])
    
    print("\n✅ Successfully saved widget data to: \(dataFileURL.path)")
    print("📊 File size: \(encoded.count) bytes")
    
    // 5. Verify by reading back
    let readData = try Data(contentsOf: dataFileURL)
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    let readBack = try decoder.decode(MockWidgetData.self, from: readData)
    
    print("✅ Verification: Read back \(readBack.promises.count) promises")
    
} catch {
    print("❌ Failed to save widget data: \(error)")
    if let encodingError = error as? EncodingError {
        print("   Encoding error: \(encodingError)")
    }
}

print("\n🔍 Conclusion:")
print("If this test succeeds but the app doesn't sync, the issue is likely:")
print("1. PromiseManager.updateSharedData() is not being called")
print("2. The promises array is empty when updateSharedData() is called")
print("3. There's an error in the actual UnifiedSharedDataManager.save() method")
print("4. The transform closure is failing silently")