#!/bin/bash

echo "🔍 CHECKING WIDGET ENTITLEMENTS"
echo "==============================="
echo ""

# Find the widget extension
WIDGET_PATH="/Users/anaygupta/Library/Developer/Xcode/DerivedData/PromiseKeeper-drhgvuuzlirrmzfbehzkkikegfxd/Build/Products/Debug/PromiseKeeper.app/Contents/PlugIns/PromiseWidgetExtension.appex"

if [ -d "$WIDGET_PATH" ]; then
    echo "✅ Widget found at: $WIDGET_PATH"
    echo ""
    
    # Check entitlements
    echo "📋 Widget Entitlements:"
    codesign -d --entitlements - "$WIDGET_PATH" 2>&1 | grep -A 10 "com.apple.security.application-groups" || echo "❌ No app group entitlements found"
    
    echo ""
    echo "📋 Main App Entitlements:"
    APP_PATH="/Users/anaygupta/Library/Developer/Xcode/DerivedData/PromiseKeeper-drhgvuuzlirrmzfbehzkkikegfxd/Build/Products/Debug/PromiseKeeper.app"
    codesign -d --entitlements - "$APP_PATH" 2>&1 | grep -A 10 "com.apple.security.application-groups" || echo "❌ No app group entitlements found"
    
else
    echo "❌ Widget not found at expected path"
fi

echo ""
echo "✅ Complete"