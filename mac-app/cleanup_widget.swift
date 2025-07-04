#!/usr/bin/swift

import Foundation

print("🧹 WIDGET CLEANUP PLAN")
print("=====================\n")

print("PROBLEM IDENTIFIED:")
print("The widget has TWO data managers:")
print("1. WidgetUnifiedDataManager (NEW - reads JSON) ✅")
print("2. WidgetSharedDataManager (OLD - reads UserDefaults) ❌")
print("")
print("The old manager is looking for UserDefaults keys that don't exist!")
print("")
print("SOLUTION:")
print("1. Remove/comment out WidgetSharedDataManager class")
print("2. Ensure widget ONLY uses WidgetUnifiedDataManager")
print("3. Clean up any old UserDefaults references")
print("")
print("Let's check what the widget is actually trying to read...")

// Check UserDefaults
let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
if let defaults = UserDefaults(suiteName: appGroupID) {
    print("\n📱 UserDefaults contents:")
    let widgetKeys = ["widget_promises", "widget_is_authenticated", "widget_user_id", "widget_last_sync_time"]
    for key in widgetKeys {
        if let value = defaults.object(forKey: key) {
            print("   \(key): \(type(of: value))")
        } else {
            print("   \(key): NOT SET ❌")
        }
    }
}

// Check JSON file
let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)!
let dataFileURL = containerURL
    .appendingPathComponent("WidgetData", isDirectory: true)
    .appendingPathComponent("widget_data.json")

if let data = try? Data(contentsOf: dataFileURL) {
    print("\n📄 JSON file exists: ✅")
    print("   Size: \(data.count) bytes")
} else {
    print("\n📄 JSON file exists: ❌")
}

print("\n🎯 NEXT STEPS:")
print("1. Edit PromiseWidget.swift")
print("2. Remove or comment out the entire WidgetSharedDataManager class")
print("3. Remove any code that uses it")
print("4. Rebuild the widget")