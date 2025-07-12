import Foundation
import AppKit
import Combine

// MARK: - Global Event Manager
@MainActor
class GlobalEventManager: ObservableObject {
    @Published var isGlobalEnterEnabled = false
    @Published var lastEnterPressTime: Date?
    
    private var globalEventMonitor: Any?
    private let enterCooldownInterval: TimeInterval = 60.0 // 1 minute cooldown like Electron app
    
    private let autoPromiseManager = AutoPromiseManager.shared
    private let screenshotManager = ScreenshotManager.shared
    
    // Singleton instance
    static let shared = GlobalEventManager()
    
    private init() {
        print("🌐 GlobalEventManager initialized")
        
        // Start global event monitoring by default
        startGlobalEventMonitoring()
    }
    
    deinit {
        stopGlobalEventMonitoring()
    }
    
    // MARK: - Global Event Monitoring
    func startGlobalEventMonitoring() {
        guard globalEventMonitor == nil else { return }
        
        // Check if we have accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            print("⚠️ Accessibility permission not granted")
            
            // Show alert to guide user
            Task { @MainActor in
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "Promise Keeper needs accessibility permission to detect Enter key presses globally.\n\nPlease grant permission in System Settings > Privacy & Security > Accessibility."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Cancel")
                
                if alert.runModal() == .alertFirstButtonReturn {
                    // Open accessibility preferences
                    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true]
                    AXIsProcessTrustedWithOptions(options as CFDictionary)
                }
            }
            return
        }
        
        // Monitor global key events
        globalEventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                await self?.handleGlobalKeyEvent(event)
            }
        }
        
        if globalEventMonitor != nil {
            print("🌐 Global event monitoring started successfully")
        } else {
            print("❌ Failed to start global event monitoring - check accessibility permissions")
        }
    }
    
    func stopGlobalEventMonitoring() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
            print("🌐 Global event monitoring stopped")
        }
    }
    
    // MARK: - Handle Global Key Events
    private func handleGlobalKeyEvent(_ event: NSEvent) async {
        // Check if it's the Enter key (Return key)
        if event.keyCode == 36 { // Return key code
            await handleGlobalEnterPress()
        }
    }
    
    // MARK: - Handle Global Enter Press
    private func handleGlobalEnterPress() async {
        // Only process if global Enter is enabled and we're in the right screenshot mode
        let screenshotMode = screenshotManager.captureMode
        
        guard screenshotMode == .onEnter else {
            print("🌐 Global Enter pressed but screenshot mode is not 'onEnter' (current: \(screenshotMode))")
            return
        }
        
        let now = Date()
        
        // Rate limiting to prevent spam (same as Electron app)
        if let lastPress = lastEnterPressTime,
           now.timeIntervalSince(lastPress) < enterCooldownInterval {
            let remainingTime = Int(enterCooldownInterval - now.timeIntervalSince(lastPress))
            print("🌐 Global Enter screenshot skipped: cooldown active (\(remainingTime)s remaining)")
            
            // Notify user about cooldown
            NotificationManager.shared.sendNotification(
                title: "Screenshot Cooldown Active",
                body: "Please wait \(remainingTime) seconds before taking another screenshot"
            )
            return
        }
        
        lastEnterPressTime = now
        print("🌐 Global Enter key detected - triggering screenshot")
        
        // Trigger screenshot and processing
        await autoPromiseManager.processManualScreenshot()
    }
    
    // MARK: - Enable/Disable Global Enter
    func setGlobalEnterEnabled(_ enabled: Bool) {
        isGlobalEnterEnabled = enabled
        print("🌐 Global Enter monitoring: \(enabled ? "enabled" : "disabled")")
    }
    
    // MARK: - Manual Screenshot Trigger
    func triggerManualScreenshot() async {
        print("🌐 Manual screenshot trigger")
        await autoPromiseManager.processManualScreenshot()
    }
}