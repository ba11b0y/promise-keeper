#!/bin/bash

echo "🔄 Force refreshing widget..."

# 1. Kill all widget-related processes
echo "1. Killing widget processes..."
killall "WidgetKit Simulator" 2>/dev/null || true
killall chronod 2>/dev/null || true
killall "Notification Center" 2>/dev/null || true

# 2. Remove the app completely
echo "2. Removing app from Applications..."
sudo rm -rf "/Applications/PromiseKeeper.app" 2>/dev/null || true

# 3. Clear widget cache
echo "3. Clearing widget cache..."
rm -rf ~/Library/Caches/com.example.mac.PromiseKeeper* 2>/dev/null || true
rm -rf ~/Library/Caches/com.apple.chronod* 2>/dev/null || true

# 4. Clear derived data (already done but just in case)
echo "4. Clearing derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData 2>/dev/null || true

# 5. Reset widget timeline
echo "5. Resetting widget timeline..."
# This forces widgets to reload their timelines
defaults delete com.apple.chronod 2>/dev/null || true

echo "✅ Widget refresh complete!"
echo ""
echo "Now:"
echo "1. Clean Build Folder in Xcode (⇧⌘K)"
echo "2. Build and Run your app"
echo "3. Manually remove any existing widgets from desktop"
echo "4. Re-add the widget from widget gallery"