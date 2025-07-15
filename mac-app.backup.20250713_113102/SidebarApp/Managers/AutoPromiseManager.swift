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
        
        // Listen for global Enter key events
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleGlobalEnterNotification),
            name: NSNotification.Name("GlobalEnterKeyPressed"),
            object: nil
        )
        
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
    
    @objc private func handleGlobalEnterNotification() {
        NSLog("📸 Received global Enter key notification")
        Task {
            await processManualScreenshot()
        }
    }
    
    // MARK: - Screenshot Processing
    private func processScreenshot(_ screenshot: ScreenshotResult, triggeredBy trigger: ScreenshotTrigger) async {
        isProcessing = true
        processingStatus = "Analyzing screenshot for promises..."
        lastProcessedTime = Date()
        
        do {
            // Convert base64 back to Data for multipart form upload
            NSLog("📸 Processing screenshot: %@", screenshot.id)
            NSLog("📸 Original base64 data length: %d characters", screenshot.base64Data.count)
            
            guard let imageData = Data(base64Encoded: screenshot.base64Data) else {
                NSLog("❌ Failed to convert base64 to image data")
                throw NSError(domain: "ScreenshotProcessing", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to convert base64 to image data"])
            }
            
            NSLog("✅ Successfully converted base64 to Data: %d bytes", imageData.count)
            
            // Extract promises using BAML API (multipart form data)
            NSLog("🚀 Calling BAML API with image data...")
            let response = try await bamlClient.extractPromisesFromImageData(
                imageData,
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
                            NSLog("✅ Auto-created promise: %@", detectedPromise.content)
                        }
                    } catch {
                        NSLog("❌ Failed to create promise: %@", error.localizedDescription)
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
                
                NSLog("✅ Found %d resolved promise(s)", resolvedPromises.count)
            }
            
            if response.promises.isEmpty && (response.resolved_promises?.isEmpty ?? true) {
                processingStatus = "No promises detected in screenshot"
                NSLog("ℹ️ No promises found in screenshot: %@", screenshot.id)
            } else {
                processingStatus = "Processing complete"
            }
            
        } catch {
            processingStatus = "Error processing screenshot: \(error.localizedDescription)"
            NSLog("❌ Error processing screenshot: %@", error.localizedDescription)
            NSLog("❌ Error type: %@", String(describing: type(of: error)))
            
            // Check if it's a BAML API error and log details
            if let bamlError = error as? BAMLError {
                NSLog("❌ BAML Error details: %@", bamlError.errorDescription ?? "Unknown BAML error")
                switch bamlError {
                case .httpError(let code):
                    NSLog("❌ HTTP Error Code: %d", code)
                case .decodingError(let decodeError):
                    NSLog("❌ Decoding Error: %@", decodeError.localizedDescription)
                case .invalidResponse:
                    NSLog("❌ Invalid Response")
                case .authenticationRequired:
                    NSLog("❌ Authentication Required")
                }
            }
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

