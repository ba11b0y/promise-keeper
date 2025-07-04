#!/usr/bin/env swift

import Foundation

let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"

print("🔍 Checking App Group Permissions")
print("==================================\n")

// Get container URL
guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) else {
    print("❌ Cannot access App Group: \(appGroupID)")
    exit(1)
}

print("✅ App Group Container: \(containerURL.path)\n")

// Check container permissions
do {
    let containerAttrs = try FileManager.default.attributesOfItem(atPath: containerURL.path)
    print("📁 Container Attributes:")
    print("   Owner: \(containerAttrs[.ownerAccountName] ?? "unknown")")
    print("   Group: \(containerAttrs[.groupOwnerAccountName] ?? "unknown")")
    print("   Permissions: \(String(format: "%o", (containerAttrs[.posixPermissions] as? NSNumber)?.intValue ?? 0))")
    print("   Protection: \((containerAttrs[.protectionKey] as? FileProtectionType)?.rawValue ?? "none")")
} catch {
    print("❌ Could not read container attributes: \(error)")
}

// Check WidgetData directory
let widgetDataDir = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
print("\n📂 WidgetData Directory: \(widgetDataDir.path)")

if FileManager.default.fileExists(atPath: widgetDataDir.path) {
    do {
        let dirAttrs = try FileManager.default.attributesOfItem(atPath: widgetDataDir.path)
        print("✅ Directory exists")
        print("   Owner: \(dirAttrs[.ownerAccountName] ?? "unknown")")
        print("   Group: \(dirAttrs[.groupOwnerAccountName] ?? "unknown")")
        print("   Permissions: \(String(format: "%o", (dirAttrs[.posixPermissions] as? NSNumber)?.intValue ?? 0))")
        print("   Protection: \((dirAttrs[.protectionKey] as? FileProtectionType)?.rawValue ?? "none")")
    } catch {
        print("❌ Could not read directory attributes: \(error)")
    }
} else {
    print("❌ Directory does not exist")
}

// Check widget_data.json
let dataFile = widgetDataDir.appendingPathComponent("widget_data.json")
print("\n📄 widget_data.json: \(dataFile.path)")

if FileManager.default.fileExists(atPath: dataFile.path) {
    do {
        let fileAttrs = try FileManager.default.attributesOfItem(atPath: dataFile.path)
        print("✅ File exists")
        print("   Size: \(fileAttrs[.size] ?? 0) bytes")
        print("   Owner: \(fileAttrs[.ownerAccountName] ?? "unknown")")
        print("   Group: \(fileAttrs[.groupOwnerAccountName] ?? "unknown")")
        print("   Permissions: \(String(format: "%o", (fileAttrs[.posixPermissions] as? NSNumber)?.intValue ?? 0))")
        print("   Protection: \((fileAttrs[.protectionKey] as? FileProtectionType)?.rawValue ?? "none")")
        
        // Try to read
        print("\n🔍 Read Test:")
        if let data = FileManager.default.contents(atPath: dataFile.path) {
            print("✅ FileManager.contents() succeeded: \(data.count) bytes")
        } else {
            print("❌ FileManager.contents() returned nil")
        }
        
        do {
            let data = try Data(contentsOf: dataFile)
            print("✅ Data(contentsOf:) succeeded: \(data.count) bytes")
        } catch {
            print("❌ Data(contentsOf:) failed: \(error)")
        }
        
    } catch {
        print("❌ Could not read file attributes: \(error)")
    }
} else {
    print("❌ File does not exist")
}

// Get current process info
print("\n🔍 Process Info:")
print("   Process: \(ProcessInfo.processInfo.processName)")
print("   User: \(NSUserName())")
print("   UID: \(getuid())")
print("   Effective UID: \(geteuid())")
print("   GID: \(getgid())")
print("   Effective GID: \(getegid())")

// Check sandbox status
print("\n🔍 Sandbox Status:")
let isSandboxed = ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil
print("   Sandboxed: \(isSandboxed)")
if let sandboxContainer = ProcessInfo.processInfo.environment["HOME"] {
    print("   Container: \(sandboxContainer)")
}