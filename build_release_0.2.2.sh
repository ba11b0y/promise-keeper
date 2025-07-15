#!/bin/bash

# Build Release 0.2.2 Script
# This script builds version 0.2.2 with widget support

set -e  # Exit on any error

VERSION="0.2.2"
BUILD_NUMBER=$(date +%Y%m%d%H%M)

echo "🚀 Building PromiseKeeper version $VERSION (build $BUILD_NUMBER)"
echo "📦 This build includes the widget extension"

# Run the main build and export script
./build_and_export_dmg.sh "$VERSION" "$BUILD_NUMBER"

echo "✅ Build complete for version $VERSION"
echo "📁 Check the releases/ directory for the DMG file"