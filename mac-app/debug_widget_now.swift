#!/usr/bin/swift

import Foundation

print("🔍 WIDGET DEBUG - CURRENT STATE")
print("==============================\n")

// Check current widget data
let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
let dataFileURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
    .appendingPathComponent("WidgetData", isDirectory: true)
    .appendingPathComponent("widget_data.json")

if let data = try? Data(contentsOf: dataFileURL),
   let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
    print("📄 Widget Data File:")
    print("   - Authenticated: \(json["isAuthenticated"] ?? "?")")
    print("   - User: \(json["userEmail"] ?? "?")")
    print("   - Promises: \((json["promises"] as? [[String: Any]])?.count ?? 0) ⚠️")
    print("   - Last Updated: \(json["lastUpdated"] ?? "?")")
    
    if let promises = json["promises"] as? [[String: Any]], promises.isEmpty {
        print("\n⚠️  PROBLEM: Authenticated but NO PROMISES!")
        print("   This is why the widget shows 'Open App'")
    }
}

print("\n🔧 HOW TO DEBUG:")
print("1. Open Console.app")
print("2. Start streaming logs (top toolbar)")
print("3. Filter by: PromiseWidgetExtension")
print("4. Remove and re-add the widget")
print("5. Look for these logs:")
print("   - '📱 Widget: getTimeline() called'")
print("   - '🔄 WidgetUnifiedDataManager.load() called'")
print("   - '✅ Widget: Successfully loaded data'")
print("   - '📱 Widget View appeared'")

print("\n💡 TO FIX:")
print("1. In the main app, press Cmd+Shift+P to fetch promises")
print("2. Then press Cmd+Shift+S to sync to widget")
print("3. Check if promises appear in the JSON file")

print("\n📱 WIDGET PROCESS:")
let output = Process()
output.executableURL = URL(fileURLWithPath: "/bin/ps")
output.arguments = ["aux"]
let pipe = Pipe()
output.standardOutput = pipe
try? output.run()
output.waitUntilExit()

let processData = pipe.fileHandleForReading.readDataToEndOfFile()
if let string = String(data: processData, encoding: .utf8) {
    let widgetProcess = string.split(separator: "\n").first { $0.contains("PromiseWidgetExtension") }
    if let process = widgetProcess {
        print("✅ Widget process is running")
        let components = process.split(separator: " ", omittingEmptySubsequences: true)
        if components.count > 1 {
            print("   PID: \(components[1])")
        }
    } else {
        print("❌ Widget process not found")
    }
}