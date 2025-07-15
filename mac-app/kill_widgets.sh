#!/bin/bash

echo "🔄 Killing all widget-related processes..."

# Kill widget processes
killall "WidgetKit Simulator" 2>/dev/null || true
killall chronod 2>/dev/null || true
killall "Notification Center" 2>/dev/null || true

# Kill specific widget extensions (common patterns)
killall "PromiseWidgetExtension" 2>/dev/null || true
killall "PromiseKeeper" 2>/dev/null || true

# Kill processes that might be holding onto widgets
pkill -f "WidgetExtension" 2>/dev/null || true
pkill -f "Widget" 2>/dev/null || true

# Force reload all widget timelines
echo "🔄 Forcing widget timeline reload..."
osascript -e 'tell application "System Events" to tell every process whose name contains "Widget" to quit' 2>/dev/null || true

echo "✅ Widget processes killed"
echo "Note: You may need to manually remove widgets from desktop and re-add them"