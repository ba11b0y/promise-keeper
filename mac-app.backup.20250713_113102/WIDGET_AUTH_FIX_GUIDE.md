# 🔐 Widget Authentication Fix - Complete Guide

## Overview
This guide implements the proper pattern for widget authentication using Keychain-based session sharing, as recommended by Apple and the Supabase community.

## Architecture
```
Main App (Supabase Auth) → Keychain → Widget (Read Session)
```

## Changes Made

### 1. **SharedSupabaseManager.swift** (NEW)
- Stores Supabase session in Keychain
- Provides shared client for widget use
- Handles session expiry checks

### 2. **Updated SupabaseManager.swift**
- Stores session in Keychain on sign in
- Clears session from Keychain on sign out
- Updates session on token refresh

### 3. **Updated PromiseWidget.swift**
- Uses SharedSupabaseManager to get authenticated client
- Makes direct Supabase queries (no more cached data dependency)
- Falls back to cached data if network fails

### 4. **Entitlements Files**
Both `SidebarApp.entitlements` and `PromiseWidget.entitlements` now include:
```xml
<key>com.apple.security.application-groups</key>
<array>
    <string>group.TX645N2QBW.com.example.mac.SidebarApp</string>
</array>
<key>keychain-access-groups</key>
<array>
    <string>$(AppIdentifierPrefix)com.example.mac.SidebarApp</string>
</array>
```

## 🚀 Setup in Xcode

### Step 1: Configure App Groups
1. Select your project in Xcode
2. Select the **SidebarApp** target
3. Go to **Signing & Capabilities**
4. Under **App Groups**:
   - Remove any old groups
   - Add: `group.TX645N2QBW.com.example.mac.SidebarApp`
   - Ensure it's checked ✓

5. Select the **PromiseWidgetExtension** target
6. Repeat steps 3-4 for the widget

### Step 2: Configure Keychain Sharing
1. Still in **Signing & Capabilities** for both targets
2. Add capability: **Keychain Sharing**
3. Add Keychain Group: `com.example.mac.SidebarApp`
4. Ensure both targets have the same Keychain Group

### Step 3: Clean Build
1. **Product → Clean Build Folder** (⇧⌘K)
2. Delete DerivedData: `rm -rf ~/Library/Developer/Xcode/DerivedData/*`
3. **Product → Build** (⌘B)

### Step 4: Test
1. Run the app
2. Sign in with your Supabase account
3. Check Console.app for success messages:
   - "✅ Supabase session stored in Keychain"
   - "📱 Widget: Fetched X promises from Supabase"
4. Add the widget to your desktop/notification center
5. Widget should show authenticated state and promises!

## 🔍 Debugging

### Check Keychain Access
```bash
# In Terminal, check if Keychain items exist
security find-generic-password -a "supabase_session" -s "TX645N2QBW.com.example.mac.SidebarApp"
```

### Console Logs
Filter Console.app by your app name and look for:
- Main App: "✅ Supabase session stored in Keychain"
- Widget: "✅ Widget: Fetched X promises from Supabase"

### Common Issues

1. **"No Supabase session found in Keychain"**
   - Ensure you're signed in to the main app
   - Check Keychain Sharing is enabled for both targets

2. **"Could not create Supabase client"**
   - Session might be expired
   - Sign out and sign in again

3. **Widget shows "Sign in to view promises"**
   - Remove widget and re-add it
   - Ensure Keychain Groups match exactly

## 🎯 Benefits of This Approach

1. **Security**: Session stored securely in Keychain
2. **Performance**: Widget can fetch fresh data directly
3. **Reliability**: Automatic token handling by main app
4. **Simplicity**: No complex data syncing logic
5. **Apple Compliance**: Follows Apple's recommended patterns

## 📝 Implementation Notes

- The widget never modifies the session, only reads it
- Token refresh is handled by the main app
- Widget timeline updates are triggered on auth state changes
- Fallback to cached data ensures widget works offline

## 🚨 Important Reminders

1. **Team ID**: The current setup uses `TX645N2QBW` - update if different
2. **Bundle ID**: Using `com.example.mac` - update if different
3. **Both targets** must have identical:
   - App Group ID
   - Keychain Access Group
   - Team ID

## Next Steps

After following this guide:
1. Test sign in/out flow
2. Verify widget updates automatically
3. Check widget works after app restart
4. Monitor for any Keychain access errors

The widget should now reliably access the main app's authentication state and fetch fresh data from Supabase! 🎉