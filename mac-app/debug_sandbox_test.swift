#!/usr/bin/env swift

import Foundation

print("🔍 Widget Sandbox Debug Test")
print("============================")

let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"

// Test 1: App Group Access
print("\n1️⃣ Testing App Group Access:")
if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
    print("✅ App Group accessible at: \(containerURL.path)")
    
    // Check if we can list the container
    do {
        let contents = try FileManager.default.contentsOfDirectory(atPath: containerURL.path)
        print("✅ Container contents: \(contents)")
    } catch {
        print("❌ Cannot list container contents: \(error)")
    }
    
} else {
    print("❌ Cannot access App Group")
}

// Test 2: UserDefaults Access  
print("\n2️⃣ Testing UserDefaults Access:")
if let defaults = UserDefaults(suiteName: appGroupID) {
    print("✅ UserDefaults accessible")
    
    // Try to read/write a test value
    defaults.set("test_value", forKey: "test_key")
    defaults.synchronize()
    
    if let testValue = defaults.string(forKey: "test_key") {
        print("✅ UserDefaults read/write works: \(testValue)")
        defaults.removeObject(forKey: "test_key")
    } else {
        print("❌ UserDefaults read failed")
    }
} else {
    print("❌ Cannot access UserDefaults")
}

// Test 3: Process Info
print("\n3️⃣ Process Information:")
print("Process Name: \(ProcessInfo.processInfo.processName)")
print("Bundle ID: \(Bundle.main.bundleIdentifier ?? "unknown")")

// Test 4: Sandbox Status
print("\n4️⃣ Sandbox Status:")
let homeDir = NSHomeDirectory()
print("Home Directory: \(homeDir)")
if homeDir.contains("Containers") {
    print("✅ Running in sandbox")
} else {
    print("❌ Not running in sandbox")
}

print("\n✅ Debug test complete")