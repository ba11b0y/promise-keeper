import Foundation

// Test access to the app group container
let groupID = "group.TX645N2QBW.com.example.mac.SidebarApp"

print("Testing App Group Access")
print("========================")
print("Group ID: \(groupID)")

// Get container URL
guard let containerURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: groupID) else {
    print("ERROR: Cannot access container URL for group ID")
    exit(1)
}

print("Container URL: \(containerURL.path)")

// Build file path
let fileURL = containerURL
    .appendingPathComponent("WidgetData", isDirectory: true)
    .appendingPathComponent("widget_data.json")

print("\nFile Information")
print("================")
print("File path: \(fileURL.path)")

// Check file existence
let exists = FileManager.default.fileExists(atPath: fileURL.path)
print("File exists: \(exists)")

// Check if readable
let readable = FileManager.default.isReadableFile(atPath: fileURL.path)
print("File readable: \(readable)")

// Try to read the file
print("\nReading Attempt")
print("===============")
do {
    let data = try Data(contentsOf: fileURL)
    print("SUCCESS: Read \(data.count) bytes")
    
    // Try to decode JSON
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    
    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] {
        print("Valid JSON with keys: \(json.keys.sorted().joined(separator: ", "))")
    }
} catch {
    print("ERROR: \(error)")
    print("Error type: \(type(of: error))")
    
    if let nsError = error as NSError? {
        print("Error domain: \(nsError.domain)")
        print("Error code: \(nsError.code)")
        print("Error description: \(nsError.localizedDescription)")
    }
}

// Check file attributes
if exists {
    print("\nFile Attributes")
    print("===============")
    do {
        let attrs = try FileManager.default.attributesOfItem(atPath: fileURL.path)
        
        if let owner = attrs[FileAttributeKey.ownerAccountName] as? String {
            print("Owner: \(owner)")
        }
        if let perms = attrs[FileAttributeKey.posixPermissions] as? NSNumber {
            print("Permissions: \(String(format: "%o", perms.intValue))")
        }
        if let protection = attrs[FileAttributeKey.protectionKey] as? FileProtectionType {
            print("Protection: \(protection.rawValue)")
        }
    } catch {
        print("ERROR getting attributes: \(error)")
    }
}

// Check if we're sandboxed
print("\nEnvironment")
print("============")
print("Process: \(ProcessInfo.processInfo.processName)")
if let bundleID = Bundle.main.bundleIdentifier {
    print("Bundle ID: \(bundleID)")
}
print("Sandboxed: \(ProcessInfo.processInfo.environment["APP_SANDBOX_CONTAINER_ID"] != nil)")