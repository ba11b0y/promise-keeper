import Foundation
import UserNotifications
import AppKit

class NotificationManager: NSObject, ObservableObject {
    static let shared = NotificationManager()
    
    @Published var isPermissionGranted = false
    
    private override init() {
        super.init()
        checkPermission()
        setupNotificationCategories()
        UNUserNotificationCenter.current().delegate = self
    }
    
    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            DispatchQueue.main.async {
                self.isPermissionGranted = granted
            }
            if let error = error {
                print("Error requesting notification permission: \(error.localizedDescription)")
            }
        }
    }
    
    private func checkPermission() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isPermissionGranted = settings.authorizationStatus == .authorized
            }
        }
    }
    
    func sendNotification(title: String, body: String, subtitle: String? = nil, timeInterval: TimeInterval = 0.5) {
        // Check permission first
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            guard settings.authorizationStatus == .authorized else {
                print("⚠️ Notification permission not granted. Current status: \(settings.authorizationStatus.rawValue)")
                // Try to request permission again
                DispatchQueue.main.async {
                    self.requestPermission()
                }
                return
            }
            
            let content = UNMutableNotificationContent()
            content.title = title
            content.body = body
            if let subtitle = subtitle {
                content.subtitle = subtitle
            }
            content.sound = .default
            content.categoryIdentifier = "PROMISE_CATEGORY"
            
            // Use immediate delivery if timeInterval is very small
            let request: UNNotificationRequest
            if timeInterval < 0.1 {
                // Deliver immediately without trigger
                request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
            } else {
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
                request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
            }
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("❌ Error sending notification: \(error.localizedDescription)")
                } else {
                    print("✅ Notification scheduled successfully")
                }
            }
        }
    }
    
    // Helper to send notification with user info for actions
    func sendPromiseNotification(promise: DetectedPromise, formatted: FormattedPromise? = nil) {
        let title = formatted?.title ?? "New Promise"
        let body = formatted?.body ?? promise.content
        let subtitle = formatted?.details
        
        sendNotification(title: title, body: body, subtitle: subtitle)
    }
    
    // Setup notification categories and actions
    private func setupNotificationCategories() {
        // Action for adding due date
        let addDueDateAction = UNNotificationAction(
            identifier: "ADD_DUE_DATE",
            title: "Add Due Date",
            options: [.foreground]
        )
        
        // Action for marking as complete
        let completeAction = UNNotificationAction(
            identifier: "MARK_COMPLETE",
            title: "Mark Complete",
            options: []
        )
        
        // Action for dismissing
        let dismissAction = UNNotificationAction(
            identifier: "DISMISS",
            title: "Dismiss",
            options: [.destructive]
        )
        
        // Create category for promise notifications
        let promiseCategory = UNNotificationCategory(
            identifier: "PROMISE_CATEGORY",
            actions: [addDueDateAction, completeAction, dismissAction],
            intentIdentifiers: [],
            options: []
        )
        
        // Set the notification categories
        UNUserNotificationCenter.current().setNotificationCategories([promiseCategory])
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension NotificationManager: UNUserNotificationCenterDelegate {
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                willPresent notification: UNNotification, 
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound])
    }
    
    // Handle notification actions
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                                didReceive response: UNNotificationResponse, 
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let actionIdentifier = response.actionIdentifier
        let content = response.notification.request.content
        
        switch actionIdentifier {
        case "ADD_DUE_DATE":
            // Post notification to open due date picker
            NotificationCenter.default.post(
                name: NSNotification.Name("ShowDueDatePicker"),
                object: nil,
                userInfo: ["promiseContent": content.body]
            )
            
        case "MARK_COMPLETE":
            // Post notification to mark promise as complete
            NotificationCenter.default.post(
                name: NSNotification.Name("MarkPromiseComplete"),
                object: nil,
                userInfo: ["promiseContent": content.body]
            )
            
        case UNNotificationDefaultActionIdentifier:
            // User tapped on notification
            NSApp.activate(ignoringOtherApps: true)
            
        default:
            break
        }
        
        completionHandler()
    }
} 