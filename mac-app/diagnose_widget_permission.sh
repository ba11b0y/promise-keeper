#!/bin/bash
# Diagnostic script for widget permission issue NSCocoaErrorDomain 257

set -euo pipefail

echo "🔍 Widget Permission Diagnostic Script"
echo "====================================="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Group ID to check
GROUP_ID="group.TX645N2QBW.com.example.mac.SidebarApp"
EXPECTED_TEAM_ID="TX645N2QBW"

echo "Expected Group ID: $GROUP_ID"
echo "Expected Team ID: $EXPECTED_TEAM_ID"
echo

# Step 1: Find the widget bundle
echo "Step 1: Locating widget bundle..."
WIDGET_BUNDLE=$(mdfind 'kMDItemCFBundleIdentifier == com.example.PromiseWidgetExtension' | head -1)

# If not found via mdfind, check common build locations
if [ -z "$WIDGET_BUNDLE" ]; then
    echo "Searching in build directories..."
    
    # Check various possible locations
    POSSIBLE_PATHS=(
        "/Users/anaygupta/Downloads/promise-keeper/mac-app/build/Release/PromiseWidgetExtension.appex"
        "/Users/anaygupta/Downloads/promise-keeper/mac-app/build/Debug/PromiseWidgetExtension.appex"
        "/Users/anaygupta/Downloads/promise-keeper/mac-app/build/Build/Products/Debug/PromiseWidgetExtension.appex"
        "/Users/anaygupta/Downloads/promise-keeper/mac-app/build/Build/Products/Release/PromiseWidgetExtension.appex"
        "/Users/anaygupta/Library/Developer/Xcode/DerivedData/SidebarApp-*/Build/Products/Debug/PromiseWidgetExtension.appex"
        "/Users/anaygupta/Library/Developer/Xcode/DerivedData/SidebarApp-*/Build/Products/Release/PromiseWidgetExtension.appex"
    )
    
    for path in "${POSSIBLE_PATHS[@]}"; do
        expanded_path=$(echo $path)
        if [ -d "$expanded_path" ]; then
            WIDGET_BUNDLE="$expanded_path"
            echo "Found widget at: $expanded_path"
            break
        fi
    done
fi

if [ -z "$WIDGET_BUNDLE" ]; then
    echo -e "${RED}❌ ERROR: Widget bundle not found!${NC}"
    echo "Please build the widget target in Xcode first (⌘B)"
    echo "Searched locations:"
    for path in "${POSSIBLE_PATHS[@]}"; do
        echo "  - $path"
    done
    exit 1
fi

echo -e "${GREEN}✓ Found widget at: $WIDGET_BUNDLE${NC}"
echo

# Step 2: Check Team ID that signed the widget
echo "Step 2: Checking Team ID that signed the widget..."
SIGNING_INFO=$(codesign -d -vv "$WIDGET_BUNDLE" 2>&1 | grep "^Authority=" | head -1)
echo "Signing info: $SIGNING_INFO"

# Extract Team ID from signing info (it's in parentheses)
ACTUAL_TEAM_ID=$(echo "$SIGNING_INFO" | sed -n 's/.*(\([A-Z0-9]*\))$/\1/p')

if [ -z "$ACTUAL_TEAM_ID" ]; then
    echo -e "${YELLOW}⚠️  Could not extract Team ID from signing info${NC}"
    echo "Full codesign output:"
    codesign -d -vv "$WIDGET_BUNDLE" 2>&1
else
    echo "Actual Team ID: $ACTUAL_TEAM_ID"
    
    if [ "$ACTUAL_TEAM_ID" = "$EXPECTED_TEAM_ID" ]; then
        echo -e "${GREEN}✓ Team ID matches group ID prefix!${NC}"
    else
        echo -e "${RED}❌ Team ID mismatch!${NC}"
        echo "   Expected: $EXPECTED_TEAM_ID (from group ID)"
        echo "   Actual:   $ACTUAL_TEAM_ID (from code signature)"
        echo
        echo "This is likely the cause of your permission error!"
    fi
fi
echo

# Step 3: Check entitlements
echo "Step 3: Checking widget entitlements..."
ENTITLEMENTS=$(codesign -d --entitlements :- "$WIDGET_BUNDLE" 2>/dev/null || echo "")

if [ -z "$ENTITLEMENTS" ]; then
    echo -e "${RED}❌ Could not read entitlements${NC}"
else
    echo "Raw entitlements:"
    echo "$ENTITLEMENTS" | head -20
    echo
    
    # Extract app groups
    APP_GROUPS=$(echo "$ENTITLEMENTS" | plutil -extract 'com.apple.security.application-groups' raw - 2>/dev/null || echo "")
    
    if [ -z "$APP_GROUPS" ]; then
        echo -e "${RED}❌ No app groups found in entitlements!${NC}"
    else
        echo "App Groups: $APP_GROUPS"
        
        if echo "$APP_GROUPS" | grep -q "$GROUP_ID"; then
            echo -e "${GREEN}✓ Correct app group found in entitlements${NC}"
        else
            echo -e "${RED}❌ Expected app group not found in entitlements!${NC}"
        fi
    fi
fi
echo

# Step 4: Check file existence and permissions
echo "Step 4: Checking file existence and permissions..."
FILE_PATH="$HOME/Library/Group Containers/$GROUP_ID/WidgetData/widget_data.json"

if [ -f "$FILE_PATH" ]; then
    echo -e "${GREEN}✓ File exists at expected location${NC}"
    ls -la "$FILE_PATH"
    
    # Check file permissions
    PERMS=$(stat -f "%Sp" "$FILE_PATH")
    echo "File permissions: $PERMS"
    
    if [[ "$PERMS" == *"r"* ]]; then
        echo -e "${GREEN}✓ File is readable${NC}"
    else
        echo -e "${RED}❌ File is not readable!${NC}"
    fi
else
    echo -e "${RED}❌ File does not exist at: $FILE_PATH${NC}"
fi
echo

# Step 5: Check main app bundle
echo "Step 5: Checking main app bundle..."
MAIN_APP=$(mdfind 'kMDItemCFBundleIdentifier == com.example.mac.SidebarApp' | head -1)

if [ -n "$MAIN_APP" ]; then
    echo "Main app found at: $MAIN_APP"
    
    # Check main app team ID
    MAIN_SIGNING=$(codesign -d -vv "$MAIN_APP" 2>&1 | grep "^Authority=" | head -1)
    MAIN_TEAM_ID=$(echo "$MAIN_SIGNING" | sed -n 's/.*(\([A-Z0-9]*\))$/\1/p')
    
    if [ -n "$MAIN_TEAM_ID" ]; then
        echo "Main app Team ID: $MAIN_TEAM_ID"
        
        if [ "$MAIN_TEAM_ID" = "$ACTUAL_TEAM_ID" ]; then
            echo -e "${GREEN}✓ Main app and widget have same Team ID${NC}"
        else
            echo -e "${RED}❌ Main app and widget have different Team IDs!${NC}"
        fi
    fi
else
    echo -e "${YELLOW}⚠️  Main app not found${NC}"
fi
echo

# Summary
echo "====================================="
echo "SUMMARY:"
echo "====================================="

if [ -n "$ACTUAL_TEAM_ID" ] && [ "$ACTUAL_TEAM_ID" != "$EXPECTED_TEAM_ID" ]; then
    echo -e "${RED}❌ TEAM ID MISMATCH DETECTED!${NC}"
    echo
    echo "To fix this issue, you have two options:"
    echo
    echo "Option 1: Change the App Group ID prefix to match your actual Team ID"
    echo "   In both targets (SidebarApp & PromiseWidgetExtension):"
    echo "   1. Go to Signing & Capabilities → App Groups"
    echo "   2. Remove the current group"
    echo "   3. Add new group: group.$ACTUAL_TEAM_ID.com.example.mac.SidebarApp"
    echo
    echo "Option 2: Change your signing team to match the Group ID prefix"
    echo "   In both targets:"
    echo "   1. Go to Signing & Capabilities → Team"
    echo "   2. Select the team with ID: $EXPECTED_TEAM_ID"
    echo
    echo "After making changes:"
    echo "   1. Clean Build Folder (Shift+Cmd+K)"
    echo "   2. Rebuild the project"
    echo "   3. Run this diagnostic again"
else
    echo -e "${GREEN}✓ Team IDs appear to match${NC}"
    echo
    echo "Other things to check:"
    echo "1. Ensure both targets use containerURL(forSecurityApplicationGroupIdentifier:)"
    echo "2. Never hard-code paths like /Users/.../Group Containers/..."
    echo "3. Verify the widget code uses the exact same group ID string"
fi