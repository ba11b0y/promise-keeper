#!/bin/bash

echo "🔄 RESTARTING WIDGET PROCESS"
echo "============================"
echo ""

# Kill the widget extension process to force restart
echo "1️⃣ Looking for PromiseWidgetExtension process..."
WIDGET_PID=$(pgrep -f "PromiseWidgetExtension")

if [ -n "$WIDGET_PID" ]; then
    echo "   Found widget process: PID $WIDGET_PID"
    echo "   Killing process..."
    kill -9 $WIDGET_PID
    echo "✅ Widget process killed"
else
    echo "   No widget process found running"
fi

# Also try to kill the WidgetKit service
echo ""
echo "2️⃣ Looking for WidgetKit processes..."
WIDGETKIT_PIDS=$(pgrep -f "com.apple.widgetkit")

if [ -n "$WIDGETKIT_PIDS" ]; then
    echo "   Found WidgetKit processes: $WIDGETKIT_PIDS"
    echo "   Note: System processes may restart automatically"
fi

# Touch the widget data file to force update
echo ""
echo "3️⃣ Touching widget data file..."
WIDGET_DATA="/Users/$USER/Library/Group Containers/group.TX645N2QBW.com.example.mac.SidebarApp/WidgetData/widget_data.json"

if [ -f "$WIDGET_DATA" ]; then
    touch "$WIDGET_DATA"
    echo "✅ Widget data file touched"
else
    echo "❌ Widget data file not found at expected location"
fi

echo ""
echo "4️⃣ Next steps:"
echo "   1. The widget should reload automatically"
echo "   2. If not, remove and re-add the widget"
echo "   3. Or open Notification Center to trigger widget refresh"
echo ""
echo "✅ Complete"