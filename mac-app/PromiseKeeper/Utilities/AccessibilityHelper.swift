import Foundation
import AppKit
import Combine

@MainActor
class AccessibilityHelper: ObservableObject {
    @Published var isAccessibilityEnabled = false
    @Published var isCheckingPermission = false
    
    static let shared = AccessibilityHelper()
    
    private var timer: Timer?
    
    private init() {
        checkAccessibilityStatus()
        // Start monitoring accessibility status
        startMonitoring()
    }
    
    deinit {
        timer?.invalidate()
    }
    
    // Check current accessibility status
    func checkAccessibilityStatus() {
        isAccessibilityEnabled = AXIsProcessTrusted()
    }
    
    // Start monitoring accessibility status changes
    private func startMonitoring() {
        // Check every 2 seconds for permission changes
        timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                self?.checkAccessibilityStatus()
            }
        }
    }
    
    // Request accessibility permission with improved UX
    func requestAccessibilityPermission() {
        isCheckingPermission = true
        
        // First check if already granted
        if AXIsProcessTrusted() {
            isAccessibilityEnabled = true
            isCheckingPermission = false
            return
        }
        
        // Create options dictionary to show prompt
        let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
        
        // This will show the system prompt and open System Preferences if needed
        let trusted = AXIsProcessTrustedWithOptions(options as CFDictionary)
        
        if trusted {
            isAccessibilityEnabled = true
        } else {
            // Start checking more frequently while user is granting permission
            startIntensiveMonitoring()
        }
        
        isCheckingPermission = false
    }
    
    // Open System Preferences directly
    func openSystemPreferences() {
        // Try the new URL scheme first (macOS 13+)
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        } else {
            // Fallback for older macOS versions
            NSWorkspace.shared.open(URL(fileURLWithPath: "/System/Library/PreferencePanes/Security.prefPane"))
        }
    }
    
    // More frequent checking while waiting for permission
    private func startIntensiveMonitoring() {
        timer?.invalidate()
        
        var checkCount = 0
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] timer in
            Task { @MainActor in
                self?.checkAccessibilityStatus()
                
                checkCount += 1
                // After 30 seconds (60 checks), go back to normal monitoring
                if checkCount > 60 {
                    timer.invalidate()
                    self?.startMonitoring()
                }
                
                // If permission granted, go back to normal monitoring
                if self?.isAccessibilityEnabled == true {
                    timer.invalidate()
                    self?.startMonitoring()
                }
            }
        }
    }
    
    // Helper to show a custom alert with better instructions
    func showAccessibilityAlert(from window: NSWindow? = nil) {
        let alert = NSAlert()
        alert.messageText = "Enable Accessibility for Promise Keeper"
        alert.informativeText = """
        Promise Keeper needs accessibility permission to detect when you press Enter.
        
        1. Click "Open System Settings" below
        2. Find "PromiseKeeper" in the list
        3. Toggle the switch to enable it
        4. You may need to restart the app
        
        This permission allows the app to capture screenshots when you press Enter.
        """
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Open System Settings")
        alert.addButton(withTitle: "Not Now")
        
        // Add icon
        alert.icon = NSImage(systemSymbolName: "lock.shield", accessibilityDescription: "Accessibility")
        
        let response: NSApplication.ModalResponse
        if let window = window {
            response = alert.runModal() // Use window sheet if available in future
        } else {
            response = alert.runModal()
        }
        
        if response == .alertFirstButtonReturn {
            requestAccessibilityPermission()
        }
    }
}