#!/bin/bash

# PromiseKeeper Update Distribution Script
# This script signs the DMG, updates appcast.xml, and distributes the update

set -e  # Exit on any error

# Configuration
GITHUB_USERNAME="anaygupta2004"
GITHUB_REPO="anaygupta2004.github.io"
APPCAST_URL="https://anaygupta2004.github.io/src/appcast.xml"
RELEASES_BASE_URL="https://anaygupta2004.github.io/src/releases"
PRIVATE_KEY="pBCGm80Eiudx3ah9/Y76h6gZCHRKu+xgFEyKCeoYh98="
RELEASES_DIR="./releases"
TEMP_DIR="./temp_update"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
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

# Check dependencies
check_dependencies() {
    local deps=("git" "curl" "swift")
    for dep in "${deps[@]}"; do
        if ! command -v "$dep" &> /dev/null; then
            error "Required dependency '$dep' is not installed"
            exit 1
        fi
    done
}

# Sign DMG with Sparkle
sign_dmg() {
    local dmg_path="$1"
    local private_key="$2"
    
    log "Signing DMG with Sparkle..."
    
    # Create temporary signing script
    cat > "$TEMP_DIR/sign_release.swift" << 'EOF'
#!/usr/bin/env swift

import Foundation
import CryptoKit

guard CommandLine.arguments.count == 3 else {
    print("Usage: swift sign_release.swift <private_key_base64> <file_path>")
    exit(1)
}

let privateKeyBase64 = CommandLine.arguments[1]
let filePath = CommandLine.arguments[2]

// Decode private key
guard let privateKeyData = Data(base64Encoded: privateKeyBase64) else {
    print("Error: Invalid private key format")
    exit(1)
}

// Load file data
guard let fileData = FileManager.default.contents(atPath: filePath) else {
    print("Error: Could not read file at \(filePath)")
    exit(1)
}

do {
    // Create private key
    let privateKey = try Curve25519.Signing.PrivateKey(rawRepresentation: privateKeyData)
    
    // Sign the file
    let signature = try privateKey.signature(for: fileData)
    let signatureBase64 = signature.base64EncodedString()
    
    print(signatureBase64)
    
} catch {
    print("Error signing file: \(error)")
    exit(1)
}
EOF
    
    chmod +x "$TEMP_DIR/sign_release.swift"
    
    # Sign the DMG and capture signature
    local signature
    signature=$(swift "$TEMP_DIR/sign_release.swift" "$private_key" "$dmg_path")
    
    if [ $? -ne 0 ] || [ -z "$signature" ]; then
        error "Failed to sign DMG"
        exit 1
    fi
    
    echo "$signature"
}

# Update appcast.xml
update_appcast() {
    local version="$1"
    local dmg_name="$2"
    local dmg_size="$3"
    local signature="$4"
    local release_date="$5"
    local release_notes="$6"
    
    log "Updating appcast.xml..."
    
    # Create new appcast entry
    cat > "$TEMP_DIR/new_entry.xml" << EOF
      <item>
         <title>Version $version</title>
         <description><![CDATA[
            $release_notes
         ]]></description>
         <pubDate>$release_date</pubDate>
         <sparkle:version>$version</sparkle:version>
         <sparkle:shortVersionString>$version</sparkle:shortVersionString>
         <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
         <sparkle:criticalUpdate>false</sparkle:criticalUpdate>
         <enclosure 
            url="$RELEASES_BASE_URL/$dmg_name"
            length="$dmg_size" 
            type="application/octet-stream"
            sparkle:edSignature="$signature" 
            sparkle:installationType="package" />
      </item>
EOF
    
    # Download current appcast
    curl -s "$APPCAST_URL" > "$TEMP_DIR/current_appcast.xml" || {
        warning "Could not download current appcast, creating new one..."
        cat > "$TEMP_DIR/current_appcast.xml" << EOF
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0" xmlns:sparkle="http://www.andymatuschak.org/xml-namespaces/sparkle" xmlns:dc="http://purl.org/dc/elements/1.1/">
   <channel>
      <title>Promise Keeper Changelog</title>
      <link>$APPCAST_URL</link>
      <description>Most recent changes with links to updates.</description>
      <language>en</language>
      
      <!-- Updates will be inserted here -->
      
   </channel>
</rss>
EOF
    }
    
    # Insert new entry at the top of the items
    python3 << EOF
import xml.etree.ElementTree as ET
import re

# Read the current appcast
with open('$TEMP_DIR/current_appcast.xml', 'r') as f:
    content = f.read()

# Read the new entry
with open('$TEMP_DIR/new_entry.xml', 'r') as f:
    new_entry = f.read()

# Find the position to insert (after language tag)
pattern = r'(<language>en</language>\s*)'
replacement = r'\1\n      <!-- Version $version -->\n' + new_entry + '\n'

# Insert the new entry
updated_content = re.sub(pattern, replacement, content, count=1)

# Write the updated appcast
with open('$TEMP_DIR/updated_appcast.xml', 'w') as f:
    f.write(updated_content)
EOF
    
    if [ ! -f "$TEMP_DIR/updated_appcast.xml" ]; then
        error "Failed to update appcast.xml"
        exit 1
    fi
    
    success "Appcast updated successfully"
}

# Upload to GitHub Pages
upload_to_github() {
    local dmg_path="$1"
    local dmg_name="$2"
    
    log "Preparing GitHub upload..."
    
    # Clone or update the GitHub Pages repository
    if [ -d "$TEMP_DIR/github_repo" ]; then
        cd "$TEMP_DIR/github_repo"
        git pull origin main
    else
        git clone "https://github.com/$GITHUB_USERNAME/$GITHUB_REPO.git" "$TEMP_DIR/github_repo"
        cd "$TEMP_DIR/github_repo"
    fi
    
    # Create necessary directories
    mkdir -p src/releases
    
    # Copy DMG to releases directory
    log "Copying DMG to GitHub repo..."
    cp "$dmg_path" "src/releases/$dmg_name"
    
    # Copy updated appcast
    log "Updating appcast.xml..."
    cp "$TEMP_DIR/updated_appcast.xml" "src/appcast.xml"
    
    # Check if there are changes
    if git diff --quiet && git diff --cached --quiet; then
        warning "No changes to commit"
        return 0
    fi
    
    # Commit and push changes
    log "Committing changes to GitHub..."
    git add .
    git commit -m "🚀 Release PromiseKeeper v$VERSION

- Added $dmg_name to releases
- Updated appcast.xml with new version
- Automatic update will be distributed to users"
    
    log "Pushing to GitHub Pages..."
    git push origin main
    
    success "Update published to GitHub Pages"
}

# Generate release notes
generate_release_notes() {
    local version="$1"
    
    echo "<h2>What's New in Version $version</h2>"
    echo "<ul>"
    
    # Try to get git changes since last tag
    local last_tag
    last_tag=$(git describe --tags --abbrev=0 2>/dev/null || echo "")
    
    if [ -n "$last_tag" ]; then
        echo "   <li>See detailed changes since $last_tag</li>"
        # Could add more sophisticated changelog parsing here
    fi
    
    echo "   <li>Performance improvements and bug fixes</li>"
    echo "   <li>Enhanced stability and user experience</li>"
    echo "</ul>"
}

# Verify update deployment
verify_deployment() {
    local version="$1"
    local dmg_name="$2"
    
    log "Verifying deployment..."
    
    # Wait a moment for GitHub Pages to update
    sleep 10
    
    # Check if appcast is accessible
    if curl -s --head "$APPCAST_URL" | grep -q "200 OK"; then
        success "✅ Appcast is accessible"
    else
        error "❌ Appcast is not accessible"
        return 1
    fi
    
    # Check if DMG is accessible
    local dmg_url="$RELEASES_BASE_URL/$dmg_name"
    if curl -s --head "$dmg_url" | grep -q "200 OK"; then
        success "✅ DMG is accessible"
    else
        error "❌ DMG is not accessible"
        return 1
    fi
    
    # Verify appcast contains new version
    if curl -s "$APPCAST_URL" | grep -q "$version"; then
        success "✅ Appcast contains version $version"
    else
        error "❌ Appcast does not contain version $version"
        return 1
    fi
    
    success "🎉 Update deployment verified successfully!"
}

# Main execution
main() {
    # Check if DMG name is provided
    if [ $# -eq 0 ]; then
        error "Usage: $0 <dmg_name_without_extension> [release_notes_file]"
        error "Example: $0 PromiseKeeper-0.1.0"
        error "         $0 PromiseKeeper-0.1.0 ./release_notes.md"
        exit 1
    fi
    
    local dmg_name="$1"
    local release_notes_file="$2"
    
    # Validate DMG name format
    if ! [[ $dmg_name =~ ^PromiseKeeper-[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        error "DMG name must be in format PromiseKeeper-X.Y.Z"
        exit 1
    fi
    
    # Extract version from DMG name
    local version=${dmg_name#PromiseKeeper-}
    local dmg_file="$dmg_name.dmg"
    local dmg_path="$RELEASES_DIR/$dmg_file"
    local info_file="$RELEASES_DIR/$dmg_name.info"
    
    log "🚀 Starting update distribution for version $version"
    
    # Check dependencies
    check_dependencies
    
    # Verify DMG exists
    if [ ! -f "$dmg_path" ]; then
        error "DMG file not found: $dmg_path"
        error "Run build_and_export_dmg.sh first to create the DMG"
        exit 1
    fi
    
    # Load build info
    if [ -f "$info_file" ]; then
        source "$info_file"
        log "Loaded build info: Version $VERSION, Build $BUILD_NUMBER"
    else
        warning "Build info file not found, using defaults"
        DMG_SIZE=$(stat -f%z "$dmg_path")
        CREATED_DATE=$(date -u +"%a, %d %b %Y %H:%M:%S +0000")
    fi
    
    # Create temp directory
    mkdir -p "$TEMP_DIR"
    
    # Sign the DMG
    log "🔐 Signing DMG..."
    local signature
    signature=$(sign_dmg "$dmg_path" "$PRIVATE_KEY")
    success "DMG signed successfully"
    
    # Generate or load release notes
    local release_notes
    if [ -n "$release_notes_file" ] && [ -f "$release_notes_file" ]; then
        release_notes=$(cat "$release_notes_file")
        log "Using release notes from $release_notes_file"
    else
        release_notes=$(generate_release_notes "$version")
        log "Generated automatic release notes"
    fi
    
    # Update appcast
    update_appcast "$version" "$dmg_file" "$DMG_SIZE" "$signature" "$CREATED_DATE" "$release_notes"
    
    # Upload to GitHub
    upload_to_github "$dmg_path" "$dmg_file"
    
    # Verify deployment
    verify_deployment "$version" "$dmg_file"
    
    # Clean up
    rm -rf "$TEMP_DIR"
    
    success "🎉 Update distribution completed successfully!"
    echo
    log "📊 Update Summary:"
    log "   Version: $version"
    log "   DMG: $dmg_file"
    log "   Size: $(numfmt --to=iec $DMG_SIZE)"
    log "   Appcast: $APPCAST_URL"
    log "   Download: $RELEASES_BASE_URL/$dmg_file"
    echo
    warning "📱 Users will receive automatic updates within 1 hour!"
    log "🔍 Monitor update adoption at: $APPCAST_URL"
}

# Run main function
main "$@"