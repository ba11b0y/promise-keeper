# 🚀 PromiseKeeper Release Automation Guide

## Overview

This guide covers the complete automated workflow for building, distributing, and updating PromiseKeeper using two powerful bash scripts:

1. **`build_and_export_dmg.sh`** - Builds, archives, and creates distributable DMG
2. **`send_update_to_users.sh`** - Signs, uploads, and distributes updates to users

## 📋 Prerequisites

Before using the automation scripts, ensure you have:

- ✅ Xcode with command line tools installed
- ✅ Valid Apple Developer account and certificates
- ✅ Git configured with GitHub access
- ✅ Python 3 installed (for XML processing)
- ✅ GitHub repository set up for hosting releases

## 📁 File Structure

```
promise-keeper/
├── build_and_export_dmg.sh        # Script 1: Build & Export
├── send_update_to_users.sh        # Script 2: Distribute Updates
├── mac-app/                       # Xcode project directory
├── releases/                      # Generated DMG files
├── build/                         # Temporary build files
├── export/                        # Exported app files
└── dmg/                          # DMG creation workspace
```

## 🔨 Script 1: Build and Export DMG

### Purpose
Automates the complete build process from source code to distributable DMG file.

### Usage
```bash
./build_and_export_dmg.sh <version> [build_number]
```

### Examples
```bash
# Initial release
./build_and_export_dmg.sh 0.1.0 1

# Subsequent releases
./build_and_export_dmg.sh 0.2.0 2
./build_and_export_dmg.sh 1.0.0 20250715

# Auto-generate build number
./build_and_export_dmg.sh 0.1.1
```

### What it does:
1. **Validates** version format (X.Y.Z)
2. **Updates** Info.plist with new version numbers
3. **Cleans** previous build artifacts
4. **Builds** and archives the Xcode project
5. **Exports** the app with proper code signing
6. **Verifies** code signing and certificates
7. **Creates** professional DMG with Applications symlink
8. **Generates** metadata file for update script
9. **Validates** final DMG integrity

### Outputs:
- `releases/PromiseKeeper-X.Y.Z.dmg` - Distributable DMG
- `releases/PromiseKeeper-X.Y.Z.info` - Metadata for update script
- `build/build.log` - Detailed build logs
- `build/export.log` - Export process logs

## 📤 Script 2: Send Update to Users

### Purpose
Automates the complete update distribution process with Sparkle auto-updates.

### Usage
```bash
./send_update_to_users.sh <dmg_name> [release_notes_file]
```

### Examples
```bash
# Basic update distribution
./send_update_to_users.sh PromiseKeeper-0.1.0

# With custom release notes
./send_update_to_users.sh PromiseKeeper-0.2.0 ./release_notes.md

# Major version update
./send_update_to_users.sh PromiseKeeper-1.0.0 ./v1_release_notes.md
```

### What it does:
1. **Validates** DMG file exists and format is correct
2. **Signs** DMG with Sparkle ED25519 private key
3. **Downloads** current appcast.xml from GitHub Pages
4. **Updates** appcast.xml with new version entry
5. **Uploads** DMG to GitHub Pages releases directory
6. **Commits** and pushes changes to GitHub repository
7. **Verifies** deployment accessibility and integrity
8. **Confirms** automatic update distribution

### Outputs:
- Updated `appcast.xml` on GitHub Pages
- DMG uploaded to GitHub Pages releases
- Git commit with release information
- Verification of live deployment

## 🔄 Complete Release Workflow

### For Initial Release (0.1.0):

```bash
# Step 1: Build and create DMG
./build_and_export_dmg.sh 0.1.0 1

# Step 2: Test the DMG locally
open releases/PromiseKeeper-0.1.0.dmg

# Step 3: Distribute to users
./send_update_to_users.sh PromiseKeeper-0.1.0
```

### For Subsequent Updates:

```bash
# Step 1: Build new version
./build_and_export_dmg.sh 0.2.0

# Step 2: Create release notes (optional)
echo "<h2>New Features</h2><ul><li>Added dark mode</li><li>Performance improvements</li></ul>" > release_notes.md

# Step 3: Distribute update
./send_update_to_users.sh PromiseKeeper-0.2.0 release_notes.md
```

## 📝 Release Notes Format

Create `release_notes.md` files in HTML format:

```html
<h2>What's New in Version 0.2.0</h2>
<ul>
   <li>🌙 Added dark mode support</li>
   <li>⚡ Improved app startup time by 50%</li>
   <li>🐛 Fixed issue with promise notifications</li>
   <li>🔧 Enhanced settings interface</li>
</ul>

<h3>Technical Improvements</h3>
<ul>
   <li>Updated to latest Sparkle framework</li>
   <li>Improved memory management</li>
   <li>Enhanced error handling</li>
</ul>
```

## 🔐 Security Configuration

Both scripts use the pre-configured Sparkle signing key:

- **Private Key**: `pBCGm80Eiudx3ah9/Y76h6gZCHRKu+xgFEyKCeoYh98=` (embedded securely)
- **Public Key**: Already in Info.plist
- **GitHub Repository**: `anaygupta2004.github.io`
- **Appcast URL**: `https://anaygupta2004.github.io/src/appcast.xml`

## 🚨 Error Handling

Both scripts include comprehensive error handling:

- **Build failures** - Detailed logs in `build/` directory
- **Code signing issues** - Automatic verification
- **Network problems** - Retry mechanisms for uploads
- **GitHub API errors** - Clear error messages
- **DMG corruption** - Integrity verification

## 📊 Monitoring Updates

After running the distribution script:

1. **Check GitHub Pages**: Verify files uploaded correctly
2. **Test appcast**: Visit `https://anaygupta2004.github.io/src/appcast.xml`
3. **Monitor adoption**: Users receive updates within 1 hour
4. **Check logs**: Build logs saved for troubleshooting

## 🎯 User Update Experience

When you run `send_update_to_users.sh`:

1. **Within 1 hour**: All users automatically receive the update
2. **Silent download**: Update downloads in background
3. **Notification shown**: "PromiseKeeper is being updated to version X.Y.Z..."
4. **Automatic restart**: App restarts with new version
5. **Completion notice**: "PromiseKeeper has been updated to version X.Y.Z!"

## 🔧 Troubleshooting

### Build Script Issues:
```bash
# Check build logs
cat build/build.log

# Verify Xcode project
xcodebuild -list -project mac-app/PromiseKeeper.xcodeproj

# Test code signing
codesign -v releases/PromiseKeeper-X.Y.Z.dmg
```

### Distribution Script Issues:
```bash
# Test GitHub connectivity
curl -I https://anaygupta2004.github.io/src/appcast.xml

# Verify DMG signature manually
swift generate_sparkle_keys.swift

# Check GitHub Pages deployment
git log --oneline -10
```

## 🎉 Success Indicators

### Build Script Success:
- ✅ DMG created in `releases/` directory
- ✅ Code signing verification passes
- ✅ Info file generated with metadata
- ✅ No errors in build logs

### Distribution Script Success:
- ✅ DMG signed with valid Sparkle signature
- ✅ Appcast.xml updated with new version
- ✅ Files uploaded to GitHub Pages
- ✅ Deployment verification passes
- ✅ Users will receive automatic updates

## 📈 Version Management

Follow semantic versioning:
- **0.1.0** - Initial release
- **0.1.1** - Bug fixes
- **0.2.0** - New features
- **1.0.0** - Major release

The scripts automatically handle version updates in:
- Info.plist files
- Appcast.xml entries
- DMG naming
- Git commit messages

---

🚀 **Your automated release pipeline is ready!** These scripts provide a production-ready workflow for distributing PromiseKeeper updates to users with zero manual intervention required.