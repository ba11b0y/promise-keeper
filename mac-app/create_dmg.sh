#!/bin/bash

echo "Creating DMG for PromiseKeeper..."

cd "$(dirname "$0")"

# Variables
APP_NAME="PromiseKeeper"
DMG_NAME="PromiseKeeper-1.0"
VOLUME_NAME="PromiseKeeper"
DMG_PATH="../${DMG_NAME}.dmg"
APP_PATH="build/Debug/${APP_NAME}.app"

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App not found at $APP_PATH"
    echo "Please build the app first using ./build_with_proper_signing.sh"
    exit 1
fi

# Create a temporary directory for DMG contents
TEMP_DIR=$(mktemp -d)
echo "Using temp directory: $TEMP_DIR"

# Copy app to temp directory
echo "Copying app..."
cp -R "$APP_PATH" "$TEMP_DIR/"

# Create Applications symlink
echo "Creating Applications symlink..."
ln -s /Applications "$TEMP_DIR/Applications"

# Create DMG
echo "Creating DMG..."
hdiutil create -volname "$VOLUME_NAME" \
    -srcfolder "$TEMP_DIR" \
    -ov \
    -format UDZO \
    "$DMG_PATH"

# Clean up
echo "Cleaning up..."
rm -rf "$TEMP_DIR"

# Sign the DMG
echo "Signing DMG..."
codesign --sign "Developer ID Application: TX645N2QBW" "$DMG_PATH" || echo "Warning: DMG signing failed (this is normal if you don't have a Developer ID certificate)"

echo ""
echo "DMG created successfully at: $DMG_PATH"
echo ""

# Verify DMG
echo "Verifying DMG..."
hdiutil verify "$DMG_PATH"

echo ""
echo "DMG Details:"
ls -lh "$DMG_PATH"