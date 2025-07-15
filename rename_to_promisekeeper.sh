#!/bin/bash

# Script to rename SidebarApp to PromiseKeeper throughout the project
# This is a comprehensive rename that updates all references

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if we're in the right directory
if [ ! -d "mac-app" ]; then
    error "Please run this script from the promise-keeper root directory"
    exit 1
fi

log "Starting rename process from SidebarApp to PromiseKeeper..."

# 1. Create backups
log "Creating backups..."
cp -r mac-app mac-app.backup.$(date +%Y%m%d_%H%M%S)
success "Backup created"

# 2. Rename directories
log "Renaming directories..."
if [ -d "mac-app/SidebarApp" ]; then
    mv "mac-app/SidebarApp" "mac-app/PromiseKeeper"
    success "Renamed app directory"
fi

if [ -d "mac-app/SidebarApp.xcodeproj" ]; then
    mv "mac-app/SidebarApp.xcodeproj" "mac-app/PromiseKeeper.xcodeproj"
    success "Renamed project directory"
fi

# 3. Update project.pbxproj
log "Updating project.pbxproj..."
if [ -f "mac-app/PromiseKeeper.xcodeproj/project.pbxproj" ]; then
    sed -i '' 's/SidebarApp/PromiseKeeper/g' "mac-app/PromiseKeeper.xcodeproj/project.pbxproj"
    success "Updated project.pbxproj"
fi

# 4. Update scheme files
log "Updating scheme files..."
if [ -d "mac-app/PromiseKeeper.xcodeproj/xcshareddata/xcschemes" ]; then
    # Rename scheme file
    if [ -f "mac-app/PromiseKeeper.xcodeproj/xcshareddata/xcschemes/SidebarApp.xcscheme" ]; then
        mv "mac-app/PromiseKeeper.xcodeproj/xcshareddata/xcschemes/SidebarApp.xcscheme" \
           "mac-app/PromiseKeeper.xcodeproj/xcshareddata/xcschemes/PromiseKeeper.xcscheme"
    fi
    
    # Update scheme contents
    find "mac-app/PromiseKeeper.xcodeproj/xcshareddata/xcschemes" -name "*.xcscheme" -type f -exec \
        sed -i '' 's/SidebarApp/PromiseKeeper/g' {} \;
    success "Updated scheme files"
fi

# 5. Update build scripts
log "Updating build scripts..."
scripts=(
    "build_and_export_dmg.sh"
    "build_and_export_dev.sh"
    "quick_release.sh"
    "send_update_to_users.sh"
)

for script in "${scripts[@]}"; do
    if [ -f "$script" ]; then
        sed -i '' 's/PROJECT_NAME="SidebarApp"/PROJECT_NAME="PromiseKeeper"/g' "$script"
        sed -i '' 's/SCHEME_NAME="SidebarApp"/SCHEME_NAME="PromiseKeeper"/g' "$script"
        sed -i '' 's|WORKSPACE_PATH="mac-app/SidebarApp.xcodeproj"|WORKSPACE_PATH="mac-app/PromiseKeeper.xcodeproj"|g' "$script"
        sed -i '' 's|mac-app/SidebarApp/Info.plist|mac-app/PromiseKeeper/Info.plist|g' "$script"
        sed -i '' 's|mac-app/SidebarApp/Assets.xcassets|mac-app/PromiseKeeper/Assets.xcassets|g' "$script"
        success "Updated $script"
    fi
done

# 6. Update shell scripts in mac-app directory
log "Updating mac-app shell scripts..."
find mac-app -name "*.sh" -type f -exec \
    sed -i '' 's/SidebarApp/PromiseKeeper/g' {} \;
success "Updated mac-app shell scripts"

# 7. Update Python scripts
log "Updating Python scripts..."
find mac-app -name "*.py" -type f -exec \
    sed -i '' 's/SidebarApp/PromiseKeeper/g' {} \;
success "Updated Python scripts"

# 8. Update Swift files
log "Updating Swift import statements and references..."
find mac-app/PromiseKeeper -name "*.swift" -type f -exec \
    sed -i '' 's/import SidebarApp/import PromiseKeeper/g' {} \;
success "Updated Swift files"

# 9. Update Info.plist path references
log "Updating Info.plist..."
if [ -f "mac-app/PromiseKeeper/Info.plist" ]; then
    # The display name is already "Promise Keeper", but let's make sure
    /usr/libexec/PlistBuddy -c "Set :CFBundleExecutable PromiseKeeper" "mac-app/PromiseKeeper/Info.plist" 2>/dev/null || true
    success "Updated Info.plist"
fi

# 10. Update documentation
log "Updating documentation files..."
find . -name "*.md" -type f -exec \
    sed -i '' 's|mac-app/SidebarApp|mac-app/PromiseKeeper|g' {} \;
find . -name "*.md" -type f -exec \
    sed -i '' 's/SidebarApp.xcodeproj/PromiseKeeper.xcodeproj/g' {} \;
success "Updated documentation"

# 11. Clean derived data
log "Cleaning Xcode derived data..."
rm -rf ~/Library/Developer/Xcode/DerivedData/SidebarApp-*
success "Cleaned derived data"

# 12. Update .gitignore if needed
if [ -f ".gitignore" ]; then
    sed -i '' 's/SidebarApp/PromiseKeeper/g' .gitignore
fi

log "Rename process completed!"
warning "IMPORTANT: You need to:"
echo "1. Open the project in Xcode (mac-app/PromiseKeeper.xcodeproj)"
echo "2. Clean the build folder (Shift+Cmd+K)"
echo "3. Build the project to ensure everything works"
echo "4. Update any hardcoded paths in your CI/CD pipelines"
echo "5. Commit these changes to git"

success "Project renamed from SidebarApp to PromiseKeeper!"