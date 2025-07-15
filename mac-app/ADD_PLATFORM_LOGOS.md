# Adding Platform Logos to PromiseKeeper

## 1. Download Platform Logos

Download high-quality logos (preferably SVG or PNG with transparent background) for each platform:

- **Slack**: https://brandfolder.com/slack/logos
- **Discord**: https://discord.com/branding
- **Zoom**: https://brand.zoom.us/media-library
- **Microsoft Teams**: https://developer.microsoft.com/en-us/microsoft-teams/app-icons
- **WhatsApp**: https://www.whatsapp.com/brand
- **Telegram**: https://telegram.org/brand
- **Signal**: https://signal.org/brand/
- **Gmail**: Use Google's Material Icons
- **Outlook**: Microsoft brand center
- **Google Meet**: Google brand center
- **Facebook Messenger**: https://www.facebookbrand.com/
- **Instagram**: https://www.facebookbrand.com/instagram
- **Twitter/X**: https://about.twitter.com/en/who-we-are/brand-toolkit
- **LinkedIn**: https://brand.linkedin.com/

## 2. Prepare the Images

1. Convert SVGs to PDFs for better scaling in Xcode:
   ```bash
   # Using Inkscape or similar tool
   inkscape -z -e slack-logo.pdf slack-logo.svg
   ```

2. Or prepare PNG versions at multiple resolutions:
   - 1x: 24x24px
   - 2x: 48x48px
   - 3x: 72x72px

## 3. Add to Xcode Project

1. Open `PromiseKeeper.xcodeproj` in Xcode
2. Navigate to `Assets.xcassets`
3. Create a new folder called "PlatformLogos"
4. For each platform logo:
   - Right-click in the folder → "New Image Set"
   - Name it exactly as referenced in `PlatformLogo.swift`:
     - `slack-logo`
     - `discord-logo`
     - `zoom-logo`
     - `teams-logo`
     - `whatsapp-logo`
     - `telegram-logo`
     - `signal-logo`
     - `gmail-logo`
     - `outlook-logo`
     - `google-meet-logo`
     - `messenger-logo`
     - `instagram-logo`
     - `twitter-logo`
     - `x-logo`
     - `linkedin-logo`
   - Drag the appropriate resolution images to 1x, 2x, 3x slots
   - Or drag the PDF to the "Universal" slot

## 4. Make Logos Available to Widget Extension

1. Select each logo image set in Assets.xcassets
2. In the File Inspector (right panel), under "Target Membership"
3. Check both:
   - ✅ PromiseKeeper
   - ✅ PromiseWidgetExtension

## 5. Update Widget Code (Optional)

If you want the widget to also use actual logos, copy `PlatformLogo.swift` to the widget extension:

1. Right-click on `PromiseWidget` folder
2. Add Files to "PromiseKeeper"...
3. Select `PlatformLogo.swift`
4. Make sure "PromiseWidgetExtension" is checked as target
5. Update `PromiseWidget.swift` to use `PlatformLogo` view instead of SF Symbols

## 6. Test

1. Build and run the app
2. Create test promises with different platforms
3. Verify logos appear correctly in:
   - Main promise list
   - Compact view
   - Modern view
   - Widget (if updated)

## Logo Guidelines

- Use official brand colors when possible
- Maintain aspect ratios
- Use transparent backgrounds
- Consider dark mode compatibility
- Follow each platform's brand guidelines for sizing and spacing

## Fallback Behavior

The `PlatformLogo` component will automatically fall back to SF Symbols if a custom logo isn't found, so the app will still work even if some logos are missing.