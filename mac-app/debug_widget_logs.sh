#!/bin/bash

echo "========================================="
echo "Promise Keeper Widget Debug Report"
echo "Generated at: $(date)"
echo "========================================="
echo ""

# 1. Check if widget process is running
echo "1. CHECKING WIDGET PROCESSES:"
echo "-----------------------------"
widget_processes=$(ps aux | grep -i "PromiseWidgetExtension" | grep -v grep)
if [ -z "$widget_processes" ]; then
    echo "❌ No PromiseWidgetExtension process found"
    echo ""
    echo "Checking for any widget-related processes:"
    ps aux | grep -i "widget.*promise\|promise.*widget" | grep -v grep || echo "None found"
else
    echo "✅ Widget process found:"
    echo "$widget_processes"
fi
echo ""

# 2. Check if the widget is installed
echo "2. CHECKING WIDGET INSTALLATION:"
echo "--------------------------------"
echo "Looking for widget extension in DerivedData:"
find ~/Library/Developer/Xcode/DerivedData -name "PromiseWidgetExtension.appex" -type d 2>/dev/null | head -5
echo ""

# 3. Check system logs for widget-related entries
echo "3. CHECKING CONSOLE LOGS:"
echo "-------------------------"
echo "Recent widget-related logs (last 30 minutes):"
echo ""

# Try different log queries
echo "a) Searching for PromiseWidget logs:"
log show --predicate 'process == "PromiseWidgetExtension"' --last 30m 2>&1 | head -20

echo ""
echo "b) Searching for widget errors:"
log show --predicate 'eventMessage CONTAINS "widget" AND eventMessage CONTAINS[c] "promise"' --last 30m 2>&1 | head -20

echo ""
echo "c) Searching for WidgetKit logs:"
log show --predicate 'subsystem == "com.apple.WidgetKit"' --last 30m 2>&1 | grep -i promise | head -10

# 4. Check for crash reports
echo ""
echo "4. CHECKING CRASH REPORTS:"
echo "--------------------------"
crash_reports=$(find ~/Library/Logs/DiagnosticReports -name "*PromiseWidget*" -o -name "*SidebarApp*" -mtime -1 2>/dev/null)
if [ -z "$crash_reports" ]; then
    echo "✅ No recent crash reports found"
else
    echo "❌ Found crash reports:"
    echo "$crash_reports"
    echo ""
    echo "Most recent crash (first 50 lines):"
    head -50 "$(echo "$crash_reports" | head -1)"
fi
echo ""

# 5. Check widget visibility in system
echo "5. CHECKING WIDGET VISIBILITY:"
echo "------------------------------"
echo "Checking if widget appears in Widget Gallery..."
echo "(This requires manual verification)"
echo ""

# 6. Check App Group access
echo "6. CHECKING APP GROUP ACCESS:"
echo "-----------------------------"
app_group_path=~/Library/Group\ Containers/group.TX645N2QBW.com.example.mac.SidebarApp
if [ -d "$app_group_path" ]; then
    echo "✅ App Group container exists at: $app_group_path"
    echo "Contents:"
    ls -la "$app_group_path" | head -10
    
    # Check for widget data
    if [ -d "$app_group_path/WidgetData" ]; then
        echo ""
        echo "WidgetData directory contents:"
        ls -la "$app_group_path/WidgetData/"
    fi
else
    echo "❌ App Group container not found at expected path"
    echo "Searching for alternative locations:"
    find ~/Library/Group\ Containers -name "*SidebarApp*" -type d 2>/dev/null
fi
echo ""

# 7. Alternative logging methods
echo "7. ALTERNATIVE LOGGING METHODS:"
echo "-------------------------------"
echo "Since print() and NSLog() aren't working, consider these alternatives:"
echo ""
echo "a) Write logs to a file in the App Group container:"
echo "   - Create a log file in the shared container"
echo "   - Write timestamped entries"
echo "   - Read from main app"
echo ""
echo "b) Use os_log with a custom subsystem:"
echo "   import os.log"
echo "   let logger = Logger(subsystem: \"com.promise-keeper.widget\", category: \"general\")"
echo "   logger.info(\"Widget message\")"
echo ""
echo "c) Use UserDefaults to store debug info:"
echo "   - Write debug timestamps and states to shared UserDefaults"
echo "   - Check from main app"
echo ""

# 8. Check if widget is actually being loaded
echo "8. WIDGET LOADING CHECK:"
echo "------------------------"
echo "To verify if the widget is loading:"
echo "1. Add a file write in the widget's init() or getTimeline()"
echo "2. Check if the file gets created"
echo "3. This will confirm if the widget code is executing"
echo ""

# 9. Generate test file writing code
echo "9. TEST CODE FOR WIDGET DEBUGGING:"
echo "----------------------------------"
cat << 'EOF'
Add this to your widget's PromiseProvider.getTimeline():

let debugURL = FileManager.default
    .containerURL(forSecurityApplicationGroupIdentifier: "group.TX645N2QBW.com.example.mac.SidebarApp")?
    .appendingPathComponent("widget_debug.log")

if let debugURL = debugURL {
    let timestamp = ISO8601DateFormatter().string(from: Date())
    let message = "[\(timestamp)] Widget getTimeline() called\n"
    
    if let data = message.data(using: .utf8) {
        if FileManager.default.fileExists(atPath: debugURL.path) {
            if let handle = try? FileHandle(forWritingTo: debugURL) {
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            }
        } else {
            try? data.write(to: debugURL)
        }
    }
}
EOF

echo ""
echo "========================================="
echo "End of Widget Debug Report"
echo "========================================="