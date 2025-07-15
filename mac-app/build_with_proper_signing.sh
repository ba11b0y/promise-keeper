#!/bin/bash

echo "Building PromiseKeeper with proper signing..."

cd "$(dirname "$0")"

# Clean first
echo "Cleaning build..."
xcodebuild clean -project PromiseKeeper.xcodeproj -scheme PromiseKeeper -configuration Debug

# Build the widget extension first
echo ""
echo "Building widget extension..."
xcodebuild build \
    -project PromiseKeeper.xcodeproj \
    -target PromiseWidgetExtension \
    -configuration Debug \
    DEVELOPMENT_TEAM=TX645N2QBW \
    CODE_SIGN_STYLE=Automatic \
    CODE_SIGN_IDENTITY="Apple Development" \
    PRODUCT_BUNDLE_IDENTIFIER=com.example.mac.PromiseKeeper.PromiseWidgetExtension

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
echo "Build complete. Verifying widget signature..."
./verify_widget_signature.sh