#!/bin/bash

# Fix widget data file permissions

APP_GROUP_PATH="$HOME/Library/Group Containers/group.TX645N2QBW.com.example.mac.SidebarApp"
WIDGET_DATA_DIR="$APP_GROUP_PATH/WidgetData"
WIDGET_DATA_FILE="$WIDGET_DATA_DIR/widget_data.json"

echo "Checking widget data permissions..."
echo "App Group Path: $APP_GROUP_PATH"
echo "Widget Data Directory: $WIDGET_DATA_DIR"
echo "Widget Data File: $WIDGET_DATA_FILE"
echo ""

# Check if paths exist
if [ ! -d "$APP_GROUP_PATH" ]; then
    echo "ERROR: App group container does not exist!"
    exit 1
fi

if [ ! -d "$WIDGET_DATA_DIR" ]; then
    echo "ERROR: WidgetData directory does not exist!"
    exit 1
fi

if [ ! -f "$WIDGET_DATA_FILE" ]; then
    echo "ERROR: widget_data.json does not exist!"
    exit 1
fi

# Show current permissions
echo "Current permissions:"
ls -la "$WIDGET_DATA_DIR"
echo ""

# Get current user
CURRENT_USER=$(whoami)
echo "Current user: $CURRENT_USER"
echo ""

# Fix permissions
echo "Fixing permissions..."
chmod 755 "$WIDGET_DATA_DIR"
chmod 644 "$WIDGET_DATA_FILE"

# Remove extended attributes that might block access
xattr -c "$WIDGET_DATA_FILE" 2>/dev/null

# Show updated permissions
echo ""
echo "Updated permissions:"
ls -la "$WIDGET_DATA_DIR"

echo ""
echo "File info:"
file "$WIDGET_DATA_FILE"
echo ""
echo "File size: $(stat -f%z "$WIDGET_DATA_FILE") bytes"

# Try to read the file
echo ""
echo "Testing read access..."
if head -n 1 "$WIDGET_DATA_FILE" > /dev/null 2>&1; then
    echo "✅ File is readable"
else
    echo "❌ File is NOT readable"
fi

echo ""
echo "Done!"