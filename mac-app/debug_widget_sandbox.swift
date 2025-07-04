#!/usr/bin/swift

import Foundation

print("🔍 WIDGET SANDBOX DEBUG")
print("======================\n")

// Check both possible App Group IDs
let appGroupIDs = [
    "group.TX645N2QBW.com.example.mac.SidebarApp",
    "group.com.example.mac.SidebarApp"
]

for groupID in appGroupIDs {
    print("Testing App Group: \(groupID)")
    
    if let containerURL = FileManager.default.containerURL(
        forSecurityApplicationGroupIdentifier: groupID
    ) {
        print("✅ Can access container: \(containerURL.path)")
        
        // Check WidgetData directory
        let widgetDataDir = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
        let dataFile = widgetDataDir.appendingPathComponent("widget_data.json")
        
        if FileManager.default.fileExists(atPath: dataFile.path) {
            print("✅ Data file exists at: \(dataFile.path)")
            
            if let data = try? Data(contentsOf: dataFile) {
                print("   Size: \(data.count) bytes")
                
                // Try to decode
                struct MinimalWidgetData: Decodable {
                    let isAuthenticated: Bool
                    let promises: [[String: Any]]?
                    
                    enum CodingKeys: String, CodingKey {
                        case isAuthenticated
                        case promises
                    }
                    
                    init(from decoder: Decoder) throws {
                        let container = try decoder.container(keyedBy: CodingKeys.self)
                        isAuthenticated = try container.decode(Bool.self, forKey: .isAuthenticated)
                        promises = nil // Skip decoding promises for now
                    }
                }
                
                if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                    print("   Authenticated: \(json["isAuthenticated"] ?? "unknown")")
                    print("   User: \(json["userEmail"] ?? "unknown")")
                    if let promisesArray = json["promises"] as? [[String: Any]] {
                        print("   Promises: \(promisesArray.count)")
                    }
                }
            } else {
                print("❌ Cannot read data file")
            }
        } else {
            print("❌ No data file at: \(dataFile.path)")
        }
        
        // Check UserDefaults
        if let defaults = UserDefaults(suiteName: groupID) {
            print("\n📱 UserDefaults for \(groupID):")
            let keys = ["widget_is_authenticated", "widget_promises", "widget_user_id"]
            for key in keys {
                if let value = defaults.object(forKey: key) {
                    print("   \(key): \(type(of: value))")
                }
            }
        }
        
    } else {
        print("❌ Cannot access App Group: \(groupID)")
    }
    
    print("")
}

// Check widget process
print("\n🔍 Widget Process Check:")
let output = Process()
output.executableURL = URL(fileURLWithPath: "/bin/ps")
output.arguments = ["aux"]

let pipe = Pipe()
output.standardOutput = pipe

do {
    try output.run()
    output.waitUntilExit()
    
    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if let string = String(data: data, encoding: .utf8) {
        let widgetProcesses = string.split(separator: "\n").filter { 
            $0.contains("PromiseWidgetExtension") 
        }
        
        if widgetProcesses.isEmpty {
            print("❌ Widget process not running")
        } else {
            print("✅ Widget process found:")
            for process in widgetProcesses {
                print("   \(process)")
            }
        }
    }
} catch {
    print("Error checking processes: \(error)")
}

print("\n✅ Debug complete")