import Foundation
import Security
import WidgetKit
import LocalAuthentication

/// Shared Supabase Manager for both main app and widget
/// Uses Keychain to securely share the Supabase session between app and widget
public struct SharedSupabaseManager {
    
    // MARK: - Constants
    
    /// Keychain access group - must match in entitlements
    /// Format: <TeamID>.<BundleID> (without "group." prefix for Keychain)
    private static let keychainAccessGroup = "TX645N2QBW.com.example.mac.PromiseKeeper"
    
    /// Request keychain permission proactively
    public static func requestKeychainPermission() {
        print("🔑 Requesting keychain permission...")
        // Try to store a test value to trigger permission dialog
        let testData = "test".data(using: .utf8)!
        _ = storeInKeychain(data: testData, forKey: "promise_keeper_keychain_test")
        // Clean up test value
        _ = deleteFromKeychain(key: "promise_keeper_keychain_test")
    }
    
    /// Keychain keys
    private struct KeychainKeys {
        static let supabaseSession = "supabase_session"
        static let sessionExpiry = "supabase_session_expiry"
        static let userEmail = "supabase_user_email"
        static let accessToken = "supabase_access_token"
    }
    
    // MARK: - Session Storage
    
    /// Store the session data in Keychain for widget access
    /// This is used by the main app after successful authentication
    public static func storeSessionData(userId: String, email: String?, expiresAt: Date?, accessToken: String?) {
        // Store user ID
        if let userIdData = userId.data(using: .utf8) {
            _ = storeInKeychain(data: userIdData, forKey: "supabase_user_id")
        }
        
        // Store email if available
        if let email = email, let emailData = email.data(using: .utf8) {
            _ = storeInKeychain(data: emailData, forKey: KeychainKeys.userEmail)
        }
        
        // Store expiry time if available
        if let expiresAt = expiresAt {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let expiryData = try? encoder.encode(expiresAt) {
                _ = storeInKeychain(data: expiryData, forKey: KeychainKeys.sessionExpiry)
            }
        }
        
        // Store access token if available
        if let accessToken = accessToken, let tokenData = accessToken.data(using: .utf8) {
            _ = storeInKeychain(data: tokenData, forKey: KeychainKeys.accessToken)
        }
        
        // Mark session as valid
        _ = storeInKeychain(data: "true".data(using: .utf8)!, forKey: KeychainKeys.supabaseSession)
        
        print("✅ Session data stored in Keychain")
        
        // Notify widget to reload
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    /// Clear the stored session (on sign out)
    public static func clearSession() {
        _ = deleteFromKeychain(key: KeychainKeys.supabaseSession)
        _ = deleteFromKeychain(key: KeychainKeys.sessionExpiry)
        _ = deleteFromKeychain(key: KeychainKeys.userEmail)
        _ = deleteFromKeychain(key: KeychainKeys.accessToken)
        _ = deleteFromKeychain(key: "supabase_user_id")
        
        print("🗑️ Cleared Supabase session from Keychain")
        
        // Notify widget to reload
        DispatchQueue.main.async {
            WidgetCenter.shared.reloadAllTimelines()
        }
    }
    
    // MARK: - Session Retrieval
    
    /// Check if we have a valid session stored
    private static func hasValidSession() -> Bool {
        // Check if session marker exists
        guard let sessionData = loadFromKeychain(key: KeychainKeys.supabaseSession),
              String(data: sessionData, encoding: .utf8) == "true" else {
            print("📱 No Supabase session found in Keychain")
            return false
        }
        
        // Check if session is expired
        if let expiryData = loadFromKeychain(key: KeychainKeys.sessionExpiry) {
            do {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                let expiryDate = try decoder.decode(Date.self, from: expiryData)
                
                if expiryDate < Date() {
                    print("⚠️ Stored session is expired")
                    return false
                }
            } catch {
                print("❌ Error checking session expiry: \(error)")
            }
        }
        
        print("✅ Found valid session in Keychain")
        return true
    }
    
    /// Get access token for widget use
    public static func getAccessTokenForWidget() -> String? {
        // First check if session is valid (not expired)
        guard hasValidSession() else {
            print("⚠️ Session is expired or invalid, cannot return access token")
            return nil
        }
        
        // Get access token
        if let tokenData = loadFromKeychain(key: KeychainKeys.accessToken) {
            return String(data: tokenData, encoding: .utf8)
        }
        
        return nil
    }
    
    /// Check if user is authenticated (quick check without creating client)
    public static var isAuthenticated: Bool {
        return hasValidSession()
    }
    
    /// Get stored user email (quick access without decoding full session)
    public static var userEmail: String? {
        guard let emailData = loadFromKeychain(key: KeychainKeys.userEmail),
              let email = String(data: emailData, encoding: .utf8) else {
            return nil
        }
        return email
    }
    
    // MARK: - Keychain Helpers
    
    private static func storeInKeychain(data: Data, forKey key: String) -> Bool {
        // First attempt: Try with most restrictive settings
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock,
            // Prompt user for keychain access if needed
            kSecUseAuthenticationContext as String: LAContext()
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        var status = SecItemAdd(query as CFDictionary, nil)
        
        // If we get interaction not allowed, try without authentication context
        if status == errSecInteractionNotAllowed || status == errSecAuthFailed {
            print("⚠️ Keychain access denied, trying without authentication context")
            query.removeValue(forKey: kSecUseAuthenticationContext as String)
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        // If still failing, try with less restrictive accessibility
        if status != errSecSuccess {
            print("⚠️ Keychain access failed, trying with kSecAttrAccessibleWhenUnlocked")
            query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
            // Delete and retry
            SecItemDelete(query as CFDictionary)
            status = SecItemAdd(query as CFDictionary, nil)
        }
        
        if status == errSecSuccess {
            print("✅ Keychain store successful")
            return true
        } else {
            print("❌ Keychain store error: \(status)")
            // Log specific error for debugging
            switch status {
            case errSecInteractionNotAllowed:
                print("❌ Error: User interaction not allowed")
            case errSecAuthFailed:
                print("❌ Error: Authentication failed")
            case errSecMissingEntitlement:
                print("❌ Error: Missing keychain entitlement")
            case errSecInvalidKeychain:
                print("❌ Error: Invalid keychain")
            default:
                print("❌ Error code: \(status)")
            }
            return false
        }
    }
    
    private static func loadFromKeychain(key: String) -> Data? {
        var query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        var status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        // If we get interaction not allowed, try with authentication prompt
        if status == errSecInteractionNotAllowed {
            print("⚠️ Keychain read access denied, prompting for permission")
            query[kSecUseOperationPrompt as String] = "PromiseKeeper needs access to your keychain to sync with widgets."
            status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        }
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            print("❌ Keychain load error: \(status)")
            // Log specific error for debugging
            switch status {
            case errSecInteractionNotAllowed:
                print("❌ Error: User interaction not allowed")
            case errSecAuthFailed:
                print("❌ Error: Authentication failed")
            case errSecUserCanceled:
                print("❌ Error: User canceled authentication")
            default:
                print("❌ Error code: \(status)")
            }
            return nil
        }
    }
    
    private static func deleteFromKeychain(key: String) -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
}