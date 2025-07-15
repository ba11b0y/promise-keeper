#!/usr/bin/swift

import Foundation

// Debug script to check what the widget is actually seeing

print("🔍 WIDGET VIEW DEBUG")
print("===================\n")

// Check the actual widget data file
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

// Just print raw contents, no need to decode

print("1️⃣ RAW FILE CONTENTS")
print("--------------------")

if let data = try? Data(contentsOf: dataFileURL),
   let jsonString = String(data: data, encoding: .utf8) {
    print(jsonString)
} else {
    print("❌ Cannot read file")
}

print("\n2️⃣ CHECKING WIDGET LOGS")
print("-----------------------")
print("To see widget logs:")
print("1. Open Console.app")
print("2. Search for: 'Widget: fetchRealData'")
print("3. Or search for process: 'PromiseWidgetExtension'")
print("")
print("Expected logs if widget is running:")
print("- 📱 Widget: fetchRealData() called - WIDGET IS RUNNING!")
print("- 📱 Widget: Loaded unified data - X promises, authenticated: true/false")

print("\n3️⃣ WIDGET REFRESH TIPS")
print("----------------------")
print("If the widget is stuck:")
print("1. Remove the widget completely (long press → Remove Widget)")
print("2. Re-add the widget from the widget gallery")
print("3. Or restart the Mac (widgets run in a separate process)")
print("")
print("The widget might be cached and not calling fetchRealData()")

print("\n4️⃣ CHECKING TIMELINE REFRESH")
print("---------------------------")
// Touch the file to force modification
if FileManager.default.fileExists(atPath: dataFileURL.path) {
    let attributes = [FileAttributeKey.modificationDate: Date()]
    try? FileManager.default.setAttributes(attributes, ofItemAtPath: dataFileURL.path)
    print("✅ Updated file modification time to force refresh")
    
    // Post multiple notifications
    for _ in 0..<3 {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.promisekeeper.widget.datachanged" as CFString),
            nil,
            nil,
            true
        )
        Thread.sleep(forTimeInterval: 0.1)
    }
    print("✅ Posted 3 Darwin notifications")
}

print("\n✅ Debug complete")
print("Check Console.app for widget logs to see if it's actually running fetchRealData()")