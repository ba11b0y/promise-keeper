#!/bin/bash

echo "🔧 Fixing Widget Data Permissions..."

APP_GROUP="group.TX645N2QBW.com.example.mac.PromiseKeeper"
CONTAINER_PATH="$HOME/Library/Group Containers/$APP_GROUP"
WIDGET_DATA_DIR="$CONTAINER_PATH/WidgetData"
WIDGET_DATA_FILE="$WIDGET_DATA_DIR/widget_data.json"

# Check if container exists
if [ ! -d "$CONTAINER_PATH" ]; then
    echo "❌ App Group container not found at: $CONTAINER_PATH"
    echo "Please run the main app first to create it."
    exit 1
fi

echo "✅ Found App Group container"

# Remove existing WidgetData directory and file to start fresh
if [ -d "$WIDGET_DATA_DIR" ]; then
    echo "🗑️  Removing existing WidgetData directory..."
    rm -rf "$WIDGET_DATA_DIR"
fi

echo "✅ Cleaned up old data"

# Create directory with proper permissions
echo "📁 Creating WidgetData directory with proper permissions..."
mkdir -p "$WIDGET_DATA_DIR"
chmod 755 "$WIDGET_DATA_DIR"

echo "✅ Directory created with permissions: $(stat -f "%Sp" "$WIDGET_DATA_DIR")"

echo ""
echo "🎉 Done! Next steps:"
echo "1. Clean Build Folder in Xcode (Shift+Cmd+K)"
echo "2. Build and run the main app"
echo "3. Sign in and let it sync some promises"
echo "4. Add the widget - it should now be able to read the data"