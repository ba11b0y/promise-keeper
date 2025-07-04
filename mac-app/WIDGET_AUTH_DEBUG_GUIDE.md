# Widget Authentication Debug Guide

## Issues Found

### 1. App Group Identifier Format
- Current format: `group.TX645N2QBW.com.example.mac.SidebarApp`
- This includes a team ID (TX645N2QBW) which is valid but unconventional
- Both main app and widget ARE using the same identifier ✅

### 2. Configuration Consistency
- Main app entitlement: ✅ Correct
- Widget entitlement: ✅ Correct
- Both use the same App Group ID ✅

### 3. Date Encoding/Decoding
- Both use `.iso8601` encoding strategy ✅
- No mismatch issues found ✅

### 4. Potential Issues Identified

#### A. UserDefaults Bool Storage
- `UserDefaults.bool(forKey:)` returns `false` if key doesn't exist
- This could cause the widget to show as unauthenticated if the key wasn't properly set

#### B. Timing Issues
- Widget might be checking auth state before it's written
- Small delay (0.1s) before widget reload might not be enough

#### C. Widget Process Isolation
- Widgets run in a separate process
- UserDefaults synchronization between processes can have delays

## Debug Steps Added

### 1. Enhanced Debug Logging
- Added comprehensive logging in both main app and widget
- Widget now logs to NSLog for Console.app visibility
- Debug function to print all stored values

### 2. Debug Manager (WidgetDebugManager.swift)
- Comprehensive diagnostics function
- Tests App Group access
- Verifies data storage and retrieval
- Shows authentication flow in detail

### 3. Debug View (WidgetDebugView.swift)
- Visual debug interface in main app
- Shows current authentication state
- Provides buttons to:
  - Run diagnostics
  - Force store auth state
  - Clear widget data
  - Reload widget timelines

## How to Debug

### 1. In Xcode
```swift
// Add to your main app's debug menu or settings
WidgetDebugView()
```

### 2. Check Console Logs
1. Open Console.app
2. Filter by "PromiseWidget" or your widget process name
3. Look for messages starting with "📱 Widget:"

### 3. Common Issues and Solutions

#### Issue: Widget shows unauthenticated but main app is signed in

**Solution 1: Force Store Auth State**
```swift
// In main app after successful sign in
if let user = supabaseManager.currentUser {
    SharedDataManager.shared.storeUserInfo(
        userId: user.id.uuidString,
        isAuthenticated: true
    )
    
    // Add extra delay before widget reload
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
        WidgetCenter.shared.reloadAllTimelines()
    }
}
```

**Solution 2: Check App Group Access**
```swift
// Run this in both main app and widget
if let defaults = UserDefaults(suiteName: "group.TX645N2QBW.com.example.mac.SidebarApp") {
    print("✅ App Group accessible")
    // Try writing and reading a test value
    defaults.set("test", forKey: "test_key")
    defaults.synchronize()
    print("Test value: \(defaults.string(forKey: "test_key") ?? "nil")")
} else {
    print("❌ App Group NOT accessible")
}
```

**Solution 3: Verify Entitlements**
1. Check that both targets have App Groups capability enabled
2. Verify the App Group ID matches exactly in both entitlements files
3. Clean build folder (Cmd+Shift+K) and rebuild

#### Issue: Widget never updates

**Solution: Check Widget Timeline Policy**
- Current policy: `.after(nextUpdate)` with 5-second intervals
- This is aggressive and might be throttled by the system
- Consider using `.atEnd` or longer intervals for production

## Code Changes Made

1. **Enhanced SharedDataManager.swift**
   - Better error handling
   - Explicit bool storage
   - Enhanced verification logging

2. **Updated PromiseWidget.swift**
   - Added debug logging
   - Print all UserDefaults keys for debugging
   - Better error messages

3. **Added Debug Tools**
   - WidgetDebugManager.swift
   - WidgetDebugView.swift
   - AppGroupConfig.swift (centralized configuration)

## Next Steps

1. **Test with Debug View**
   - Run the app
   - Open WidgetDebugView
   - Run comprehensive diagnostics
   - Check the output for any errors

2. **Monitor Console Logs**
   - Filter by your widget process
   - Look for authentication state changes
   - Check for any App Group access errors

3. **If Still Not Working**
   - Try changing App Group ID to simpler format: `group.com.example.mac.SidebarApp`
   - Update in all three places (both entitlements + code)
   - Clean, delete app, and rebuild

4. **Production Considerations**
   - Reduce widget update frequency
   - Add retry logic for failed auth checks
   - Consider caching auth state with expiration