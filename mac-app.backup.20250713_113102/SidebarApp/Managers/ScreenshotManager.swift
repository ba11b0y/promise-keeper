import Foundation
import Combine
import ScreenCaptureKit
import AppKit

// MARK: - Screenshot Manager
@MainActor
class ScreenshotManager: ObservableObject {
    @Published var captureMode: CaptureMode = .onEnter
    @Published var isCapturing = false
    @Published var lastCaptureTime: Date?
    @Published var errorMessage: String?
    
    private var captureTimer: Timer?
    private var globalMonitor: Any?
    private var lastGlobalEnterTime = Date(timeIntervalSince1970: 0)
    private let globalEnterCooldown: TimeInterval = 10 // 10 second cooldown
    
    // Singleton instance
    static let shared = ScreenshotManager()
    
    // Screenshot delegate for processing
    weak var delegate: ScreenshotManagerDelegate?
    
    private init() {
        setupGlobalKeyMonitor()
    }
    
    deinit {
        Task { @MainActor in
            stopCapture()
        }
        if let monitor = globalMonitor {
            NSEvent.removeMonitor(monitor)
        }
    }
    
    // MARK: - Capture Modes
    enum CaptureMode: String, CaseIterable {
        case off = "off"
        case interval = "interval"
        case onEnter = "enter"
        
        var displayName: String {
            switch self {
            case .off: return "Off (Manual only)"
            case .interval: return "Every 30 seconds"
            case .onEnter: return "On Enter key press"
            }
        }
    }
    
    // MARK: - Public Methods
    func setCaptureMode(_ mode: CaptureMode) {
        captureMode = mode
        
        // Save preference
        UserDefaults.standard.set(mode.rawValue, forKey: "ScreenshotCaptureMode")
        
        switch mode {
        case .off:
            stopCapture()
        case .interval:
            startIntervalCapture()
        case .onEnter:
            stopCapture() // Global monitor handles Enter key
        }
    }
    
    func captureScreenshot() async -> ScreenshotResult? {
        guard await requestScreenRecordingPermission() else {
            errorMessage = "Screen recording permission required"
            return nil
        }
        
        isCapturing = true
        errorMessage = nil
        
        do {
            let result = try await captureScreen()
            lastCaptureTime = Date()
            return result
        } catch {
            print("❌ Screenshot capture failed: \(error)")
            errorMessage = "Screenshot capture failed: \(error.localizedDescription)"
            return nil
        }
        
        isCapturing = false
    }
    
    func loadSavedPreferences() {
        let savedMode = UserDefaults.standard.string(forKey: "ScreenshotCaptureMode") ?? "enter"
        if let mode = CaptureMode(rawValue: savedMode) {
            setCaptureMode(mode)
        }
    }
    
    // MARK: - Private Methods
    private func startIntervalCapture() {
        stopCapture()
        
        captureTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.handleTimerCapture()
            }
        }
        
        print("📸 Started 30-second screenshot interval")
    }
    
    private func stopCapture() {
        captureTimer?.invalidate()
        captureTimer = nil
    }
    
    private func setupGlobalKeyMonitor() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] event in
            if event.keyCode == 36 { // Enter key
                Task { @MainActor [weak self] in
                    await self?.handleGlobalEnterPress()
                }
            }
        }
    }
    
    private func handleTimerCapture() async {
        if let result = await captureScreenshot() {
            delegate?.screenshotCaptured(result, triggeredBy: .timer)
        }
    }
    
    private func handleGlobalEnterPress() async {
        guard captureMode == .onEnter else { return }
        
        let now = Date()
        
        // Rate limiting
        guard now.timeIntervalSince(lastGlobalEnterTime) >= globalEnterCooldown else {
            print("🔄 Global Enter screenshot skipped: cooldown active")
            return
        }
        
        lastGlobalEnterTime = now
        print("⌨️ Global Enter key detected - taking screenshot")
        
        if let result = await captureScreenshot() {
            delegate?.screenshotCaptured(result, triggeredBy: .enterKey)
        }
    }
    
    private func requestScreenRecordingPermission() async -> Bool {
        // Check if we have screen recording permission
        let stream = CGDisplayStream(
            dispatchQueueDisplay: CGMainDisplayID(),
            outputWidth: 1,
            outputHeight: 1,
            pixelFormat: Int32(kCVPixelFormatType_32BGRA),
            properties: nil,
            queue: DispatchQueue.main
        ) { _, _, _, _ in }
        
        if stream != nil {
            return true
        }
        
        // Request permission by trying to capture
        do {
            let availableDisplays = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true).displays
            return !availableDisplays.isEmpty
        } catch {
            return false
        }
    }
    
    private func captureScreen() async throws -> ScreenshotResult {
        let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
        
        guard let display = content.displays.first else {
            throw ScreenshotError.noDisplaysAvailable
        }
        
        let filter = SCContentFilter(display: display, excludingWindows: [])
        
        let configuration = SCStreamConfiguration()
        configuration.width = display.width
        configuration.height = display.height
        configuration.pixelFormat = kCVPixelFormatType_32BGRA
        configuration.showsCursor = false
        
        let screenshot = try await SCScreenshotManager.captureImage(
            contentFilter: filter,
            configuration: configuration
        )
        
        let screenshotId = "screenshot_\(Int(Date().timeIntervalSince1970 * 1000))"
        
        // Convert CGImage to base64
        let bitmapRep = NSBitmapImageRep(cgImage: screenshot)
        guard let pngData = bitmapRep.representation(using: .png, properties: [:]) else {
            throw ScreenshotError.conversionFailed
        }
        
        let base64String = pngData.base64EncodedString()
        
        return ScreenshotResult(
            id: screenshotId,
            timestamp: Date(),
            cgImage: screenshot,
            base64Data: base64String,
            size: CGSize(width: screenshot.width, height: screenshot.height)
        )
    }
}

// MARK: - Screenshot Result
struct ScreenshotResult {
    let id: String
    let timestamp: Date
    let cgImage: CGImage
    let base64Data: String
    let size: CGSize
}

// MARK: - Screenshot Trigger
enum ScreenshotTrigger {
    case manual
    case timer
    case enterKey
}

// MARK: - Screenshot Manager Delegate
protocol ScreenshotManagerDelegate: AnyObject {
    func screenshotCaptured(_ result: ScreenshotResult, triggeredBy trigger: ScreenshotTrigger)
}

// MARK: - Screenshot Errors
enum ScreenshotError: LocalizedError {
    case noDisplaysAvailable
    case permissionDenied
    case conversionFailed
    
    var errorDescription: String? {
        switch self {
        case .noDisplaysAvailable:
            return "No displays available for capture"
        case .permissionDenied:
            return "Screen recording permission denied"
        case .conversionFailed:
            return "Failed to convert screenshot to image data"
        }
    }
}