import Foundation
import Supabase
import WidgetKit

/// Manages proactive token refresh to prevent widget JWT expiration
@MainActor
class TokenRefreshManager: ObservableObject {
    static let shared = TokenRefreshManager()
    
    private var refreshTimer: Timer?
    private let refreshInterval: TimeInterval = 30 * 60 // 30 minutes
    
    private init() {
        startTokenRefreshTimer()
    }
    
    /// Start a timer to refresh tokens periodically
    func startTokenRefreshTimer() {
        NSLog("🔄 TokenRefreshManager: Starting token refresh timer")
        
        // Cancel any existing timer
        refreshTimer?.invalidate()
        
        // Schedule timer to run every 30 minutes
        refreshTimer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
            Task { @MainActor in
                await self.refreshTokenIfNeeded()
            }
        }
        
        // Also refresh immediately on start
        Task {
            await refreshTokenIfNeeded()
        }
    }
    
    /// Stop the refresh timer (when user logs out)
    func stopTokenRefreshTimer() {
        NSLog("🛑 TokenRefreshManager: Stopping token refresh timer")
        refreshTimer?.invalidate()
        refreshTimer = nil
    }
    
    /// Check if token needs refresh and refresh if necessary
    private func refreshTokenIfNeeded() async {
        NSLog("🔍 TokenRefreshManager: Checking if token needs refresh")
        
        // Check if we have a valid session
        guard SupabaseManager.shared.isAuthenticated else {
            NSLog("❌ TokenRefreshManager: Not authenticated, skipping refresh")
            return
        }
        
        // Get current session from Supabase
        do {
            let session = try await SupabaseManager.shared.supabase.auth.session
            let expiryDate = Date(timeIntervalSince1970: session.expiresAt)
            let timeUntilExpiry = expiryDate.timeIntervalSinceNow
            
            NSLog("⏰ TokenRefreshManager: Token expires in \(timeUntilExpiry / 60) minutes")
            
            // Refresh if token expires in less than 60 minutes
            if timeUntilExpiry < 60 * 60 {
                NSLog("🔄 TokenRefreshManager: Token expiring soon, refreshing...")
                
                // Refresh the session
                let refreshedSession = try await SupabaseManager.shared.supabase.auth.refreshSession()
                
                NSLog("✅ TokenRefreshManager: Token refreshed successfully")
                
                // Update keychain with new token
                let newExpiryDate = Date(timeIntervalSince1970: refreshedSession.expiresAt)
                SharedSupabaseManager.storeSessionData(
                    userId: refreshedSession.user.id.uuidString,
                    email: refreshedSession.user.email,
                    expiresAt: newExpiryDate,
                    accessToken: refreshedSession.accessToken
                )
                
                // Reload widget timelines
                WidgetCenter.shared.reloadAllTimelines()
                
                NSLog("📱 TokenRefreshManager: Updated widget with refreshed token")
            } else {
                NSLog("✅ TokenRefreshManager: Token still valid, no refresh needed")
            }
        } catch {
            NSLog("❌ TokenRefreshManager: Error refreshing token: \(error)")
        }
    }
}