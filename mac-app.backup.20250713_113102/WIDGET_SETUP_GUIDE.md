# Widget Authentication & Data Sync Setup Guide

## 🚨 IMPORTANT: App Group Configuration

The widget authentication issue is caused by improper App Group configuration. Follow these steps to fix it:

### 1. Update App Group Identifier

The current App Group identifier `group.com.example.mac.SidebarApp` is using example values. You need to update it to match your actual bundle identifier:

1. **Find your Team ID**: 
   - Open Xcode → Select your project → Signing & Capabilities
   - Note your Team ID (e.g., `ABC123DEF`)

2. **Update the App Group identifier** in these locations:
   - `SharedDataManager.swift`: Line 31
   - `PromiseWidget.swift`: Line 45 (WidgetSharedDataManager)
   - Both entitlements files

   Format: `group.<YOUR-TEAM-ID>.<YOUR-APP-BUNDLE-ID>`
   Example: `group.ABC123DEF.com.yourcompany.promisekeeper`

### 2. Configure App Groups in Xcode

#### For the Main App Target:
1. Select your main app target
2. Go to "Signing & Capabilities" tab
3. Click "+" → Add "App Groups" capability
4. Click the "+" under App Groups
5. Enter your App Group identifier (e.g., `group.ABC123DEF.com.yourcompany.promisekeeper`)
6. Make sure it's checked

#### For the Widget Extension Target:
1. Select your widget extension target
2. Go to "Signing & Capabilities" tab
3. Click "+" → Add "App Groups" capability
4. Select the SAME App Group identifier you created for the main app
5. Make sure it's checked

### 3. Verify Bundle Identifiers

Ensure your bundle identifiers follow Apple's requirements:
- Main App: `com.yourcompany.promisekeeper`
- Widget: `com.yourcompany.promisekeeper.PromiseWidget`

### 4. Clean Build Folder

After making these changes:
1. Product → Clean Build Folder (⇧⌘K)
2. Delete derived data: `~/Library/Developer/Xcode/DerivedData`
3. Restart Xcode

## 🔍 Debugging Widget Authentication

### Use the Widget Debug View

Add this to your main app's UI to debug widget issues:

```swift
// In your main view, add a debug button:
Button("Widget Debug") {
    showWidgetDebug = true
}
.sheet(isPresented: $showWidgetDebug) {
    WidgetDebugView()
}
```

### Check Console Logs

1. Open Console.app
2. Filter by your app's bundle identifier
3. Look for messages starting with:
   - `✅` (success)
   - `❌` (error)
   - `📱` (widget)
   - `🔄` (sync)

### Common Issues & Solutions

#### Issue: "App Group is NOT accessible"
**Solution**: Check that both targets have the same App Group identifier and it matches your team ID.

#### Issue: Widget shows "Not Authenticated" even when signed in
**Solution**: 
1. Ensure `SharedDataManager.storeUserInfo()` is called after sign in
2. Check that `WidgetCenter.shared.reloadAllTimelines()` is called
3. Verify App Group identifier matches in all locations

#### Issue: Widget doesn't update immediately
**Solution**: iOS limits widget updates. Force refresh by:
1. Long-press widget → Edit Widget → Done
2. Or use the debug view's "Force Widget Refresh" button

## 🏗️ Architecture Overview

### Data Flow:
1. User signs in → `SupabaseManager` updates auth state
2. `SupabaseManager` calls `SharedDataManager.storeUserInfo()`
3. Data is written to App Group UserDefaults
4. `WidgetCenter.shared.reloadAllTimelines()` triggers widget update
5. Widget reads from App Group UserDefaults via `WidgetSharedDataManager`

### Key Components:
- **SharedDataManager.swift**: Main app's interface for writing to App Group
- **WidgetSharedDataManager**: Widget's interface for reading from App Group
- **App Group UserDefaults**: Shared storage between app and widget

## 🧪 Testing Checklist

- [ ] App Group identifier updated to match your team ID
- [ ] Both targets have App Groups capability enabled
- [ ] Same App Group selected in both targets
- [ ] Bundle identifiers follow Apple's format
- [ ] Clean build performed after changes
- [ ] Widget Debug View shows "App Group accessible"
- [ ] Sign in triggers widget update
- [ ] Sign out clears widget authentication

## 📱 Production Considerations

1. **Privacy**: Don't store sensitive data in App Groups
2. **Size Limits**: UserDefaults has size limits (~1MB)
3. **Update Frequency**: iOS limits widget updates to preserve battery
4. **Error Handling**: Always check if App Group is accessible before reading/writing

## 🚀 Next Steps

1. Fix the App Group identifier (most important!)
2. Test with the Widget Debug View
3. Monitor console logs during sign in/out
4. Deploy and test on real devices