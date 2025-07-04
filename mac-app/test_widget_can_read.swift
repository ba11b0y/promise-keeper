#!/usr/bin/swift

import Foundation

print("🧪 TESTING WIDGET DATA ACCESS")
print("============================\n")

// Replicate the widget's data loading logic
class TestWidgetDataManager {
    private let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
    private let dataFileName = "widget_data.json"
    
    func load() -> Bool {
        print("1️⃣ Attempting to access App Group...")
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            print("❌ Cannot access App Group '\(appGroupID)'")
            return false
        }
        print("✅ App Group accessible")
        
        let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
        let dataFileURL = dataDirectory.appendingPathComponent(dataFileName)
        
        print("\n2️⃣ Looking for data file...")
        print("   Path: \(dataFileURL.path)")
        
        guard FileManager.default.fileExists(atPath: dataFileURL.path) else {
            print("❌ No data file found")
            return false
        }
        print("✅ Data file exists")
        
        print("\n3️⃣ Reading data...")
        do {
            let data = try Data(contentsOf: dataFileURL)
            print("✅ Read \(data.count) bytes")
            
            print("\n4️⃣ Decoding JSON...")
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("✅ JSON decoded successfully:")
                print("   - isAuthenticated: \(json["isAuthenticated"] ?? "?")")
                print("   - userEmail: \(json["userEmail"] ?? "?")")
                print("   - userId: \(String(describing: json["userId"] ?? "?").prefix(8))...")
                if let promises = json["promises"] as? [[String: Any]] {
                    print("   - promises: \(promises.count)")
                    if let first = promises.first {
                        print("   - first promise: \(first["content"] ?? "?")")
                    }
                }
                return true
            } else {
                print("❌ Failed to decode JSON")
                return false
            }
        } catch {
            print("❌ Error reading file: \(error)")
            return false
        }
    }
}

print("Running test as if we were the widget...\n")

let manager = TestWidgetDataManager()
let success = manager.load()

print("\n" + String(repeating: "=", count: 40))
if success {
    print("✅ WIDGET CAN READ DATA SUCCESSFULLY!")
    print("The widget should be able to display the data.")
    print("\nIf the widget still shows 0 promises:")
    print("1. The widget binary needs to be rebuilt")
    print("2. Remove and re-add the widget")
} else {
    print("❌ WIDGET CANNOT READ DATA")
    print("There's a problem with data access.")
}
print(String(repeating: "=", count: 40))