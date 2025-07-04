# Widget Logging Solution

## Problem
Widget `print()` and `NSLog()` statements were not appearing in Console.app, making debugging difficult.

## Root Cause
1. **Widget IS running**: Process `PromiseWidgetExtension` is active (PID 39964)
2. **Widget IS executing**: System logs show timeline requests and successful completion
3. **Issue**: Standard `print()` and `NSLog()` outputs from widget extensions don't appear in Console.app by default

## Solution
Created a comprehensive logging system with three output methods:

### 1. **WidgetLogger.swift** - Custom Logger
- Uses `os.log` with custom subsystem `"com.promise-keeper.widget"`
- Writes to file: `~/Library/Group Containers/group.TX645N2QBW.com.example.mac.SidebarApp/widget_debug.log`
- Stores recent logs in UserDefaults for quick access

### 2. **WidgetDebugView.swift** - Debug UI in Main App
- Real-time log viewer with auto-refresh
- Shows both file logs and UserDefaults logs
- Accessible via Cmd+Shift+Option+D or Help menu
- Shows widget running status

### 3. **Console.app Integration**
Filter logs with:
```bash
log show --predicate 'subsystem == "com.promise-keeper.widget"' --last 1h
```

## How to Use

### In Widget Code
Replace standard logging:
```swift
// OLD
print("Widget: Loading data")
NSLog("Widget: Loading data")

// NEW
widgetLog("Loading data")          // General log
widgetInfo("Loading data")         // Info level
widgetDebug("Loading data")        // Debug level
widgetError("Failed to load")      // Error level
```

### Viewing Logs

1. **In Main App**: Press Cmd+Shift+Option+D
2. **In Terminal**: `tail -f ~/Library/Group\ Containers/group.TX645N2QBW.com.example.mac.SidebarApp/widget_debug.log`
3. **In Console.app**: Use the filter command above

## Files Created
1. `/mac-app/PromiseWidget/WidgetLogger.swift` - Logger implementation
2. `/mac-app/SidebarApp/Views/WidgetDebugView.swift` - Debug UI (updated existing)
3. `/mac-app/debug_widget_logs.sh` - Diagnostic script
4. `/mac-app/setup_widget_logging.sh` - Setup instructions

## Next Steps
1. Add `WidgetLogger.swift` to the widget target in Xcode
2. Update widget code to use the new logging functions
3. Build and run
4. View logs using any of the methods above

## Important Notes
- Widget must be added to home screen to start logging
- Log file is shared via App Groups
- Logs persist across widget restarts
- Maximum 50 logs kept in UserDefaults to prevent bloat