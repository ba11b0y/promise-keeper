#!/bin/bash

# Build and Export Script for Promise Keeper (Development Version)
# This script uses development signing for testing purposes

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

# Version management
VERSION="${1:-$(defaults read "$PWD/mac-app/PromiseKeeper/Info.plist" CFBundleShortVersionString 2>/dev/null || echo "0.1.0")}"
BUILD_NUMBER="${2:-$(defaults read "$PWD/mac-app/PromiseKeeper/Info.plist" CFBundleVersion 2>/dev/null || echo "1")}"

# Create necessary directories
mkdir -p "$BUILD_DIR" "$EXPORT_DIR" "$DMG_DIR" "$RELEASES_DIR"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    echo -e "${RED}[ERROR] $1${NC}"
}

success() {
    echo -e "${GREEN}[SUCCESS] $1${NC}"
}

warning() {
    echo -e "${YELLOW}[WARNING] $1${NC}"
}

# Check for required tools
check_dependencies() {
    local missing=()
    
    command -v xcodebuild >/dev/null 2>&1 || missing+=("xcodebuild")
    command -v create-dmg >/dev/null 2>&1 || missing+=("create-dmg")
    
    if [ ${#missing[@]} -ne 0 ]; then
        error "Missing required tools: ${missing[*]}"
        echo "Please install missing tools:"
        for tool in "${missing[@]}"; do
            if [ "$tool" = "create-dmg" ]; then
                echo "  brew install create-dmg"
            fi
        done
        exit 1
    fi
}

check_dependencies

log "Building Promise Keeper v$VERSION (Build $BUILD_NUMBER) - Development Version"
warning "This is a development build and should not be distributed publicly!"

# Update version in project
log "Updating version numbers in project..."
/usr/libexec/PlistBuddy -c "Set :CFBundleShortVersionString $VERSION" "mac-app/PromiseKeeper/Info.plist"
/usr/libexec/PlistBuddy -c "Set :CFBundleVersion $BUILD_NUMBER" "mac-app/PromiseKeeper/Info.plist"

# Clean previous builds
log "Cleaning previous builds..."
rm -rf "$BUILD_DIR"/* "$EXPORT_DIR"/* "$DMG_DIR"/*

# Build and archive
log "Building and archiving project..."
xcodebuild -project "$WORKSPACE_PATH" \
    -scheme "$SCHEME_NAME" \
    -configuration Release \
    -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive" \
    archive \
    MARKETING_VERSION="$VERSION" \
    CURRENT_PROJECT_VERSION="$BUILD_NUMBER" \
    CODE_SIGN_IDENTITY="Apple Development" \
    DEVELOPMENT_TEAM="TX645N2QBW" \
    -allowProvisioningUpdates \
    | tee "$BUILD_DIR/build.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    error "Build failed. Check $BUILD_DIR/build.log for details."
    exit 1
fi

success "Build completed successfully"

# Create export options plist for development
log "Creating export options for development..."
cat > "$BUILD_DIR/ExportOptions.plist" << EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>method</key>
    <string>development</string>
    <key>teamID</key>
    <string>TX645N2QBW</string>
    <key>signingStyle</key>
    <string>automatic</string>
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
</dict>
</plist>
EOF

# Export archive
log "Exporting archive..."
xcodebuild -exportArchive \
    -archivePath "$BUILD_DIR/$PROJECT_NAME.xcarchive" \
    -exportPath "$EXPORT_DIR" \
    -exportOptionsPlist "$BUILD_DIR/ExportOptions.plist" \
    | tee "$BUILD_DIR/export.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    error "Export failed. Check $BUILD_DIR/export.log for details."
    exit 1
fi

success "Export completed successfully"

# Create DMG
log "Creating DMG..."
DMG_NAME="PromiseKeeper-${VERSION}-Dev"
VOLUME_NAME="Promise Keeper ${VERSION} Dev"

# The exported app keeps the project name, so we'll use that
EXPORTED_APP="PromiseKeeper.app"

create-dmg \
    --volname "$VOLUME_NAME" \
    --volicon "mac-app/PromiseKeeper/Assets.xcassets/AppIcon.appiconset/AppIcon.icns" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "$EXPORTED_APP" 150 150 \
    --hide-extension "$EXPORTED_APP" \
    --app-drop-link 450 150 \
    "$DMG_DIR/${DMG_NAME}.dmg" \
    "$EXPORT_DIR/$EXPORTED_APP"

if [ $? -eq 0 ]; then
    success "DMG created successfully: $DMG_DIR/${DMG_NAME}.dmg"
    
    # Move to releases directory
    mv "$DMG_DIR/${DMG_NAME}.dmg" "$RELEASES_DIR/"
    success "DMG moved to releases: $RELEASES_DIR/${DMG_NAME}.dmg"
    
    # Open the releases folder in Finder
    open "$RELEASES_DIR"
else
    error "DMG creation failed"
    exit 1
fi

# Display summary
echo ""
echo "========================================="
echo "Build Summary:"
echo "========================================="
echo "App Name: $APP_NAME"
echo "Version: $VERSION (Build $BUILD_NUMBER)"
echo "Bundle ID: $BUNDLE_ID"
echo "DMG Location: $RELEASES_DIR/${DMG_NAME}.dmg"
echo "Export Name: $EXPORTED_APP"
echo "========================================="
warning "This is a DEVELOPMENT build - not for distribution!"
echo ""