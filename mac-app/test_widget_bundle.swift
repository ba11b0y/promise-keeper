#!/usr/bin/swift

import Foundation
import WidgetKit

// Check if the widget bundle loads
print("Testing widget bundle loading...")

// Get the main app bundle
if let appPath = Bundle.main.bundleURL.path.components(separatedBy: "/").dropLast().joined(separator: "/").appending("/PromiseKeeper.app") as String? {
    let appBundle = Bundle(path: appPath)
    print("App bundle: \(appBundle?.bundleIdentifier ?? "not found")")
    
    // Check for widget extension
    let widgetPath = appPath + "/Contents/PlugIns/PromiseWidgetExtension.appex"
    if FileManager.default.fileExists(atPath: widgetPath) {
        print("✅ Widget extension found at: \(widgetPath)")
        
        if let widgetBundle = Bundle(path: widgetPath) {
            print("Widget bundle identifier: \(widgetBundle.bundleIdentifier ?? "unknown")")
            print("Widget principal class: \(widgetBundle.principalClass?.description ?? "none")")
            
            // Check Info.plist
            if let infoPlist = widgetBundle.infoDictionary {
                print("\nWidget Info.plist keys:")
                for (key, _) in infoPlist {
                    print("  - \(key)")
                }
            }
        }
    } else {
        print("❌ Widget extension NOT found at expected path")
        print("Checking build directory...")
        
        // Check in build directory
        let buildPath = "/Users/anaygupta/Library/Developer/Xcode/DerivedData/PromiseKeeper-awjygrunslsmyrccoallzphjwnbi/Build/Products/Debug"
        if let contents = try? FileManager.default.contentsOfDirectory(atPath: buildPath) {
            print("\nBuild directory contents:")
            for item in contents {
                print("  - \(item)")
            }
        }
    }
}

// Check widget timeline
print("\nChecking widget timeline reload...")
WidgetCenter.shared.reloadAllTimelines()
print("Widget timeline reload triggered")