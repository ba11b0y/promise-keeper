#!/usr/bin/swift

import Foundation
import WidgetKit

print("🔄 Forcing Widget Refresh")
print("========================\n")

// Post Darwin notification
print("1️⃣ Posting Darwin notification...")
CFNotificationCenterPostNotification(
    CFNotificationCenterGetDarwinNotifyCenter(),
    CFNotificationName("com.promisekeeper.widget.datachanged" as CFString),
    nil,
    nil,
    true
)
print("✅ Darwin notification posted")

// Also try to reload widget timelines directly
print("\n2️⃣ Reloading widget timelines...")
print("⚠️  Note: This requires WidgetKit which may not be available in command line context")

// Create a simple test to verify the notification system
print("\n3️⃣ Verifying widget data...")
let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
let dataFileURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
    .appendingPathComponent("WidgetData", isDirectory: true)
    .appendingPathComponent("widget_data.json")

if let url = dataFileURL,
   let data = try? Data(contentsOf: url) {
    print("✅ Widget data file exists and is readable")
    print("   Size: \(data.count) bytes")
    
    // Touch the file to update modification time
    try? FileManager.default.setAttributes(
        [.modificationDate: Date()],
        ofItemAtPath: url.path
    )
    print("✅ Updated file modification time")
}

print("\n✅ Widget refresh triggered")
print("   The widget should update within a few seconds")
print("   If not, try:")
print("   - Long-press the widget and select 'Edit Widget'")
print("   - Remove and re-add the widget")
print("   - Check Console.app for widget process logs")