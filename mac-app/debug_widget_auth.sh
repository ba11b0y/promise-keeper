#!/bin/bash

echo "🔍 Widget Authentication Debug Script v2.0"
echo "========================================"
echo "Now with Keychain session checking!"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check current App Group identifier in files
echo "📋 Checking App Group identifiers in source files:"
echo ""

# Check AppGroupConfig.swift
echo "AppGroupConfig.swift:"
grep -n "identifier = " PromiseKeeper/Configuration/AppGroupConfig.swift | grep -v "//" || echo "${RED}Not found${NC}"
echo ""

# Check PromiseWidget.swift
echo "PromiseWidget.swift:"
grep -n "appGroupIdentifier = " PromiseWidget/PromiseWidget.swift | grep -v "//" || echo "${RED}Not found${NC}"
echo ""

# Check entitlements
echo "📋 Checking entitlements files:"
echo ""
echo "PromiseKeeper.entitlements:"
grep -A 2 "application-groups" PromiseKeeper/PromiseKeeper.entitlements || echo "${RED}Not found${NC}"
echo ""
echo "PromiseWidget.entitlements:"
grep -A 2 "application-groups" PromiseWidget/PromiseWidget.entitlements || echo "${RED}Not found${NC}"
echo ""

# Check if old App Group data exists
echo "📋 Checking for existing App Group data:"
echo ""

OLD_GROUP="group.TX645N2QBW.com.example.mac.PromiseKeeper"
NEW_GROUP="group.com.example.mac.PromiseKeeper"

if defaults read $OLD_GROUP &>/dev/null; then
    echo "${YELLOW}⚠️  Found data in old App Group: $OLD_GROUP${NC}"
    echo "   Run: defaults delete $OLD_GROUP"
else
    echo "${GREEN}✅ No data in old App Group${NC}"
fi

if defaults read $NEW_GROUP &>/dev/null; then
    echo "${GREEN}✅ Found data in new App Group: $NEW_GROUP${NC}"
    echo "   Keys found:"
    defaults read $NEW_GROUP 2>/dev/null | grep -E "widget_" | head -5
else
    echo "${YELLOW}⚠️  No data in new App Group yet${NC}"
fi

echo ""
echo "📋 Checking Keychain Access:"
echo ""

# Check for Keychain items
KEYCHAIN_GROUP="TX645N2QBW.com.example.mac.PromiseKeeper"
echo "Keychain Access Group: ${BLUE}$KEYCHAIN_GROUP${NC}"

# Try to find the session in Keychain
if security find-generic-password -a "supabase_session" -s "$KEYCHAIN_GROUP" &>/dev/null; then
    echo "${GREEN}✅ Found Supabase session in Keychain${NC}"
    echo "   Session exists and is accessible"
else
    echo "${RED}❌ No Supabase session found in Keychain${NC}"
    echo "   Either not signed in or Keychain access issue"
fi

echo ""
echo "📋 Quick fixes:"
echo ""
echo "1. Clean build folder: ${YELLOW}Cmd+Shift+K${NC} in Xcode"
echo "2. Delete derived data: ${YELLOW}rm -rf ~/Library/Developer/Xcode/DerivedData/*${NC}"
echo "3. Delete old App Group data: ${YELLOW}defaults delete $OLD_GROUP${NC}"
echo "4. In Xcode, for BOTH targets (main app & widget):"
echo "   ${BLUE}App Groups:${NC}"
echo "   - Remove old: $OLD_GROUP"
echo "   - Add new: $NEW_GROUP"
echo "   ${BLUE}Keychain Sharing:${NC}"
echo "   - Add capability if missing"
echo "   - Add group: com.example.mac.PromiseKeeper"
echo ""
echo "✅ App Group should be: ${GREEN}$NEW_GROUP${NC}"
echo "✅ Keychain Group should be: ${GREEN}com.example.mac.PromiseKeeper${NC}"