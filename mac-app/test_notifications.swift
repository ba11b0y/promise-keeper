#!/usr/bin/env swift

import Foundation
import UserNotifications
import AppKit

// Test notification permissions and sending
class NotificationTester {
    static func test() async {
        print("🔍 Testing macOS Notification System")
        print("=====================================")
        
        // Check current permission status
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        
        print("\n📋 Current Status:")
        print("Authorization Status: \(describeAuthStatus(settings.authorizationStatus))")
        print("Alert Setting: \(describeAlertSetting(settings.alertSetting))")
        print("Sound Setting: \(describeSetting(settings.soundSetting))")
        print("Badge Setting: \(describeSetting(settings.badgeSetting))")
        
        // Request permission if needed
        if settings.authorizationStatus != .authorized {
            print("\n🔐 Requesting notification permission...")
            do {
                let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
                print("Permission granted: \(granted)")
            } catch {
                print("❌ Error requesting permission: \(error)")
            }
        }
        
        // Send test notification
        print("\n📬 Sending test notification...")
        await sendTestNotification()
        
        // Check System Preferences
        print("\n💡 Troubleshooting Tips:")
        print("1. Check System Settings > Notifications > PromiseKeeper")
        print("2. Make sure notifications are enabled for the app")
        print("3. Check if Do Not Disturb is enabled")
        print("4. Try running the app from Xcode to see console logs")
        
        // Keep the script running for a moment to allow notification to show
        try? await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
    }
    
    static func sendTestNotification() async {
        let content = UNMutableNotificationContent()
        content.title = "Promise Keeper Test"
        content.subtitle = "Testing Notifications"
        content.body = "If you see this, notifications are working! 🎉"
        content.sound = .default
        
        // Try immediate delivery (no trigger)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil // Immediate delivery
        )
        
        do {
            try await UNUserNotificationCenter.current().add(request)
            print("✅ Notification request added successfully")
            
            // Also try with a small delay
            let delayedContent = UNMutableNotificationContent()
            delayedContent.title = "Promise Keeper Delayed Test"
            delayedContent.body = "This should appear 2 seconds after the first one"
            delayedContent.sound = .default
            
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 2, repeats: false)
            let delayedRequest = UNNotificationRequest(
                identifier: UUID().uuidString,
                content: delayedContent,
                trigger: trigger
            )
            
            try await UNUserNotificationCenter.current().add(delayedRequest)
            print("✅ Delayed notification request added successfully")
            
        } catch {
            print("❌ Error sending notification: \(error)")
        }
    }
    
    static func describeAuthStatus(_ status: UNAuthorizationStatus) -> String {
        switch status {
        case .notDetermined: return "Not Determined ⚠️"
        case .denied: return "Denied ❌"
        case .authorized: return "Authorized ✅"
        case .provisional: return "Provisional 🔄"
        case .ephemeral: return "Ephemeral ⏱"
        @unknown default: return "Unknown"
        }
    }
    
    static func describeAlertSetting(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .notSupported: return "Not Supported"
        case .disabled: return "Disabled ❌"
        case .enabled: return "Enabled ✅"
        @unknown default: return "Unknown"
        }
    }
    
    static func describeSetting(_ setting: UNNotificationSetting) -> String {
        switch setting {
        case .notSupported: return "Not Supported"
        case .disabled: return "Disabled"
        case .enabled: return "Enabled"
        @unknown default: return "Unknown"
        }
    }
}

// Run the test
Task {
    await NotificationTester.test()
    exit(0)
}

// Keep RunLoop active
RunLoop.main.run()