#!/bin/bash

# GitHub Release Upload Script for PromiseKeeper
# This script creates GitHub releases and uploads DMG files

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
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
    error "Usage: $0 <version> [release_notes]"
    error "Example: $0 0.1.0 \"Bug fixes and improvements\""
    exit 1
fi

VERSION="$1"
RELEASE_NOTES="${2:-Release $VERSION}"
DMG_NAME="PromiseKeeper-$VERSION"
DMG_PATH="./releases/$DMG_NAME.dmg"
INFO_PATH="./releases/$DMG_NAME.info"

log "Starting GitHub release process for version $VERSION"

# Validate version format
if ! [[ $VERSION =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    error "Version must be in format X.Y.Z (e.g., 1.2.0)"
    exit 1
fi

# Check if DMG file exists
if [ ! -f "$DMG_PATH" ]; then
    error "DMG file not found: $DMG_PATH"
    error "Please run ./build_and_export_dmg.sh $VERSION first"
    exit 1
fi

# Read DMG info if available
if [ -f "$INFO_PATH" ]; then
    source "$INFO_PATH"
    log "Loaded build info: Version $VERSION, Build $BUILD_NUMBER"
else
    warning "No build info file found, using defaults"
    BUILD_NUMBER="unknown"
fi

# Check if release already exists
if gh release view "v$VERSION" >/dev/null 2>&1; then
    warning "Release v$VERSION already exists"
    read -p "Delete existing release and recreate? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        log "Deleting existing release..."
        gh release delete "v$VERSION" --yes
    else
        error "Release cancelled"
        exit 1
    fi
fi

# Get DMG file size in human readable format
DMG_SIZE_HR=$(ls -lh "$DMG_PATH" | awk '{print $5}')

# Create release notes
FULL_RELEASE_NOTES="# PromiseKeeper v$VERSION

$RELEASE_NOTES

## Installation
1. Download the DMG file below
2. Open the DMG and drag PromiseKeeper to Applications
3. Launch PromiseKeeper from Applications

## Build Information
- Version: $VERSION
- Build: $BUILD_NUMBER
- File size: $DMG_SIZE_HR
- Built: $(date -u +"%Y-%m-%d %H:%M:%S UTC")

## Automatic Updates
If you have a previous version installed, PromiseKeeper will automatically check for updates.

---
🤖 This release was created automatically."

log "Creating GitHub release v$VERSION..."

# Create the release
gh release create "v$VERSION" \
    --title "PromiseKeeper v$VERSION" \
    --notes "$FULL_RELEASE_NOTES" \
    --draft=false \
    --prerelease=false

if [ $? -ne 0 ]; then
    error "Failed to create GitHub release"
    exit 1
fi

success "GitHub release v$VERSION created successfully"

# Upload the DMG file
log "Uploading DMG file to release..."
gh release upload "v$VERSION" "$DMG_PATH" \
    --clobber

if [ $? -ne 0 ]; then
    error "Failed to upload DMG file to release"
    exit 1
fi

success "DMG file uploaded successfully"

# Get the release URL
RELEASE_URL=$(gh release view "v$VERSION" --json url --jq .url)

success "✅ GitHub release completed successfully!"
log "🔗 Release URL: $RELEASE_URL"
log "📁 DMG uploaded: $DMG_NAME.dmg ($DMG_SIZE_HR)"
log "🏷️  Tag: v$VERSION"

echo
warning "Next steps:"
echo "1. Test the release by downloading and installing from GitHub"
echo "2. Share the release URL with users: $RELEASE_URL"
echo "3. Monitor download statistics in GitHub"