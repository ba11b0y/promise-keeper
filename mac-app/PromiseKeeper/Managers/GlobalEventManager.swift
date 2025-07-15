import Foundation
import AppKit
import Combine

// MARK: - Global Event Manager
@MainActor
class GlobalEventManager: ObservableObject {
    @Published var isGlobalEnterEnabled = false
    @Published var lastEnterPressTime: Date?
    
    private var globalEventMonitor: Any?
    private var localEventMonitor: Any?
    private let enterCooldownInterval: TimeInterval = 10.0 // 10 second cooldown
    
    private let screenshotManager = ScreenshotManager.shared
    
    // Singleton instance
    static let shared = GlobalEventManager()
    
    private init() {
        NSLog("🌐 GlobalEventManager initialized at \(Date())")
        
        // Start both local and global event monitoring by default
        startGlobalEventMonitoring()
        startLocalEventMonitoring()
    }
    
    deinit {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    // MARK: - Global Event Monitoring
    func startGlobalEventMonitoring() {
        guard globalEventMonitor == nil else { return }
        
        // Check if we have accessibility permissions
        let trusted = AXIsProcessTrusted()
        if !trusted {
            NSLog("⚠️ Accessibility permission not granted")
            
            // Use AccessibilityHelper for better UX
            Task { @MainActor in
                AccessibilityHelper.shared.showAccessibilityAlert()
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
            NSLog("🌐 Global event monitoring started successfully")
        } else {
            NSLog("❌ Failed to start global event monitoring - check accessibility permissions")
        }
    }
    
    func stopGlobalEventMonitoring() {
        if let monitor = globalEventMonitor {
            NSEvent.removeMonitor(monitor)
            globalEventMonitor = nil
            NSLog("🌐 Global event monitoring stopped")
        }
    }
    
    // MARK: - Local Event Monitoring (for when app has focus)
    func startLocalEventMonitoring() {
        guard localEventMonitor == nil else { return }
        
        localEventMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            Task { @MainActor in
                await self?.handleLocalKeyEvent(event)
            }
            return event
        }
        
        NSLog("🌐 Local event monitoring started successfully")
    }
    
    func stopLocalEventMonitoring() {
        if let monitor = localEventMonitor {
            NSEvent.removeMonitor(monitor)
            localEventMonitor = nil
            NSLog("🌐 Local event monitoring stopped")
        }
    }
    
    // MARK: - Handle Key Events
    private func handleGlobalKeyEvent(_ event: NSEvent) async {
        NSLog("🌐 Global key event detected: keyCode=%d, characters=%@", event.keyCode, event.characters ?? "nil")
        // Check if it's the Enter key (Return key)
        if event.keyCode == 36 { // Return key code
            await handleGlobalEnterPress()
        }
    }
    
    private func handleLocalKeyEvent(_ event: NSEvent) async {
        NSLog("🌐 Local key event detected: keyCode=%d, characters=%@", event.keyCode, event.characters ?? "nil")
        // Check if it's the Enter key (Return key)
        if event.keyCode == 36 { // Return key code
            await handleGlobalEnterPress()
        }
    }
    
    // MARK: - Handle Global Enter Press
    private func handleGlobalEnterPress() async {
        // Process Enter key for all modes (not just onEnter mode)
        let screenshotMode = screenshotManager.captureMode
        
        NSLog("🌐 Global Enter pressed with screenshot mode: %@", String(describing: screenshotMode))
        
        let now = Date()
        
        // Rate limiting to prevent spam (same as Electron app)
        if let lastPress = lastEnterPressTime,
           now.timeIntervalSince(lastPress) < enterCooldownInterval {
            let remainingTime = Int(enterCooldownInterval - now.timeIntervalSince(lastPress))
            NSLog("🌐 Global Enter screenshot skipped: cooldown active (%d seconds remaining)", remainingTime)
            
            // Cooldown active - skip without notification
            return
        }
        
        lastEnterPressTime = now
        NSLog("🌐 Global Enter key detected - triggering screenshot")
        
        // Post notification to trigger screenshot processing
        NotificationCenter.default.post(name: NSNotification.Name("GlobalEnterKeyPressed"), object: nil)
    }
    
    // MARK: - Enable/Disable Global Enter
    func setGlobalEnterEnabled(_ enabled: Bool) {
        isGlobalEnterEnabled = enabled
        NSLog("🌐 Global Enter monitoring: %@", enabled ? "enabled" : "disabled")
    }
    
    // MARK: - Manual Screenshot Trigger
    func triggerManualScreenshot() async {
        NSLog("🌐 Manual screenshot trigger")
        // Post notification to trigger screenshot processing
        NotificationCenter.default.post(name: NSNotification.Name("GlobalEnterKeyPressed"), object: nil)
    }
}