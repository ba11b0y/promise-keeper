#!/bin/bash

echo "Verifying widget signature and entitlements..."

# Path to the built app (adjust if needed)
APP_PATH="$HOME/Library/Developer/Xcode/DerivedData/PromiseKeeper-*/Build/Products/Debug/PromiseKeeper.app"
WIDGET_PATH="$APP_PATH/Contents/PlugIns/PromiseWidgetExtension.appex"

# Find the actual app path
APP_PATH=$(find ~/Library/Developer/Xcode/DerivedData -name "PromiseKeeper.app" -path "*/Debug/*" 2>/dev/null | head -1)

if [ -z "$APP_PATH" ]; then
    echo "Error: Could not find built app. Please build the project first."
    exit 1
fi

WIDGET_PATH="$APP_PATH/Contents/PlugIns/PromiseWidgetExtension.appex"

echo "App path: $APP_PATH"
echo "Widget path: $WIDGET_PATH"
echo ""

# Check widget exists
if [ ! -d "$WIDGET_PATH" ]; then
    echo "Error: Widget extension not found at $WIDGET_PATH"
    exit 1
fi

# Verify code signature
echo "=== Widget Code Signature ==="
codesign -dv --verbose=4 "$WIDGET_PATH" 2>&1

echo ""
echo "=== Widget Entitlements ==="
codesign -d --entitlements - "$WIDGET_PATH" 2>&1

echo ""
echo "=== Provisioning Profile Info ==="
security cms -D -i "$WIDGET_PATH/Contents/embedded.mobileprovision" 2>/dev/null | grep -A1 -B1 "application-identifier\|com.apple.developer.team-identifier" || echo "No embedded provisioning profile found"

echo ""
echo "=== Network Capability Check ==="
codesign -d --entitlements - "$WIDGET_PATH" 2>&1 | grep -E "network.client|application-identifier" || echo "Network entitlements not found"