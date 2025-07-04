#!/bin/bash

echo "========================================="
echo "Setting up Widget Logging"
echo "========================================="
echo ""

# 1. Update the widget to use the new logger
echo "To enable widget logging, update your PromiseWidget.swift file:"
echo ""
echo "1. Add import for WidgetLogger at the top of the file:"
echo "   import WidgetKit"
echo "   import SwiftUI"
echo "   // Add this line:"
echo "   import Foundation"
echo ""
echo "2. Replace print() and NSLog() calls with the new logger:"
echo ""
echo "   OLD:"
echo "   print(\"📱 Widget: getTimeline() called\")"
echo "   NSLog(\"📱 Widget: getTimeline() called\")"
echo ""
echo "   NEW:"
echo "   widgetLog(\"📱 Widget: getTimeline() called\")"
echo "   widgetInfo(\"📱 Widget: getTimeline() called\")"
echo "   widgetDebug(\"📱 Widget: getTimeline() called\")"
echo "   widgetError(\"📱 Widget: Error loading data\")"
echo ""

# 2. Show example implementation
echo "3. Example implementation in PromiseProvider:"
echo ""
cat << 'EOF'
struct PromiseProvider: TimelineProvider {
    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        widgetInfo("getTimeline() called")
        widgetDebug("Context: \(context)")
        
        Task {
            widgetDebug("Starting data fetch...")
            let entry = await fetchRealData()
            
            widgetInfo("Fetched \(entry.promises.count) promises")
            widgetDebug("Authenticated: \(entry.isAuthenticated)")
            
            let nextUpdate = Calendar.current.date(byAdding: .second, value: 5, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            
            widgetInfo("Timeline created, next update: \(nextUpdate)")
            completion(timeline)
        }
    }
    
    private func fetchRealData() async -> PromiseEntry {
        widgetDebug("fetchRealData() called")
        
        // Load data using the unified data manager
        let data = WidgetUnifiedDataManager.shared.load() ?? WidgetData()
        
        widgetInfo("Loaded data - promises: \(data.promises.count), auth: \(data.isAuthenticated)")
        
        if data.promises.isEmpty {
            widgetDebug("No promises found, returning empty entry")
        }
        
        // ... rest of implementation
    }
}
EOF

echo ""
echo "4. To view logs in Console.app, use this command:"
echo "   log show --predicate 'subsystem == \"com.promise-keeper.widget\"' --last 1h"
echo ""
echo "5. To view logs in the main app:"
echo "   - Open the app"
echo "   - Press Cmd+Shift+Option+D to open Widget Debug Logs window"
echo "   - Or use the menu: Help > Widget Debug Logs..."
echo ""
echo "6. The log file is located at:"
echo "   ~/Library/Group Containers/group.TX645N2QBW.com.example.mac.SidebarApp/widget_debug.log"
echo ""
echo "7. You can tail the log file in Terminal:"
echo "   tail -f ~/Library/Group\\ Containers/group.TX645N2QBW.com.example.mac.SidebarApp/widget_debug.log"
echo ""
echo "========================================="
echo "Done! Remember to add WidgetLogger.swift to your widget target in Xcode."
echo "========================================="