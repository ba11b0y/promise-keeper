# Unified Widget Sync Integration Guide

## Overview
This guide explains how to integrate the new unified data sync system that ensures reliable, atomic data synchronization between the main app and widget.

## Key Benefits
- **Single source of truth**: One data manager, one data model
- **Atomic operations**: No partial writes or race conditions
- **Change notifications**: Efficient cross-process communication
- **Type safety**: Shared models between app and widget
- **Thread safety**: Concurrent read/write protection

## Integration Steps

### 1. Add Shared Framework to Xcode Project

1. In Xcode, go to File → Add Package Dependencies
2. Click "Add Local..." and select the `PromiseKeeperShared` folder
3. Add the package to both app and widget targets

### 2. Update PromiseManager

Replace the existing `updateSharedData()` method with:

```swift
import PromiseKeeperShared

private func updateSharedData() {
    updateWidgetData() // Calls the new extension method
}
```

### 3. Update SupabaseManager

Replace widget sync calls with:

```swift
import PromiseKeeperShared

// On authentication state change
UnifiedDataManager.shared.updateAuthState(
    userId: user.id.uuidString,
    userEmail: user.email,
    isAuthenticated: true
)
```

### 4. Update Widget

Replace the existing widget with `UnifiedPromiseWidget`:

```swift
@main
struct PromiseWidgetBundle: WidgetBundle {
    var body: some Widget {
        UnifiedPromiseWidget()
    }
}
```

### 5. Remove Old Code

Delete these files/classes:
- `WidgetDataSyncManager.swift`
- `SharedDataManager.swift` (after migrating)
- Old `WidgetPromise` definitions
- Manual UserDefaults code

### 6. Update Info.plist (Optional)

Add App Group identifier to Info.plist for centralized configuration:

```xml
<key>AppGroupIdentifier</key>
<string>group.TX645N2QBW.com.example.mac.SidebarApp</string>
```

## Usage Examples

### Saving Data (Main App)

```swift
// In PromiseManager after fetching/updating promises
func updateWidgetData() {
    let widgetPromises = PromiseConverter.toWidgetPromises(from: promises)
    
    let widgetData = WidgetData(
        promises: widgetPromises,
        userId: currentUser?.id,
        userEmail: currentUser?.email,
        isAuthenticated: true
    )
    
    UnifiedDataManager.shared.save(widgetData)
}
```

### Loading Data (Widget)

```swift
// In widget provider
private func createEntry() -> UnifiedPromiseEntry {
    let data = UnifiedDataManager.shared.load() ?? WidgetData()
    return UnifiedPromiseEntry(date: Date(), data: data)
}
```

### Listening for Changes (Widget)

The widget automatically listens for change notifications:

```swift
// Handled internally by UnifiedDataManager
NotificationCenter.default.addObserver(
    forName: .widgetDataDidChange,
    object: nil,
    queue: .main
) { _ in
    // Widget reloads automatically
}
```

## Data Flow

1. **Main App Updates**:
   - User action → PromiseManager → `updateWidgetData()`
   - UnifiedDataManager saves atomically
   - Posts Darwin notification
   - Widget receives notification and reloads

2. **Widget Display**:
   - Widget provider calls `UnifiedDataManager.shared.load()`
   - Displays data or placeholder if nil
   - Refreshes on notification or timer

## Debugging

### Check Data File
```bash
# View the actual data file
cat ~/Library/Group\ Containers/group.TX645N2QBW.com.example.mac.SidebarApp/WidgetData/widget_data.json | jq
```

### Test Script
```bash
./test_unified_sync.swift
```

### Console Logs
Filter Console.app by "UnifiedDataManager" to see all operations.

## Migration Checklist

- [ ] Add PromiseKeeperShared package to project
- [ ] Import PromiseKeeperShared in app files
- [ ] Add Promise+Widget extension
- [ ] Update PromiseManager with new sync method
- [ ] Update SupabaseManager auth sync
- [ ] Replace widget with UnifiedPromiseWidget
- [ ] Test data sync in both directions
- [ ] Remove old sync code
- [ ] Verify widget updates in real-time