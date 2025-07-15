# Widget Sync Refactoring Plan

## Current Issues
1. **Duplicate Managers**: SharedDataManager and WidgetDataSyncManager both write to App Group
2. **Incompatible Models**: Two different WidgetPromise structs with different properties
3. **Write-only Workflow**: No real synchronization, just "dump and hope"
4. **No Change Notifications**: Blind reloading of widget timelines
5. **Hardcoded Strings**: App Group ID repeated in multiple files
6. **Race Conditions**: Non-atomic writes can leave inconsistent state

## Solution Architecture

### 1. Single Shared Framework
Create a new framework/package `PromiseKeeperShared` that contains:
- Unified data models (WidgetPromise)
- Single SharedDataManager
- App Group configuration
- Atomic read/write operations

### 2. Unified Data Model
```swift
// In PromiseKeeperShared
struct WidgetPromise: Codable, Identifiable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool
    
    // Computed properties for compatibility
    var isResolved: Bool { resolved }
    var createdAt: Date { created_at }
}

struct WidgetData: Codable {
    let promises: [WidgetPromise]
    let userId: String?
    let isAuthenticated: Bool
    let lastUpdated: Date
    let version: Int = 1  // For future migrations
}
```

### 3. Atomic SharedDataManager
```swift
// In PromiseKeeperShared
public final class SharedDataManager {
    public static let shared = SharedDataManager()
    
    private let appGroupID: String
    private let queue = DispatchQueue(label: "com.promisekeeper.shareddata", attributes: .concurrent)
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()
    
    private init() {
        // Read from Info.plist or use default
        self.appGroupID = Bundle.main.object(forInfoDictionaryKey: "AppGroupIdentifier") as? String 
            ?? "group.TX645N2QBW.com.example.mac.SidebarApp"
            
        encoder.dateEncodingStrategy = .iso8601
        decoder.dateDecodingStrategy = .iso8601
    }
    
    // Atomic write
    public func save(_ data: WidgetData) {
        queue.async(flags: .barrier) {
            guard let url = self.dataFileURL else { return }
            
            do {
                let encoded = try self.encoder.encode(data)
                try encoded.write(to: url, options: .atomic)
                
                // Post notification for widget
                self.postChangeNotification()
            } catch {
                print("Failed to save widget data: \(error)")
            }
        }
    }
    
    // Atomic read
    public func load() -> WidgetData? {
        queue.sync {
            guard let url = self.dataFileURL,
                  let data = try? Data(contentsOf: url) else { return nil }
            
            return try? self.decoder.decode(WidgetData.self, from: data)
        }
    }
    
    private var dataFileURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("widget_data.json")
    }
    
    private func postChangeNotification() {
        // Use Darwin notification for cross-process communication
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.promisekeeper.widget.datachanged" as CFString),
            nil, nil, true
        )
        
        // Also reload widget timelines (but throttled)
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

### 4. Implementation Steps

1. **Create Shared Framework**
   - New target: PromiseKeeperShared (Framework)
   - Add to both app and widget targets

2. **Move Models**
   - Move WidgetPromise to shared framework
   - Create WidgetData wrapper for atomic operations

3. **Implement SharedDataManager**
   - Single source of truth
   - Atomic file operations
   - Change notifications

4. **Update App Code**
   - Remove duplicate managers
   - Use shared framework

5. **Update Widget Code**
   - Import shared framework
   - Listen for change notifications
   - Use unified model

### 5. Usage Example

```swift
// In main app
let widgetData = WidgetData(
    promises: promises.map { /* convert to WidgetPromise */ },
    userId: currentUser?.id,
    isAuthenticated: true,
    lastUpdated: Date()
)
SharedDataManager.shared.save(widgetData)

// In widget
if let data = SharedDataManager.shared.load() {
    // Use data.promises, data.isAuthenticated, etc.
}
```

## Benefits
- Single source of truth
- Atomic operations (no partial writes)
- Proper change notifications
- No duplicate code
- Type-safe shared models
- Easy to test and maintain