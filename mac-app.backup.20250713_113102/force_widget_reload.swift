#!/usr/bin/swift

import Foundation
import WidgetKit

print("🔄 Forcing Widget Reload")
print("========================\n")

// Force reload all widgets
WidgetCenter.shared.reloadAllTimelines()
print("✅ Requested widget timeline reload")

// Post Darwin notification
let notificationName = "com.promisekeeper.widget.datachanged" as CFString
CFNotificationCenterPostNotification(
    CFNotificationCenterGetDarwinNotifyCenter(),
    CFNotificationName(notificationName),
    nil,
    nil,
    true
)
print("✅ Posted Darwin notification")

// Also try to trigger via UserDefaults change
if let defaults = UserDefaults(suiteName: "group.TX645N2QBW.com.example.mac.SidebarApp") {
    defaults.set(Date().timeIntervalSince1970, forKey: "widget_force_refresh")
    defaults.synchronize()
    print("✅ Updated UserDefaults timestamp")
}

print("\n🎯 Widget should reload now!")
print("Check your widget to see if it displays the promises.")