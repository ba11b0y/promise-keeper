# Getting Your Developer ID Application Certificate

Since you're already enrolled in the Apple Developer Program, follow these steps:

## Method 1: Using Xcode (Recommended)

1. **Open Xcode**
2. **Go to Xcode → Settings** (or Xcode → Preferences on older versions)
3. **Click on Accounts tab**
4. **Select your Apple ID** that's enrolled in the Developer Program
5. **Click "Manage Certificates..."** button
6. **Click the "+" button** in the bottom left
7. **Select "Developer ID Application"** from the dropdown
8. **Xcode will create and download the certificate automatically**

## Method 2: Using Apple Developer Portal

1. **Go to** [developer.apple.com/account](https://developer.apple.com/account)
2. **Sign in** with your Apple ID
3. **Navigate to** Certificates, Identifiers & Profiles
4. **Click on Certificates**
5. **Click the "+" button** to create a new certificate
6. **Select "Developer ID" → "Developer ID Application"**
7. **Follow the instructions** to create a Certificate Signing Request (CSR)
8. **Upload the CSR** and download your certificate
9. **Double-click** the downloaded certificate to install it in Keychain

## Verify Your Certificate

After installation, verify it's properly installed:

```bash
security find-identity -v -p codesigning | grep "Developer ID"
```

You should see something like:
```
1) XXXXXXXXXX "Developer ID Application: Your Name (TEAMID)"
```

## Important Notes

- **Developer ID certificates are valid for 5 years**
- **Keep your private key safe** - back it up!
- **You can have multiple Developer ID certificates**
- **This certificate is for distribution outside the Mac App Store**

## Next Steps

Once you have your Developer ID certificate:
1. Run `./build_and_export_dmg.sh` (not the dev version)
2. The app will be properly signed for distribution
3. Consider notarizing for the best user experience

## Troubleshooting

If you don't see the Developer ID option:
- Make sure your Apple Developer account is properly set up
- Check that you've accepted all agreements at developer.apple.com
- Ensure your account has the proper permissions (Account Holder or Admin role)