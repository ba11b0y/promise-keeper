#!/bin/bash

echo "🔧 Rebuilding PromiseKeeper with all authentication fixes..."

cd "$(dirname "$0")"

# Clean all build artifacts
echo "Cleaning build artifacts..."
xcodebuild clean -project PromiseKeeper.xcodeproj -alltargets -configuration Debug
xcodebuild clean -project PromiseKeeper.xcodeproj -alltargets -configuration Release

# Remove DerivedData
echo "Removing DerivedData..."
rm -rf ~/Library/Developer/Xcode/DerivedData/PromiseKeeper-*

# Build the widget extension first
echo ""
echo "Building widget extension..."
xcodebuild build \
    -project PromiseKeeper.xcodeproj \
    -target PromiseWidgetExtension \
    -configuration Debug \
    DEVELOPMENT_TEAM=TX645N2QBW \
    CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY="Apple Development"

# Build the main app
echo ""
echo "Building main app..."
xcodebuild build \
    -project PromiseKeeper.xcodeproj \
    -scheme PromiseKeeper \
    -configuration Debug \
    DEVELOPMENT_TEAM=TX645N2QBW \
    CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY="Apple Development"

echo ""
echo "✅ Build complete!"
echo ""
echo "Next steps:"
echo "1. Open the app and sign out if you're currently signed in"
echo "2. Sign back in with your credentials"
echo "3. The widget should now work properly with authentication"
echo ""
echo "If the widget still doesn't work:"
echo "- Check Console.app for messages containing 'Rahul:' to see widget logs"
echo "- Look for JWT expiration or keychain access errors"
echo "- Ensure the app has been opened at least once after building"