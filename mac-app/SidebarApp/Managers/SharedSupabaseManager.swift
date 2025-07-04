import Foundation
import Security
import WidgetKit

/// Shared Supabase Manager for both main app and widget
/// Uses Keychain to securely share the Supabase session between app and widget
public struct SharedSupabaseManager {
    
    // MARK: - Constants
    
    /// Keychain access group - must match in entitlements
    /// Format: <TeamID>.<BundleID> (without "group." prefix for Keychain)
    private static let keychainAccessGroup = "TX645N2QBW.com.example.mac.SidebarApp"
    
    /// Keychain keys
    private struct KeychainKeys {
        static let supabaseSession = "supabase_session"
        static let sessionExpiry = "supabase_session_expiry"
        static let userEmail = "supabase_user_email"
    }
    
    // MARK: - Session Storage
    
    /// Store the session data in Keychain for widget access
    /// This is used by the main app after successful authentication
    public static func storeSessionData(userId: String, email: String?, expiresAt: Date?) {
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
    
    /// Get session info for widget use
    public static func getSessionForWidget() -> (userId: String?, email: String?, isAuthenticated: Bool) {
        guard hasValidSession() else {
            return (nil, nil, false)
        }
        
        var userId: String? = nil
        var email: String? = nil
        
        // Get user ID
        if let userIdData = loadFromKeychain(key: "supabase_user_id") {
            userId = String(data: userIdData, encoding: .utf8)
        }
        
        // Get email
        if let emailData = loadFromKeychain(key: KeychainKeys.userEmail) {
            email = String(data: emailData, encoding: .utf8)
        }
        
        return (userId, email, true)
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
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlock
        ]
        
        // Delete any existing item
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess {
            return true
        } else {
            print("❌ Keychain store error: \(status)")
            return false
        }
    }
    
    private static func loadFromKeychain(key: String) -> Data? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecAttrAccessGroup as String: keychainAccessGroup,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        if status == errSecSuccess, let data = dataTypeRef as? Data {
            return data
        } else if status == errSecItemNotFound {
            return nil
        } else {
            print("❌ Keychain load error: \(status)")
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