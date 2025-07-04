# 🧪 **Promise Keeper Swift App Testing Guide**

## **How to Test the Migrated Swift App vs Electron**

### **Prerequisites**
1. Ensure both Electron and Swift apps use the same backend:
   - Same Supabase database
   - Same BAML API endpoint: `https://promise-keeper-api-red-sunset-2072.fly.dev`
   - Same AppleScript MCP server in `/applescript-mcp/`

2. Grant necessary permissions:
   - **Screen Recording** (System Preferences → Privacy & Security → Screen Recording)
   - **Accessibility** (System Preferences → Privacy & Security → Accessibility)
   - **Notifications** (System Preferences → Notifications)

---

## **🚀 Step 1: Build & Run the Swift App**

### Option A: Using Xcode (Recommended)
```bash
cd /Users/anaygupta/Downloads/promise-keeper/mac-app
open SidebarApp.xcodeproj
```
1. Open in Xcode
2. Select "SidebarApp" target
3. Click "Run" (⌘+R)

### Option B: Command Line Build
```bash
cd /Users/anaygupta/Downloads/promise-keeper/mac-app
xcodebuild -project SidebarApp.xcodeproj -scheme SidebarApp -configuration Debug
```

### Fix Compilation Issues (if any):
If you encounter build errors, check these common issues:

1. **Missing Dependencies**:
   ```bash
   # Install WidgetKit and ScreenCaptureKit frameworks
   # These should be automatically available in Xcode 14+
   ```

2. **Import Issues**: Make sure all new files are added to the Xcode project:
   - `ScreenshotManager.swift`
   - `BAMLAPIClient.swift`
   - `AutoPromiseManager.swift`
   - `MCPClient.swift`
   - `CompactPromiseView.swift`
   - `ModernPromiseView.swift`
   - `PromiseWidgetExtension.swift`

3. **Target Membership**: Ensure all new Swift files are added to the SidebarApp target

---

## **🎯 Step 2: Functional Testing Checklist**

### **A. Core Screenshot Functionality**
Test against Electron app behavior:

#### **Test 1: Screenshot Modes**
- ✅ **Off Mode**: No automatic screenshots
- ✅ **30-Second Mode**: Screenshots every 30 seconds  
- ✅ **Enter Mode**: Screenshots on Enter key press (1-min cooldown)

**Expected Result**: Same behavior as Electron app

#### **Test 2: Manual Screenshot**
1. Click "📸 Take Screenshot Now" button
2. Verify screenshot is captured and processed
3. Check console for processing status

**Expected Result**: Identical to Electron app workflow

#### **Test 3: Global Enter Key Monitoring**
1. Set mode to "Enter" 
2. Press Enter key in any application
3. Verify screenshot is taken (max once per minute)

**Expected Result**: Same cooldown behavior as Electron

### **B. BAML Promise Extraction**
Compare with Electron app results:

#### **Test 4: Promise Detection**
1. Create a test screenshot with promises (e.g., Messages app with "I'll call you tomorrow")
2. Take screenshot via Swift app
3. Verify promises are extracted correctly
4. Compare with same screenshot in Electron app

**Expected Result**: Identical promise extraction

#### **Test 5: Promise Auto-Creation**
1. Verify extracted promises are saved to Supabase database
2. Check database for new promises with:
   - `extracted_from_screenshot: true`
   - `screenshot_id` metadata
   - Same content as Electron app would create

**Expected Result**: Same database entries as Electron

### **C. MCP Integration Testing**
Verify AppleScript MCP server integration:

#### **Test 6: Calendar Integration**
1. Create promise with calendar action (e.g., "Meet at 3pm tomorrow")
2. Verify calendar event is created via MCP
3. Check Calendar app for new event

**Expected Result**: Same calendar integration as Electron

#### **Test 7: App Launch Actions**
1. Create promise with app launch action (e.g., "Open Spotify")
2. Verify app launches via MCP
3. Compare with Electron app behavior

**Expected Result**: Same app launching as Electron

### **D. UI/UX Comparison**

#### **Test 8: Compact Widget Interface**
1. Verify main window is 320x480 (widget-like)
2. Check glass blur effects
3. Test expand/collapse functionality
4. Compare visual design with Electron

**Expected Result**: Modern widget-like UI (superior to Electron)

#### **Test 9: Menu Bar Integration**
1. Verify menu bar icon appears
2. Test right-click menu options:
   - Show Promise Keeper
   - Add Promise  
   - Take Screenshot Now
   - Quit
3. Compare with Electron system tray

**Expected Result**: Same menu functionality as Electron

### **E. Backend Compatibility**

#### **Test 10: Authentication**
1. Sign in with same credentials as Electron app
2. Verify user session persists
3. Test logout functionality

**Expected Result**: Same auth flow as Electron

#### **Test 11: Data Synchronization**
1. Create promise in Swift app
2. Verify it appears in Electron app (refresh)
3. Create promise in Electron app  
4. Verify it appears in Swift app

**Expected Result**: Perfect data sync between apps

---

## **📊 Step 3: Performance Testing**

### **Speed Comparison**
Time these operations in both apps:

1. **Screenshot Capture Time**:
   - Electron: ___ ms
   - Swift: ___ ms (should be faster)

2. **Promise Extraction Time**:
   - Electron: ___ ms  
   - Swift: ___ ms (should be similar)

3. **Memory Usage**:
   - Electron: ~___MB (Activity Monitor)
   - Swift: ~___MB (should be much lower)

4. **CPU Usage During Screenshots**:
   - Electron: ___%
   - Swift: ___% (should be lower)

---

## **🔧 Step 4: Troubleshooting**

### **Common Issues & Solutions**

#### **Issue: Swift app won't build**
```bash
# Clean build folder
cd /Users/anaygupta/Downloads/promise-keeper/mac-app
rm -rf DerivedData
xcodebuild clean
```

#### **Issue: Screen recording permission denied**
1. Go to System Preferences → Privacy & Security → Screen Recording
2. Add SidebarApp to allowed applications
3. Restart the app

#### **Issue: MCP server not connecting**
```bash
# Check if AppleScript MCP server is running
cd /Users/anaygupta/Downloads/promise-keeper/applescript-mcp
npm run dev
```

#### **Issue: BAML API not responding**
1. Check internet connection
2. Verify API endpoint: `https://promise-keeper-api-red-sunset-2072.fly.dev/health`
3. Check authentication token

#### **Issue: Supabase connection fails**
1. Verify environment variables in `EnvironmentConfig.swift`
2. Check Supabase project status
3. Verify API keys

---

## **✅ Success Criteria**

The Swift app migration is successful when:

1. **✅ Identical Functionality**: All Electron features work in Swift
2. **✅ Same Data**: Both apps create/read same database entries  
3. **✅ Better Performance**: Swift app uses less memory/CPU
4. **✅ Native Integration**: Superior macOS system integration
5. **✅ Widget UI**: Modern compact interface (320x480)
6. **✅ MCP Compatibility**: Same AppleScript server integration

---

## **🚨 Known Limitations**

During testing, note these differences:

1. **UI Design**: Swift app has modern glass effects (superior to Electron)
2. **Window Management**: Swift uses native macOS window system
3. **Performance**: Swift should be significantly faster
4. **Memory Usage**: Swift should use ~50-70% less memory
5. **Battery Life**: Swift should be more efficient

---

## **📝 Test Results Template**

Document your findings:

```
SWIFT APP TEST RESULTS
======================

Date: ___________
Tester: ___________

FUNCTIONALITY TESTS:
[ ] Screenshot modes work (Off/30s/Enter) 
[ ] Manual screenshots work
[ ] Global Enter key monitoring
[ ] BAML promise extraction
[ ] Promise auto-creation  
[ ] MCP calendar integration
[ ] MCP app launching
[ ] Authentication flow
[ ] Data synchronization

PERFORMANCE COMPARISON:
Electron Memory: _____ MB
Swift Memory: _____ MB (Improvement: ___%)

Electron CPU: _____%  
Swift CPU: ____% (Improvement: ___%)

UI/UX ASSESSMENT:
[ ] Compact 320x480 widget interface
[ ] Glass blur effects
[ ] Menu bar integration
[ ] Native macOS feel

OVERALL MIGRATION SUCCESS: ___/10

NOTES:
________________
________________
________________
```

This guide will help you thoroughly test that the Swift app provides **identical functionality** to the Electron version while delivering **superior performance**! 🚀