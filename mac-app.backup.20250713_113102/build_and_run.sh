#!/bin/bash

# Build and Run Script for SidebarApp
# Usage: ./build_and_run.sh

echo "🧹 Cleaning up running instances..."
pkill -f SidebarApp 2>/dev/null || true
pkill -f PromiseWidget 2>/dev/null || true
pkill -f Xcode 2>/dev/null || true

echo "🔨 Building SidebarApp..."
xcodebuild -project SidebarApp.xcodeproj -scheme SidebarApp -configuration Debug build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/SidebarApp-*/Build/Products/Debug -name "SidebarApp.app" -type d | head -n 1)
    
    if [ -n "$APP_PATH" ]; then
        echo "🚀 Launching SidebarApp..."
        open "$APP_PATH"
        echo "📱 SidebarApp is now running!"
    else
        echo "❌ Could not find built app"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi