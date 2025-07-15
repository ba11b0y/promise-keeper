#!/bin/bash

# Build script for Promise Keeper 0.2.1 Release
set -e

# Configuration
PROJECT_NAME="PromiseKeeper"
SCHEME_NAME="PromiseKeeper"
WORKSPACE_PATH="mac-app/PromiseKeeper.xcodeproj"
APP_NAME="Promise Keeper"
BUNDLE_ID="com.example.mac.PromiseKeeper"
BUILD_DIR="./build"
EXPORT_DIR="./export"
DMG_DIR="./dmg"
RELEASES_DIR="./releases"

VERSION="0.2.1"
BUILD_NUMBER="3"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log "Starting build process for version $VERSION (build $BUILD_NUMBER)"

# Create directories
log "Creating build directories..."
mkdir -p "$BUILD_DIR" "$EXPORT_DIR" "$DMG_DIR" "$RELEASES_DIR"

# Update version in project
log "Updating version numbers in project..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "mac-app/PromiseKeeper/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "mac-app/PromiseKeeper/Info.plist"

# Clean previous builds
log "Cleaning previous builds..."
rm -rf "$BUILD_DIR"/* "$EXPORT_DIR"/* "$DMG_DIR"/*

# Build and archive with automatic signing
log "Building and archiving project..."
xcodebuild -project "$WORKSPACE_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive" \
    archive \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    CODE_SIGNING_ALLOWED=YES \
    CODE_SIGNING_REQUIRED=YES \
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="TX645N2QBW" \
    -allowProvisioningUpdates \
    | tee "$BUILD_DIR/build.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    error "Build failed. Check $BUILD_DIR/build.log for details."
    exit 1
fi

success "Archive created successfully!"

# Create export options plist for Developer ID distribution
log "Creating export options..."
cat > "$BUILD_DIR/ExportOptions.plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>developer-id</string>
    <key>teamID</key>
    <string>TX645N2QBW</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>provisioningProfiles</key>
    <dict/>
</dict>
</plist>
EOF

# Export archive
log "Exporting archive..."
xcodebuild -exportArchive \
    -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
    -allowProvisioningUpdates \
    | tee "$BUILD_DIR/export.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    error "Export failed. Check $BUILD_DIR/export.log for details."
    exit 1
fi

success "Export completed successfully!"

# Create DMG
log "Creating DMG..."
DMG_NAME="PromiseKeeper-$VERSION.dmg"
OUTPUT_DMG="$RELEASES_DIR/$DMG_NAME"

# Clean up any existing DMG
rm -f "$OUTPUT_DMG"

# Create DMG using create-dmg
create-dmg \
    --volname "$APP_NAME $VERSION" \
    --background "$DMG_DIR/background.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$APP_NAME.app" 175 190 \
    --hide-extension "$APP_NAME.app" \
    --app-drop-link 425 190 \
    --no-internet-enable \
    "$OUTPUT_DMG" \
    "$EXPORT_DIR/$APP_NAME.app"

if [ $? -eq 0 ]; then
    success "DMG created successfully: $OUTPUT_DMG"
    log "DMG size: $(du -h "$OUTPUT_DMG" | cut -f1)"
else
    error "Failed to create DMG"
    exit 1
fi

success "Build complete! Version $VERSION (build $BUILD_NUMBER)"
log "Output: $OUTPUT_DMG"