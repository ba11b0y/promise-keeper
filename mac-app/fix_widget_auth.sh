#!/bin/bash

echo "🔧 Fixing widget authentication issues..."

# Kill widget processes to force reload
echo "Stopping widget processes..."
killall WidgetKit-Simulator 2>/dev/null || true
killall chronod 2>/dev/null || true

# Clear widget caches
echo "Clearing widget caches..."
rm -rf ~/Library/Caches/com.example.mac.PromiseKeeper.PromiseWidgetExtension
rm -rf ~/Library/Caches/com.apple.widgetkit-simulator

# Clear UserDefaults caches that might have stale data
echo "Clearing UserDefaults caches..."
defaults delete group.TX645N2QBW.com.example.mac.PromiseKeeper 2>/dev/null || true
defaults delete group.TX645N2QBW.com.example.mac.SidebarApp 2>/dev/null || true

# Remove all keychain items for fresh start
echo "Clearing keychain items..."
security delete-generic-password -a "supabase_session" -s "TX645N2QBW.com.example.mac.PromiseKeeper" 2>/dev/null || true
security delete-generic-password -a "supabase_access_token" -s "TX645N2QBW.com.example.mac.PromiseKeeper" 2>/dev/null || true
security delete-generic-password -a "supabase_user_id" -s "TX645N2QBW.com.example.mac.PromiseKeeper" 2>/dev/null || true
security delete-generic-password -a "supabase_user_email" -s "TX645N2QBW.com.example.mac.PromiseKeeper" 2>/dev/null || true
security delete-generic-password -a "supabase_session_expiry" -s "TX645N2QBW.com.example.mac.PromiseKeeper" 2>/dev/null || true

# Clear old keychain items from wrong access group
security delete-generic-password -a "supabase_session" -s "TX645N2QBW.com.example.mac.SidebarApp" 2>/dev/null || true
security delete-generic-password -a "supabase_access_token" -s "TX645N2QBW.com.example.mac.SidebarApp" 2>/dev/null || true
security delete-generic-password -a "supabase_user_id" -s "TX645N2QBW.com.example.mac.SidebarApp" 2>/dev/null || true
security delete-generic-password -a "supabase_user_email" -s "TX645N2QBW.com.example.mac.SidebarApp" 2>/dev/null || true
security delete-generic-password -a "supabase_session_expiry" -s "TX645N2QBW.com.example.mac.SidebarApp" 2>/dev/null || true

echo ""
echo "✅ Widget authentication cache cleared!"
echo ""
echo "Next steps:"
echo "1. Rebuild the app and widget in Xcode"
echo "2. Sign out and sign back in to the app"
echo "3. The widget should now work with fresh authentication"