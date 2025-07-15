#!/bin/bash

echo "Fixing widget signing and provisioning..."

# Remove any cached provisioning profiles for the widget
rm -rf ~/Library/MobileDevice/Provisioning\ Profiles/*

# Remove derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/PromiseKeeper-*

# Delete the provisioning profile in Xcode's cache
rm -rf ~/Library/Developer/Xcode/DerivedData/ModuleCache.noindex
rm -rf ~/Library/Developer/Xcode/DerivedData/XCBuildData

# Reset the code signing settings
defaults delete com.apple.dt.Xcode DVTDeveloperAccountUseKeychainService
defaults delete com.apple.dt.Xcode IDEProvisioningTeamManagerLastSelectedTeamID

echo "Clearing widget extension caches..."
# Clear widget extension caches
rm -rf ~/Library/Caches/com.apple.widgetkit-simulator
rm -rf ~/Library/Caches/com.example.mac.PromiseKeeper.PromiseWidgetExtension

echo "Resetting widget service..."
# Kill any existing widget processes
killall WidgetKit-Simulator 2>/dev/null || true
killall chronod 2>/dev/null || true

echo "Done! Please rebuild the project in Xcode."
echo ""
echo "Important: When building in Xcode:"
echo "1. Make sure 'Automatically manage signing' is checked for both the app and widget targets"
echo "2. Select the same team (TX645N2QBW) for both targets"
echo "3. Build the widget extension first, then the main app"