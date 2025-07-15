#!/bin/bash

echo "🔍 Testing Widget Permission Fix..."

# Check App Group entitlements
echo -e "\n📋 Checking Widget Entitlements:"
if plutil -p PromiseWidget/PromiseWidget.entitlements | grep -q '$(TeamIdentifierPrefix)'; then
    echo "❌ Widget still has incorrect App Group entry"
else
    echo "✅ Widget entitlements are correct"
fi

echo -e "\n📋 Checking Main App Entitlements:"
if plutil -p PromiseKeeper/PromiseKeeper.entitlements | grep -q '$(TeamIdentifierPrefix)'; then
    echo "❌ Main app still has incorrect App Group entry"
else
    echo "✅ Main app entitlements are correct"
fi

# Check App Group container
APP_GROUP="group.TX645N2QBW.com.example.mac.PromiseKeeper"
CONTAINER_PATH="$HOME/Library/Group Containers/$APP_GROUP"

echo -e "\n📂 Checking App Group Container:"
if [ -d "$CONTAINER_PATH" ]; then
    echo "✅ App Group container exists at: $CONTAINER_PATH"
    
    # Check WidgetData directory
    if [ -d "$CONTAINER_PATH/WidgetData" ]; then
        echo "✅ WidgetData directory exists"
        
        # Check permissions
        echo -e "\n🔒 Directory permissions:"
        ls -ld "$CONTAINER_PATH/WidgetData"
        
        # Check for widget_data.json
        if [ -f "$CONTAINER_PATH/WidgetData/widget_data.json" ]; then
            echo -e "\n✅ widget_data.json exists"
            echo "🔒 File permissions:"
            ls -l "$CONTAINER_PATH/WidgetData/widget_data.json"
            
            # Show file size and preview
            SIZE=$(stat -f%z "$CONTAINER_PATH/WidgetData/widget_data.json" 2>/dev/null || echo "unknown")
            echo "📊 File size: $SIZE bytes"
            
            echo -e "\n📄 File preview (first 200 chars):"
            head -c 200 "$CONTAINER_PATH/WidgetData/widget_data.json" 2>/dev/null || echo "Cannot read file"
        else
            echo "⚠️  widget_data.json does not exist yet"
        fi
    else
        echo "⚠️  WidgetData directory does not exist yet"
    fi
else
    echo "❌ App Group container does not exist"
fi

echo -e "\n💡 Next steps:"
echo "1. Clean Build Folder (Shift+Cmd+K) in Xcode"
echo "2. Rebuild both the main app and widget extension"
echo "3. Run the main app first to create the data file"
echo "4. Then add/refresh the widget to see if it loads data correctly"