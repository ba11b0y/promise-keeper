import Foundation
import Combine
import AppKit
import UserNotifications

// MARK: - Auto Promise Manager
@MainActor
class AutoPromiseManager: ObservableObject {
    @Published var isProcessing = false
    @Published var lastProcessedTime: Date?
    @Published var processingStatus: String?
    @Published var recentlyCreatedPromises: [DetectedPromise] = []
    @Published var recentlyResolvedPromises: [ResolvedPromise] = []
    
    private let screenshotManager = ScreenshotManager.shared
    private let bamlClient = BAMLAPIClient.shared
    private let promiseManager = PromiseManager()
    private let notificationManager = NotificationManager.shared
    private let mcpClient = MCPClient.shared
    
    private var cancellables = Set<AnyCancellable>()
    
    // Singleton instance
    static let shared = AutoPromiseManager()
    
    private init() {
        setupScreenshotDelegate()
        screenshotManager.loadSavedPreferences()
        
        // Initialize MCP client
        Task {
            await mcpClient.initialize()
        }
    }
    
    // MARK: - Setup
    private func setupScreenshotDelegate() {
        screenshotManager.delegate = self
    }
    
    // MARK: - Manual Screenshot Processing
    func processManualScreenshot() async {
        guard let screenshotResult = await screenshotManager.captureScreenshot() else {
            return
        }
        
        await processScreenshot(screenshotResult, triggeredBy: .manual)
    }
    
    // MARK: - Screenshot Processing
    private func processScreenshot(_ screenshot: ScreenshotResult, triggeredBy trigger: ScreenshotTrigger) async {
        isProcessing = true
        processingStatus = "Analyzing screenshot for promises..."
        lastProcessedTime = Date()
        
        do {
            // Convert screenshot to base64 PNG data format expected by BAML API
            let base64ImageData = "data:image/png;base64,\(screenshot.base64Data)"
            
            // Extract promises using BAML API
            let response = try await bamlClient.extractPromisesFromBase64(
                imageData: base64ImageData,
                screenshotId: screenshot.id,
                screenshotTimestamp: ISO8601DateFormatter().string(from: screenshot.timestamp)
            )
            
            // Process detected promises
            if !response.promises.isEmpty {
                processingStatus = "Found \(response.promises.count) promise(s). Creating..."
                
                var createdPromises: [DetectedPromise] = []
                
                for detectedPromise in response.promises {
                    do {
                        // Create promise in database
                        await promiseManager.createPromise(content: detectedPromise.content)
                        
                        if promiseManager.errorMessage == nil {
                            createdPromises.append(detectedPromise)
                            print("✅ Auto-created promise: \(detectedPromise.content)")
                        }
                    } catch {
                        print("❌ Failed to create promise: \(error)")
                    }
                }
                
                if !createdPromises.isEmpty {
                    recentlyCreatedPromises = createdPromises
                    
                    // Show notification
                    await showPromiseCreatedNotification(count: createdPromises.count, screenshotId: screenshot.id)
                    
                    // Execute actions if any
                    await executePromiseActions(for: createdPromises)
                }
            }
            
            // Process resolved promises
            if let resolvedPromises = response.resolved_promises, !resolvedPromises.isEmpty {
                recentlyResolvedPromises = resolvedPromises
                
                // Show notification for resolved promises
                await showPromiseResolvedNotification(count: resolvedPromises.count)
                
                print("✅ Found \(resolvedPromises.count) resolved promise(s)")
            }
            
            if response.promises.isEmpty && (response.resolved_promises?.isEmpty ?? true) {
                processingStatus = "No promises detected in screenshot"
                print("ℹ️ No promises found in screenshot: \(screenshot.id)")
            } else {
                processingStatus = "Processing complete"
            }
            
        } catch {
            processingStatus = "Error processing screenshot: \(error.localizedDescription)"
            print("❌ Error processing screenshot: \(error)")
        }
        
        isProcessing = false
        
        // Clear status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.processingStatus = nil
        }
    }
    
    // MARK: - Notifications
    private func showPromiseCreatedNotification(count: Int, screenshotId: String) async {
        let title = "Promise Keeper"
        let body = "Found \(count) promise\(count > 1 ? "s" : "") in your screen!"
        
        notificationManager.sendNotification(
            title: title,
            body: body
        )
    }
    
    private func showPromiseResolvedNotification(count: Int) async {
        let title = "Promise Keeper"
        let body = "\(count) promise\(count > 1 ? "s" : "") resolved!"
        
        notificationManager.sendNotification(
            title: title,
            body: body
        )
    }
    
    // MARK: - Action Execution
    private func executePromiseActions(for promises: [DetectedPromise]) async {
        for promise in promises {
            guard let action = promise.action, action.actionType != .noAction else {
                continue
            }
            
            switch action.actionType {
            case .calendarAdd:
                await executeCalendarAction(action, for: promise)
            case .systemLaunchApp:
                await executeLaunchAppAction(action, for: promise)
            case .noAction:
                break
            }
        }
    }
    
    private func executeCalendarAction(_ action: PromiseAction, for promise: DetectedPromise) async {
        guard let startTimeString = action.start_time,
              let endTimeString = action.end_time else {
            print("❌ Calendar action missing required time parameters")
            return
        }
        
        do {
            let result = try await mcpClient.addCalendarEvent(
                title: promise.content,
                startDate: startTimeString,
                endDate: endTimeString,
                calendar: nil // Use default calendar
            )
            print("✅ Created calendar event: \(result)")
            
            // Show notification about calendar event creation
            notificationManager.sendNotification(
                title: "Calendar Event Created",
                body: "Added '\(promise.content)' to your calendar"
            )
        } catch {
            print("❌ Failed to create calendar event: \(error)")
        }
    }
    
    private func executeLaunchAppAction(_ action: PromiseAction, for promise: DetectedPromise) async {
        guard let appName = action.app_name else { return }
        
        print("🚀 Launching app: \(appName) for promise: \(promise.content)")
        
        do {
            // Use MCP client to launch the app (same as Electron app)
            let result = try await mcpClient.launchApp(appName: appName)
            print("✅ MCP app launch result: \(result)")
            
            // Show notification about app launch
            notificationManager.sendNotification(
                title: "App Launched",
                body: "Opened \(appName) for '\(promise.content)'"
            )
        } catch {
            print("❌ MCP app launch failed, trying NSWorkspace fallback: \(error)")
            
            // Fallback to NSWorkspace (native macOS)
            let workspace = NSWorkspace.shared
            if let appURL = workspace.urlForApplication(withBundleIdentifier: appName) ??
                             workspace.urlForApplication(toOpen: URL(string: "file://\(appName)")!) {
                do {
                    try workspace.launchApplication(at: appURL, options: [], configuration: [:])
                    print("✅ Successfully launched \(appName) via NSWorkspace")
                } catch {
                    print("❌ Failed to launch \(appName): \(error)")
                }
            } else {
                // Try launching by name
                if !workspace.launchApplication(appName) {
                    print("❌ Could not launch app: \(appName)")
                }
            }
        }
    }
    
    // MARK: - Settings
    func getCaptureMode() -> ScreenshotManager.CaptureMode {
        return screenshotManager.captureMode
    }
    
    func setCaptureMode(_ mode: ScreenshotManager.CaptureMode) {
        screenshotManager.setCaptureMode(mode)
    }
    
    func getCaptureModeDisplayName() -> String {
        return screenshotManager.captureMode.displayName
    }
}

// MARK: - Screenshot Manager Delegate
extension AutoPromiseManager: ScreenshotManagerDelegate {
    nonisolated func screenshotCaptured(_ result: ScreenshotResult, triggeredBy trigger: ScreenshotTrigger) {
        Task {
            await processScreenshot(result, triggeredBy: trigger)
        }
    }
}

