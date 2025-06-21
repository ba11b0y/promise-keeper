# Supabase Authentication Setup

This guide will help you set up Supabase authentication in your macOS app.

## Files Added

The following authentication files have been created:

```
SidebarApp/Auth/
├── SupabaseConfig.swift       # Configuration file for Supabase credentials
├── SupabaseManager.swift      # Main authentication manager
├── AuthView.swift            # Login/Register UI
├── AuthenticatedView.swift   # Wrapper view for authenticated content
└── UserProfileView.swift     # User profile display
```

## Supabase Project Setup

1. **Create a Supabase Project**
   - Go to [https://supabase.com](https://supabase.com)
   - Click "New Project"
   - Choose your organization and create a new project
   - Wait for the project to be set up

2. **Get Your Project Credentials**
   - In your Supabase dashboard, go to **Settings > API**
   - Copy your **Project URL** 
   - Copy your **anon/public key**

3. **Configure Authentication**
   - Go to **Authentication > Settings**
   - Make sure **"Enable email confirmations"** is turned **OFF** for testing
   - Under **"Auth Providers"**, ensure **"Email"** is enabled

## Xcode Project Setup

1. **Add Files to Xcode**
   - In Xcode, right-click on the `SidebarApp` folder
   - Choose "Add Files to 'SidebarApp'"
   - Navigate to the `Auth` folder and select all Swift files
   - Make sure "Add to target: SidebarApp" is checked

2. **Update Configuration**
   - Open `Auth/SupabaseConfig.swift`
   - Replace `"https://your-project-ref.supabase.co"` with your Project URL
   - Replace `"your-anon-key-here"` with your anon/public key

## How It Works

### Authentication Flow
- The app starts with `AuthenticatedView` wrapper
- If not authenticated, shows login/register screen
- Once authenticated, shows the main app interface
- User info is displayed in the sidebar footer
- Profile view accessible from sidebar

### Key Components

**SupabaseManager**: 
- Handles all authentication logic
- Manages user session persistence
- Provides methods for API calls with auth headers

**AuthView**: 
- Beautiful login/register interface
- Form validation and error handling
- Smooth animations between states

**UserProfileView**: 
- Shows current user information
- Sign out functionality

## Usage Examples

### Making Authenticated API Calls

```swift
// In any view with access to SupabaseManager
@EnvironmentObject var supabaseManager: SupabaseManager

// Make authenticated requests
Task {
    do {
        let data = try await supabaseManager.makeAuthenticatedRequest(
            to: "your_table_name",
            method: "GET"
        )
        // Handle response data
    } catch {
        print("API Error: \(error)")
    }
}
```

### Accessing User Information

```swift
// Current user
if let user = supabaseManager.currentUser {
    Text("Welcome, \(user.email)")
}

// Authentication state
if supabaseManager.isAuthenticated {
    // Show authenticated content
} else {
    // Show login screen
}
```

## Customization

### Styling
- Modify button styles in `AuthView.swift`
- Update colors and fonts to match your app theme
- Customize the user profile display

### Additional Features
- Add password reset functionality
- Implement social login providers
- Add user profile editing
- Set up real-time subscriptions

## Security Notes

1. **Never commit your Supabase keys to version control**
2. Consider using environment variables for production
3. Set up Row Level Security (RLS) policies in Supabase
4. Validate user permissions on the server side

## Troubleshooting

**Build Errors**: Make sure all auth files are added to the Xcode target

**Login Fails**: Check your Supabase URL and keys in `SupabaseConfig.swift`

**Email Confirmation**: Disable email confirmations in Supabase for testing

**Network Issues**: Ensure your app has network permissions in the entitlements file

## Next Steps

1. Set up your Supabase project
2. Add the auth files to Xcode
3. Update the configuration
4. Build and test the authentication flow
5. Customize the UI to match your app's design
6. Add any additional authentication features you need

The authentication system is now ready to use! Users can sign up, sign in, and access authenticated content in your app. 