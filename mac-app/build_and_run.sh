#!/bin/bash

# Build and Run Script for PromiseKeeper
# Usage: ./build_and_run.sh

echo "🧹 Cleaning up running instances..."
pkill -f PromiseKeeper 2>/dev/null || true
pkill -f PromiseWidget 2>/dev/null || true
pkill -f Xcode 2>/dev/null || true

echo "🔨 Building PromiseKeeper..."
xcodebuild -project PromiseKeeper.xcodeproj -scheme PromiseKeeper -configuration Debug build

if [ $? -eq 0 ]; then
    echo "✅ Build successful!"
    
    # Find the built app
    APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData/PromiseKeeper-*/Build/Products/Debug -name "PromiseKeeper.app" -type d | head -n 1)
    
    if [ -n "$APP_PATH" ]; then
        echo "🚀 Launching PromiseKeeper..."
        open "$APP_PATH"
        echo "📱 PromiseKeeper is now running!"
    else
        echo "❌ Could not find built app"
        exit 1
    fi
else
    echo "❌ Build failed"
    exit 1
fi