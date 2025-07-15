#!/bin/bash

# PromiseKeeper DMG Export Script
# This script builds, archives, exports, and creates a DMG for distribution

set -e  # Exit on any error

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

# Check if version is provided
if [ $# -eq 0 ]; then
    error "Usage: $0 <version> [build_number]"
    error "Example: $0 0.1.0 1"
    error "         $0 0.2.0 $(date +%Y%m%d%H%M)"
    exit 1
fi

VERSION="$1"
BUILD_NUMBER="${2:-$(date +%Y%m%d%H%M)}"

log "Starting DMG export process for version $VERSION (build $BUILD_NUMBER)"

# Validate version format
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Version must be in format X.Y.Z (e.g., 1.2.0)"
    exit 1
fi

# Create directories
log "Creating build directories..."
mkdir -p "$BUILD_DIR" "$EXPORT_DIR" "$DMG_DIR" "$RELEASES_DIR"

# Check if Xcode project exists
if [ ! -d "$WORKSPACE_PATH" ]; then
    error "Xcode project not found at $WORKSPACE_PATH"
    exit 1
fi

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
    CODE_SIGN_STYLE=Automatic \
    DEVELOPMENT_TEAM="TX645N2QBW" \
    -allowProvisioningUpdates \
    | tee "$BUILD_DIR/build.log"

if [ ${PIPESTATUS[0]} -ne 0 ]; then
    error "Build failed. Check $BUILD_DIR/build.log for details."
    exit 1
fi

success "Build completed successfully"

# Create export options plist
log "Creating export options..."
cat > "$BUILD_DIR/ExportOptions.plist" << EOF
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
    <key>stripSwiftSymbols</key>
    <true/>
    <key>thinning</key>
    <string>&lt;none&gt;</string>
    <key>provisioningProfiles</key>
    <dict/>
    <key>signingCertificate</key>
    <string>Developer ID Application</string>
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

# Find the exported app (Xcode exports with project name)
EXPORTED_APP_NAME="PromiseKeeper.app"
APP_PATH="$EXPORT_DIR/$EXPORTED_APP_NAME"
if [ ! -d "$APP_PATH" ]; then
    # Fallback to display name if not found
    APP_PATH="$EXPORT_DIR/$APP_NAME.app"
    if [ ! -d "$APP_PATH" ]; then
        error "Exported app not found at $EXPORT_DIR"
        ls -la "$EXPORT_DIR"
        exit 1
    fi
fi

# Verify code signing
log "Verifying code signing..."
if ! codesign -v "$APP_PATH"; then
    error "Code signing verification failed"
    exit 1
fi

success "Code signing verified"

# Create DMG
DMG_NAME="PromiseKeeper-$VERSION"
DMG_PATH="$RELEASES_DIR/$DMG_NAME.dmg"

log "Creating DMG: $DMG_NAME.dmg"

# Create a temporary DMG directory
TEMP_DMG_DIR="$DMG_DIR/dmg_temp"
mkdir -p "$TEMP_DMG_DIR"

# Copy app to temp directory
cp -R "$APP_PATH" "$TEMP_DMG_DIR/"

# Create Applications symlink
ln -s /Applications "$TEMP_DMG_DIR/Applications"

# Calculate size needed for DMG
SIZE=$(du -sk "$TEMP_DMG_DIR" | cut -f1)
SIZE=$((SIZE + 10000)) # Add 10MB buffer

# Create DMG
hdiutil create -srcfolder "$TEMP_DMG_DIR" \
    -volname "$APP_NAME $VERSION" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDBZ \
    -size ${SIZE}k \
    "$DMG_PATH"

if [ $? -ne 0 ]; then
    error "DMG creation failed"
    exit 1
fi

# Clean up temp directory
rm -rf "$TEMP_DMG_DIR"

# Get DMG file size
DMG_SIZE=$(stat -f%z "$DMG_PATH")

success "DMG created successfully: $DMG_PATH"
log "DMG size: $DMG_SIZE bytes"

# Create info file for the update script
cat > "$RELEASES_DIR/$DMG_NAME.info" << EOF
VERSION=$VERSION
BUILD_NUMBER=$BUILD_NUMBER
DMG_PATH=$DMG_PATH
DMG_SIZE=$DMG_SIZE
DMG_NAME=$DMG_NAME.dmg
CREATED_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")
EOF

success "Build information saved to $RELEASES_DIR/$DMG_NAME.info"

# Final verification
log "Performing final verification..."
if [ -f "$DMG_PATH" ] && [ -s "$DMG_PATH" ]; then
    success "✅ DMG export completed successfully!"
    log "📁 DMG Location: $DMG_PATH"
    log "📊 DMG Size: $(numfmt --to=iec $DMG_SIZE)"
    log "🏷️  Version: $VERSION"
    log "🔢 Build: $BUILD_NUMBER"
    echo
    warning "Next steps:"
    echo "1. Test the DMG by mounting and running the app"
    echo "2. Run the update distribution script: ./send_update_to_users.sh $DMG_NAME"
else
    error "DMG creation verification failed"
    exit 1
fi