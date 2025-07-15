# Sparkle Auto-Update Setup Guide

## 🔑 Your Generated Keys

**Private Key (KEEP SECRET!):**
```
pBCGm80Eiudx3ah9/Y76h6gZCHRKu+xgFEyKCeoYh98=
```

**Public Key (already added to Info.plist):**
```
sdg1G+uHbxfMXRV3kbTcvSlpekeSDJK3AkRGryuwqVQ=
```

## 🔔 Automatic Update Behavior

Your app is now configured for **fully automatic updates** with notifications:

- **Checks every hour** for new updates automatically
- **Downloads updates** in the background without user intervention  
- **Shows notification** when installing: "PromiseKeeper is being updated to version X.X.X..."
- **Shows notification** when complete: "PromiseKeeper has been updated to version X.X.X!"
- **No user interaction required** - updates happen seamlessly

## 📋 Complete Setup Checklist

### ✅ Already Done
- [x] Added Sparkle framework to Xcode project
- [x] Configured app delegate with SPUStandardUpdaterController
- [x] Updated Info.plist with public key and settings
- [x] Created UpdateCommands.swift for "Check for Updates" menu
- [x] Generated signing keys

### 📝 What You Need to Do Next

#### 1. ✅ Domain Already Configured

Your Info.plist is already set to use:
```xml
<key>SUFeedURL</key>
<string>https://anaygupta2004.github.io/src/appcast.xml</string>
```

#### 2. Set Up GitHub Pages Hosting

You need to create a GitHub repository structure like this:
```
your-github-repo/
├── src/
│   ├── appcast.xml           # Upload the appcast.xml here
│   └── releases/
│       ├── PromiseKeeper-1.0.0.dmg
│       ├── PromiseKeeper-1.1.0.dmg
│       └── ...
```

Upload `appcast.xml` to `https://github.com/anaygupta2004/[your-repo]/src/` and enable GitHub Pages.

#### 3. Build and Test

1. Build your app in Xcode
2. The "Check for Updates..." menu item should appear under the app menu
3. Test that it can reach your appcast URL (it will show "no updates" initially)

#### 4. Creating Your First Release

When you're ready to release version 1.1.0:

1. **Build and export your app** as a .dmg or .zip file

2. **Sign the release** using the provided script:
   ```bash
   swift sign_release.swift 'pBCGm80Eiudx3ah9/Y76h6gZCHRKu+xgFEyKCeoYh98=' '/path/to/YourApp.dmg'
   ```

3. **Update appcast.xml** with the new version info and signature:
   ```xml
   <item>
      <title>Version 1.1.0</title>
      <description><![CDATA[
         <h2>What's New in Version 1.1.0</h2>
         <ul>
            <li>Added automatic update support</li>
            <li>Bug fixes and improvements</li>
         </ul>
      ]]></description>
      <pubDate>Mon, 13 Jul 2025 12:00:00 +0000</pubDate>
      <sparkle:version>1.1.0</sparkle:version>
      <sparkle:shortVersionString>1.1.0</sparkle:shortVersionString>
      <sparkle:minimumSystemVersion>14.0</sparkle:minimumSystemVersion>
      <enclosure 
         url="https://anaygupta2004.github.io/src/releases/PromiseKeeper-1.1.0.dmg"
         length="50000000" 
         type="application/octet-stream"
         sparkle:edSignature="[SIGNATURE_FROM_SCRIPT]" />
   </item>
   ```

4. **Upload both files** (app and updated appcast.xml) to your server

## 🔐 Security Notes

- **NEVER commit the private key to git**
- Store the private key securely (password manager, encrypted file, etc.)
- Only use the private key on trusted machines for signing releases
- The public key in Info.plist is safe to commit

## 🧪 Testing Updates

To test the update system:

1. Build version 1.0.0 of your app
2. Install and run it
3. Create a new version (1.0.1) with the appcast pointing to it
4. Use "Check for Updates..." - it should detect and offer the new version

## 📁 File Structure

```
your-web-server/
├── appcast.xml                    # Update feed
└── releases/
    ├── PromiseKeeper-1.0.0.dmg   # Initial release
    ├── PromiseKeeper-1.0.1.dmg   # Update 1
    └── PromiseKeeper-1.1.0.dmg   # Update 2
```

## 🎯 Next Steps

1. Replace `https://your-domain.com` in Info.plist with your actual domain
2. Set up web hosting for appcast.xml and release files  
3. Build and test the app with update checking
4. Create your first signed release when ready

Your Sparkle auto-update system is now ready! 🚀