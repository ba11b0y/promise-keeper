import SwiftUI
import AppKit
import Sparkle
import UserNotifications

@main
struct PromiseKeeperApp: App {
    /// Legacy app delegate.
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        MainScene()
    }
}

// MARK: - App Delegate

class AppDelegate: NSObject, NSApplicationDelegate {
    
    var menuBarButton: MenuBarButton?
    var updaterController: SPUStandardUpdaterController!
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        menuBarButton = MenuBarButton()
        
        // Request notification permissions
        setupNotifications()
        
        // Initialize Sparkle updater with automatic updates enabled
        let updaterDelegate = UpdaterDelegate()
        updaterController = SPUStandardUpdaterController(
            startingUpdater: true, 
            updaterDelegate: updaterDelegate, 
            userDriverDelegate: nil
        )
        
        // Configure automatic updates
        updaterController.updater.automaticallyChecksForUpdates = true
        updaterController.updater.automaticallyDownloadsUpdates = true
        
        // Initialize GlobalEventManager on the main thread
        // The singleton will be initialized when first accessed
        NSLog("🚀 AppDelegate: Application launched with auto-updates enabled")
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                NSLog("✅ Notification permission granted")
            } else {
                NSLog("❌ Notification permission denied: \(error?.localizedDescription ?? "unknown")")
            }
        }
    }
        
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        // Return false to keep app running in background when windows are closed
        return false
    }
}

// MARK: - Updater Delegate

class UpdaterDelegate: NSObject, SPUUpdaterDelegate {
    
    func updater(_ updater: SPUUpdater, didFinishUpdateCycleFor updateCheck: SPUUpdateCheck, error: Error?) {
        if let error = error {
            NSLog("❌ Update check failed: \(error.localizedDescription)")
            showNotification(
                title: "Update Failed", 
                body: "Update check failed: \(error.localizedDescription)"
            )
        } else {
            NSLog("✅ Update check completed successfully")
        }
    }
    
    func updater(_ updater: SPUUpdater, willInstallUpdate item: SUAppcastItem) {
        NSLog("🔄 Installing update: \(item.displayVersionString)")
        
        // Show notification that update is being installed
        showNotification(
            title: "Installing Update", 
            body: "PromiseKeeper is being updated to version \(item.displayVersionString)..."
        )
    }
    
    func updater(_ updater: SPUUpdater, didAbortWithError error: Error) {
        NSLog("❌ Update aborted: \(error.localizedDescription)")
    }
    
    func updater(_ updater: SPUUpdater, willInstallUpdateOnQuit item: SUAppcastItem, immediateInstallationBlock: @escaping () -> Void) {
        NSLog("🔄 Update will install on quit: \(item.displayVersionString)")
        
        // Show notification about pending update
        showNotification(
            title: "Update Ready", 
            body: "PromiseKeeper will update to version \(item.displayVersionString) when you quit the app."
        )
    }
    
    func updaterWillRelaunchApplication(_ updater: SPUUpdater) {
        NSLog("✅ Update installed successfully - application will relaunch")
        
        // Show notification that update was installed successfully
        showNotification(
            title: "Update Complete", 
            body: "PromiseKeeper has been updated successfully! The app will now restart."
        )
    }
    
    private func showNotification(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                NSLog("❌ Failed to show notification: \(error.localizedDescription)")
            }
        }
    }
}
