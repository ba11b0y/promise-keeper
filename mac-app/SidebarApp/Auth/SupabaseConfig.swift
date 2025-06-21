import Foundation

struct SupabaseConfig {
    // MARK: - Configuration
    // Your actual Supabase project values (these are public, not secret)
    static let supabaseURL = "https://msucqyacicicjkakvurq.supabase.co"
    static let supabaseAnonKey = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zdWNxeWFjaWNpY2prYWt2dXJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjcyMDgsImV4cCI6MjA2NjEwMzIwOH0.dqV_-pUx8yJbyv2m1c-O5syFoKERKLEF0bDimtv0lro"
    
    // MARK: - Instructions
    /*
     To set up Supabase authentication:
     
     1. Go to https://supabase.com and create a new project
     2. In your Supabase dashboard, go to Settings > API
     3. Copy your Project URL and replace `supabaseURL` above
     4. Copy your anon/public key and replace `supabaseAnonKey` above
     5. In your Supabase dashboard, go to Authentication > Settings
     6. Make sure "Enable email confirmations" is turned OFF for testing
        (or set up email templates if you want email confirmation)
     7. Under "Auth Providers", make sure "Email" is enabled
     
     Optional: Set up Row Level Security (RLS) policies in your database
     to secure your data based on authenticated users.
     */
} 