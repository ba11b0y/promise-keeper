#!/usr/bin/env swift

import Foundation

let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
let fileName = "widget_data.json"

print("🔍 Testing widget file read permissions...")

guard let containerURL = FileManager.default.containerURL(
    forSecurityApplicationGroupIdentifier: appGroupID
) else {
    print("❌ Cannot access App Group '\(appGroupID)'")
    exit(1)
}

let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
let dataFileURL = dataDirectory.appendingPathComponent(fileName)

print("📁 File path: \(dataFileURL.path)")

// Check if file exists
let fileExists = FileManager.default.fileExists(atPath: dataFileURL.path)
print("📄 File exists: \(fileExists)")

if !fileExists {
    print("❌ File does not exist")
    exit(1)
}

// Check file attributes
do {
    let attributes = try FileManager.default.attributesOfItem(atPath: dataFileURL.path)
    print("📊 File size: \(attributes[.size] ?? 0) bytes")
    if let perms = attributes[.posixPermissions] as? NSNumber {
        print("🔐 Permissions: \(String(perms.intValue, radix: 8))")
    }
    if let protection = attributes[.protectionKey] as? FileProtectionType {
        print("🛡️ Protection: \(protection.rawValue)")
    }
} catch {
    print("❌ Could not read file attributes: \(error)")
}

// Test different read methods
print("\n🧪 Testing read methods:")

// Method 1: Data(contentsOf:)
do {
    let data = try Data(contentsOf: dataFileURL)
    print("✅ Data(contentsOf:) succeeded: \(data.count) bytes")
} catch {
    print("❌ Data(contentsOf:) failed: \(error)")
}

// Method 2: FileManager.contents
if let data = FileManager.default.contents(atPath: dataFileURL.path) {
    print("✅ FileManager.contents succeeded: \(data.count) bytes")
} else {
    print("❌ FileManager.contents failed")
}

// Method 3: String(contentsOf:)
do {
    let string = try String(contentsOf: dataFileURL, encoding: .utf8)
    print("✅ String(contentsOf:) succeeded: \(string.count) characters")
} catch {
    print("❌ String(contentsOf:) failed: \(error)")
}

print("\n✅ Test complete")