import Foundation
import Combine
import Supabase

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
        
        do {
            let response = try await supabase.auth.signIn(email: email, password: password)
            print("✅ Sign in successful!")
            // Auth listener will handle the state update
        } catch {
            print("❌ Sign in error: \(error)")
            errorMessage = error.localizedDescription
        }
        
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
        Task {
            for await (event, session) in supabase.auth.authStateChanges {
                await MainActor.run {
                    handleAuthStateChange(event: event, session: session)
                }
            }
        }
    }
    
    private func handleAuthStateChange(event: AuthChangeEvent, session: Session?) {
        print("🔄 Auth state changed: \(event)")
        print("🔄 Current isAuthenticated: \(isAuthenticated)")
        
        switch event {
        case .signedIn:
            if let user = session?.user {
                print("✅ User signed in: \(user.email ?? "unknown")")
                print("🔄 Setting currentUser and isAuthenticated = true")
                currentUser = user
                isAuthenticated = true
                print("✅ Updated isAuthenticated: \(isAuthenticated)")
            }
        case .signedOut:
            print("👋 User signed out")
            print("🔄 Setting currentUser = nil and isAuthenticated = false")
            currentUser = nil
            isAuthenticated = false
            print("✅ Updated isAuthenticated: \(isAuthenticated)")
        case .tokenRefreshed:
            print("🔄 Token refreshed")
            if let user = session?.user {
                currentUser = user
                isAuthenticated = true
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
                }
            } catch {
                print("No existing session found")
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