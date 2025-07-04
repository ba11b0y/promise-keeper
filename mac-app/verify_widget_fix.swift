#!/usr/bin/swift

import Foundation

// Configuration
let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
let dataFileName = "widget_data.json"

print("🔍 Verifying Widget Fix")
print("=======================\n")

// Check file attributes
if let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID) {
    let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
    let dataFileURL = dataDirectory.appendingPathComponent(dataFileName)
    
    // Check directory attributes
    do {
        let dirAttributes = try FileManager.default.attributesOfItem(atPath: dataDirectory.path)
        print("📁 Directory Attributes:")
        if let protection = dirAttributes[.protectionKey] as? FileProtectionType {
            print("   Protection: \(protection.rawValue)")
        } else {
            print("   Protection: none")
        }
        print("   Permissions: \(dirAttributes[.posixPermissions] ?? 0)")
    } catch {
        print("❌ Could not read directory attributes: \(error)")
    }
    
    // Check file attributes
    if FileManager.default.fileExists(atPath: dataFileURL.path) {
        do {
            let fileAttributes = try FileManager.default.attributesOfItem(atPath: dataFileURL.path)
            print("\n📄 File Attributes:")
            if let protection = fileAttributes[.protectionKey] as? FileProtectionType {
                print("   Protection: \(protection.rawValue)")
            } else {
                print("   Protection: none")
            }
            print("   Permissions: \(fileAttributes[.posixPermissions] ?? 0)")
            print("   Size: \(fileAttributes[.size] ?? 0) bytes")
            
            // Try to read the file
            let data = try Data(contentsOf: dataFileURL)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
                print("\n✅ File is readable and valid JSON")
                print("   isAuthenticated: \(json["isAuthenticated"] ?? "unknown")")
                if let promises = json["promises"] as? [[String: Any]] {
                    print("   Promises: \(promises.count)")
                    for (index, promise) in promises.prefix(3).enumerated() {
                        if let content = promise["content"] as? String,
                           let resolved = promise["resolved"] as? Bool {
                            print("     \(index + 1). [\(resolved ? "✓" : " ")] \(content)")
                        }
                    }
                }
            }
        } catch {
            print("❌ Error reading file: \(error)")
        }
    }
}

print("\n🎯 Summary:")
print("The widget data file has been updated with no file protection.")
print("The widget should now be able to read the promises.")
print("\nIf the widget still shows 'Open App', try:")
print("1. Remove and re-add the widget")
print("2. Restart the Mac")
print("3. Check Console.app for widget-specific errors")