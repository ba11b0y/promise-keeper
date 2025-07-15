# Promise Keeper Code Signing Guide

## Current Status

You currently have an **Apple Development** certificate installed, which is suitable for:
- Local development and testing
- Distribution to known testers via direct installation
- Running the app on your own machine

## For Public Distribution

To distribute Promise Keeper publicly (outside the Mac App Store), you need a **Developer ID Application** certificate.

### How to Get a Developer ID Certificate

1. **Enroll in Apple Developer Program** ($99/year)
   - Go to [developer.apple.com](https://developer.apple.com)
   - Sign in with your Apple ID
   - Enroll in the Apple Developer Program

2. **Create Developer ID Certificate**
   - Open Xcode
   - Go to Xcode → Settings → Accounts
   - Select your Apple ID
   - Click "Manage Certificates"
   - Click the "+" button and choose "Developer ID Application"

3. **Alternative: Use Xcode's Automatic Signing**
   - Open the project in Xcode
   - Select the project in the navigator
   - Go to "Signing & Capabilities"
   - Ensure "Automatically manage signing" is checked
   - Xcode will create certificates as needed

## Building Promise Keeper

### For Development/Testing

Use the development build script:
```bash
./build_and_export_dev.sh
```

This creates a DMG that:
- Can be run on any Mac
- May show security warnings on first launch
- Users need to right-click and select "Open" to bypass Gatekeeper

### For Distribution (requires Developer ID)

Use the main build script:
```bash
./build_and_export_dmg.sh
```

This will only work once you have a Developer ID certificate.

## Current Configuration

- **App Name**: Promise Keeper
- **Bundle ID**: com.example.mac.PromiseKeeper
- **Team ID**: TX645N2QBW
- **Development Certificate**: ✅ Available
- **Developer ID Certificate**: ❌ Not Available

## Troubleshooting

### "Unidentified Developer" Warning

If users see this when opening the app:
1. They can right-click the app and choose "Open"
2. Or go to System Settings → Privacy & Security and click "Open Anyway"

### Certificate Issues

Check available certificates:
```bash
security find-identity -v -p codesigning
```

### Notarization (Future)

For the best user experience, apps should be notarized by Apple. This requires:
1. Developer ID certificate
2. Submitting the app to Apple for automated security checks
3. Stapling the notarization ticket to the DMG

The `send_update_to_users.sh` script handles notarization automatically.

## Next Steps

1. **For Testing**: Use `build_and_export_dev.sh` to create development builds
2. **For Distribution**: 
   - Enroll in Apple Developer Program
   - Create Developer ID certificate
   - Use `build_and_export_dmg.sh` for release builds
   - Consider notarization for the best user experience