#!/bin/bash

# Quick Release Script for PromiseKeeper
# This script demonstrates the complete workflow for building and distributing updates

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 PromiseKeeper Quick Release Workflow${NC}"
echo "=========================================="
echo

# Check if version is provided
if [ $# -eq 0 ]; then
    echo -e "${YELLOW}Usage: $0 <version>${NC}"
    echo "Example: $0 0.1.0"
    echo
    echo "This script will:"
    echo "1. Build and export DMG for the specified version"
    echo "2. Distribute the update to users automatically"
    exit 1
fi

VERSION="$1"

echo -e "${GREEN}📋 Release Plan for Version $VERSION:${NC}"
echo "1. ✅ Build and export DMG"
echo "2. ✅ Upload to GitHub Releases"
echo "3. ✅ Sign with Sparkle"
echo "4. ✅ Update appcast.xml"
echo "5. ✅ Upload to GitHub Pages"
echo "6. ✅ Distribute to users automatically"
echo

read -p "Continue with release? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Release cancelled."
    exit 0
fi

echo -e "${BLUE}🔨 Step 1: Building and exporting DMG...${NC}"
./build_and_export_dmg.sh "$VERSION"

echo
echo -e "${BLUE}📤 Step 2: Uploading to GitHub Releases...${NC}"
./upload_release_to_github.sh "$VERSION" "Release $VERSION with latest features and bug fixes"

echo
echo -e "${BLUE}📤 Step 3: Distributing update to users...${NC}"
./send_update_to_users.sh "PromiseKeeper-$VERSION"

echo
echo -e "${GREEN}🎉 Release Complete!${NC}"
echo "✅ Version $VERSION has been built and distributed"
echo "✅ Users will receive automatic updates within 1 hour"
echo "✅ Monitor adoption at: https://anaygupta2004.github.io/src/appcast.xml"