import Foundation
import Combine
import Supabase
import WidgetKit

// Note: WidgetDataSyncManager is in the Managers folder

// MARK: - Supabase Manager
@MainActor
class SupabaseManager: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: Supabase.User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabase: SupabaseClient
    
    // Shared instance
    static let shared = SupabaseManager()
    
    private init() {
        // Load configuration from environment (supports .env files and Xcode env vars)
        let supabaseURL = EnvironmentConfig.supabaseURL
        let supabaseKey = EnvironmentConfig.supabaseAnonKey
        
        // Debug: Print configuration source
        #if DEBUG
        EnvironmentConfig.printConfiguration()
        #endif
        
        // Initialize the official Supabase client
        self.supabase = SupabaseClient(
            supabaseURL: URL(string: supabaseURL)!,
            supabaseKey: supabaseKey
        )
        
        // Check if user is already logged in and listen to auth changes
        setupAuthListener()
        checkInitialSession()
    }
    
    // MARK: - Authentication Methods
    
    func signUp(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        print("🔐 Attempting sign up for: \(email)")
        
        do {
            let response = try await supabase.auth.signUp(email: email, password: password)
            print("✅ Sign up successful!")
            // Auth listener will handle the state update
        } catch {
            print("❌ Sign up error: \(error)")
            errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
    
    func signIn(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        print("🔐 Attempting sign in for: \(email)")
        NSLog("🔐 Attempting sign in for: \(email)")
        
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            print("✅ Sign in successful!")
            NSLog("✅ Sign in successful!")
            print("✅ Response: \(response)")
            NSLog("✅ Response: \(response)")
            // Auth listener will handle the state update
        } catch {
            print("❌ Sign in error: \(error)")
            NSLog("❌ Sign in error: \(error)")
            print("❌ Error details: \(error.localizedDescription)")
            NSLog("❌ Error details: \(error.localizedDescription)")
            if let supabaseError = error as? AuthError {
                print("❌ Supabase auth error: \(supabaseError)")
                NSLog("❌ Supabase auth error: \(supabaseError)")
            }
            errorMessage = error.localizedDescription
        }
        
        print("🔐 Sign in completed, isLoading = false")
        NSLog("🔐 Sign in completed, isLoading = false")
        isLoading = false
    }
    
    func signOut() async {
        do {
            try await supabase.auth.signOut()
            print("✅ Sign out successful!")
            // Auth listener will handle the state update
        } catch {
            print("❌ Sign out error: \(error)")
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Private Methods
    
    private func setupAuthListener() {
        print("🎧 Setting up auth listener...")
        NSLog("🎧 Setting up auth listener...")
        Task {
            print("🎧 Starting auth state change listener task")
            NSLog("🎧 Starting auth state change listener task")
            for await (event, session) in supabase.auth.authStateChanges {
                print("🎧 Auth event received: \(event)")
                NSLog("🎧 Auth event received: \(event)")
                await MainActor.run {
                    handleAuthStateChange(event: event, session: session)
                }
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
        print("🔄 Auth state changed: \(event)")
        NSLog("🔄 Auth state changed: \(event)")
        print("🔄 Current isAuthenticated: \(isAuthenticated)")
        NSLog("🔄 Current isAuthenticated: \(isAuthenticated)")
        
        switch event {
        case .signedIn:
            if let user = session?.user, let session = session {
                print("✅ User signed in: \(user.email ?? "unknown")")
                print("🔄 Setting currentUser and isAuthenticated = true")
                currentUser = user
                isAuthenticated = true
                print("✅ Updated isAuthenticated: \(isAuthenticated)")
                
                // Store session data in Keychain for widget access
                // Convert expiresAt from TimeInterval to Date
                let expiryDate = Date(timeIntervalSince1970: session.expiresAt)
                SharedSupabaseManager.storeSessionData(
                    userId: user.id.uuidString,
                    email: user.email,
                    expiresAt: expiryDate
                )
                
                // Sync authentication state with widget
                print("🔐 SupabaseManager: Updating widget auth state to TRUE for user \(user.email ?? "unknown")")
                UnifiedSharedDataManager.shared.updateAuthState(
                    userId: user.id.uuidString,
                    userEmail: user.email,
                    isAuthenticated: true
                )
                print("📱 Shared authentication state and session with widget")
                NSLog("📱 Shared authentication state and session with widget")

                // Immediately fetch and sync promises to the widget now that we are authenticated
                Task {
                    await PromiseManager.shared.refreshPromises()
                    // Force-refresh widget after promises are synced
                    WidgetCenter.shared.reloadAllTimelines()
                }

                // Debug the authentication flow
                #if DEBUG
                print("🔍 DEBUG: Auth flow completed for user: \(user.id.uuidString)")
                // To use advanced debugging, add WidgetDebugView to your app
                #endif
            }
        case .signedOut:
            print("👋 User signed out")
            print("🔄 Setting currentUser = nil and isAuthenticated = false")
            currentUser = nil
            isAuthenticated = false
            print("✅ Updated isAuthenticated: \(isAuthenticated)")
            
            // Clear the session from Keychain
            SharedSupabaseManager.clearSession()
            
            // Clear widget data
            UnifiedSharedDataManager.shared.clear()
            print("📱 Cleared session and shared signed-out state with widget")
            WidgetCenter.shared.reloadAllTimelines()
        case .tokenRefreshed:
            print("🔄 Token refreshed")
            if let user = session?.user, let session = session {
                currentUser = user
                isAuthenticated = true
                
                // Update session data in Keychain with refreshed token
                // Convert expiresAt from TimeInterval to Date
                let expiryDate = Date(timeIntervalSince1970: session.expiresAt)
                SharedSupabaseManager.storeSessionData(
                    userId: user.id.uuidString,
                    email: user.email,
                    expiresAt: expiryDate
                )
                
                // Also update SharedDataManager for backwards compatibility
                SharedDataManager.shared.storeUserInfo(userId: user.id.uuidString, isAuthenticated: true)
                print("📱 Shared refreshed auth state and session with widget")
                WidgetCenter.shared.reloadAllTimelines()
            }
        default:
            break
        }
    }
    
    private func checkInitialSession() {
        Task {
            do {
                let session = try await supabase.auth.session
                await MainActor.run {
                    let user = session.user
                    print("✅ Found existing session for: \(user.email ?? "unknown")")
                    currentUser = user
                    isAuthenticated = true
                    
                    // Store session data in Keychain for widget access
                    // Convert expiresAt from TimeInterval to Date
                    let expiryDate = Date(timeIntervalSince1970: session.expiresAt)
                    SharedSupabaseManager.storeSessionData(
                        userId: user.id.uuidString,
                        email: user.email,
                        expiresAt: expiryDate
                    )
                    
                    // Also update SharedDataManager for backwards compatibility
                    SharedDataManager.shared.storeUserInfo(userId: user.id.uuidString, isAuthenticated: true)
                    print("📱 Shared initial auth state and session with widget")
                }
            } catch {
                print("No existing session found")
                await MainActor.run {
                    // Clear any stale session from Keychain
                    SharedSupabaseManager.clearSession()
                    
                    // Share unauthenticated state with widget
                    SharedDataManager.shared.storeUserInfo(userId: nil, isAuthenticated: false)
                    print("📱 Shared unauthenticated state with widget")
                }
            }
        }
    }
    
    // MARK: - Database Access
    
    /// Get the Supabase client for database operations
    var client: SupabaseClient {
        return supabase
    }
    
    // MARK: - Convenience Database Methods
    
    /// Example: Fetch data from a table
    func fetchData<T: Codable>(from table: String, type: T.Type) async throws -> [T] {
        let response: [T] = try await supabase
            .from(table)
            .select()
            .execute()
            .value
        return response
    }
    
    /// Example: Insert data into a table
    func insertData<T: Codable>(_ data: T, into table: String) async throws -> T {
        let response: T = try await supabase
            .from(table)
            .insert(data)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    /// Example: Update data in a table
    func updateData<T: Codable, V: PostgrestFilterValue>(_ data: T, in table: String, where condition: String, equals value: V) async throws -> T {
        let response: T = try await supabase
            .from(table)
            .update(data)
            .eq(condition, value: value)
            .select()
            .single()
            .execute()
            .value
        return response
    }
    
    /// Example: Delete data from a table
    func deleteData<V: PostgrestFilterValue>(from table: String, where condition: String, equals value: V) async throws {
        try await supabase
            .from(table)
            .delete()
            .eq(condition, value: value)
            .execute()
    }
} 