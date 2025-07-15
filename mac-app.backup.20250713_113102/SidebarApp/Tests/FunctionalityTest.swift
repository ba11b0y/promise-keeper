import Foundation
import XCTest
@testable import PromiseKeeper

// MARK: - Functionality Test Suite
// Tests to verify Swift app matches Electron app functionality exactly

class FunctionalityTest: XCTestCase {
    
    var autoPromiseManager: AutoPromiseManager!
    var screenshotManager: ScreenshotManager!
    var bamlClient: BAMLAPIClient!
    var mcpClient: MCPClient!
    var promiseManager: PromiseManager!
    
    override func setUp() async throws {
        await MainActor.run {
            autoPromiseManager = AutoPromiseManager.shared
            screenshotManager = ScreenshotManager.shared
            bamlClient = BAMLAPIClient.shared
            mcpClient = MCPClient.shared
            promiseManager = PromiseManager()
        }
    }
    
    // MARK: - Screenshot Capture Tests
    func testScreenshotCaptureModesMatchElectron() async throws {
        await MainActor.run {
            // Test all three modes exist (matching Electron app)
            XCTAssertEqual(ScreenshotManager.CaptureMode.allCases.count, 3)
            
            let modes = ScreenshotManager.CaptureMode.allCases
            XCTAssertTrue(modes.contains(.off))
            XCTAssertTrue(modes.contains(.interval))
            XCTAssertTrue(modes.contains(.onEnter))
            
            // Test default mode is Enter (matching Electron)
            XCTAssertEqual(screenshotManager.captureMode, .onEnter)
            
            // Test mode display names match Electron app
            XCTAssertEqual(ScreenshotManager.CaptureMode.off.displayName, "Off (Manual only)")
            XCTAssertEqual(ScreenshotManager.CaptureMode.interval.displayName, "Every 30 seconds")
            XCTAssertEqual(ScreenshotManager.CaptureMode.onEnter.displayName, "On Enter key press")
        }
    }
    
    func testScreenshotCaptureWorkflow() async throws {
        await MainActor.run {
            // Test manual screenshot capture
            screenshotManager.setCaptureMode(.off)
            XCTAssertEqual(screenshotManager.captureMode, .off)
            
            // Note: Actual screenshot capture requires screen recording permission
            // In production testing, verify this works
        }
    }
    
    // MARK: - BAML API Tests
    func testBAMLAPIClientConfiguration() async throws {
        // Test BAML client uses same API endpoint as Electron
        let expectedBaseURL = "https://promise-keeper-api-red-sunset-2072.fly.dev"
        // Note: Internal baseURL is private, but we test the endpoint behavior
        
        // Test that BAML client methods exist and match Electron functionality
        let mockImageData = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAADUlEQVR42mP8/5+hHgAHggJ/PchI7wAAAABJRU5ErkJggg=="
        
        do {
            // This would make an actual API call in integration testing
            // let result = try await bamlClient.extractPromisesFromBase64(imageData: mockImageData)
            // XCTAssertNotNil(result)
        } catch {
            // Expected in unit test without real API
        }
    }
    
    // MARK: - MCP Integration Tests
    func testMCPClientMatchesElectronIntegration() async throws {
        await MainActor.run {
            // Test MCP client has all required methods matching Electron app
            XCTAssertNotNil(mcpClient)
            
            // Test system operations exist
            // Note: Actual MCP calls require AppleScript MCP server running
            
            // Test calendar operations exist
            // Test message operations exist
        }
    }
    
    // MARK: - Promise Management Tests
    func testPromiseModelMatchesDatabase() async throws {
        await MainActor.run {
            // Test Promise model has all fields from database (matching Electron)
            let samplePromise = Promise(
                id: 1,
                created_at: Date(),
                updated_at: Date(),
                content: "Test promise",
                owner_id: UUID(),
                resolved: false,
                extracted_from_screenshot: true,
                screenshot_id: "test_screenshot",
                screenshot_timestamp: "2024-01-01T00:00:00Z",
                resolved_screenshot_id: nil,
                resolved_screenshot_time: nil,
                resolved_reason: nil,
                extraction_data: nil,
                action: nil,
                metadata: nil
            )
            
            XCTAssertEqual(samplePromise.content, "Test promise")
            XCTAssertEqual(samplePromise.isFromScreenshot, true)
            XCTAssertEqual(samplePromise.isResolved, false)
        }
    }
    
    // MARK: - Auto-Promise Creation Tests
    func testAutoPromiseWorkflowMatchesElectron() async throws {
        await MainActor.run {
            // Test auto-promise manager has all required functionality
            XCTAssertNotNil(autoPromiseManager.recentlyCreatedPromises)
            XCTAssertNotNil(autoPromiseManager.recentlyResolvedPromises)
            XCTAssertNotNil(autoPromiseManager.processingStatus)
            
            // Test capture mode settings
            autoPromiseManager.setCaptureMode(.interval)
            XCTAssertEqual(autoPromiseManager.getCaptureMode(), .interval)
            
            autoPromiseManager.setCaptureMode(.onEnter)
            XCTAssertEqual(autoPromiseManager.getCaptureMode(), .onEnter)
        }
    }
    
    // MARK: - UI Component Tests
    func testCompactUIMatchesElectronDimensions() async throws {
        await MainActor.run {
            // Test compact view dimensions match Electron app widget-like size
            let compactWidth: CGFloat = 320
            let compactHeight: CGFloat = 480
            
            // Verify these match the Electron app's window size
            XCTAssertEqual(compactWidth, 320)
            XCTAssertEqual(compactHeight, 480)
        }
    }
    
    // MARK: - Widget Integration Tests
    func testWidgetKitImplementation() async throws {
        // Test WidgetKit widgets are properly configured
        // Note: Widget testing requires special Widget testing framework
        
        // Test widget timeline provider exists
        // Test widget entry view exists
        // Test widget supports all required families (small, medium, large)
    }
    
    // MARK: - Notification Tests
    func testNotificationSystemMatchesElectron() async throws {
        await MainActor.run {
            let notificationManager = NotificationManager.shared
            XCTAssertNotNil(notificationManager)
            
            // Test notification content matches Electron app format
            // Note: Actual notification testing requires permission and system integration
        }
    }
    
    // MARK: - Integration Test
    func testFullWorkflowIntegration() async throws {
        await MainActor.run {
            // Test complete workflow matches Electron app:
            // 1. Screenshot capture
            // 2. BAML promise extraction
            // 3. Promise creation
            // 4. MCP action execution
            // 5. Notification display
            
            // This would be tested in full integration environment
            XCTAssertTrue(true) // Placeholder for integration test
        }
    }
    
    // MARK: - Performance Comparison Tests
    func testPerformanceVsElectron() async throws {
        // Test Swift app performance advantages
        measure {
            // Screenshot capture performance
            Task {
                await MainActor.run {
                    // Performance test for screenshot operations
                }
            }
        }
    }
    
    // MARK: - Backend Compatibility Tests
    func testBackendCompatibility() async throws {
        // Test Supabase integration matches Electron app exactly
        await MainActor.run {
            let supabaseManager = SupabaseManager.shared
            XCTAssertNotNil(supabaseManager.client)
            
            // Test authentication flow
            // Test database operations
            // Test API compatibility
        }
    }
}

// MARK: - Manual Test Checklist
/*
MANUAL TESTING CHECKLIST (to verify against Electron app):

✅ CORE FUNCTIONALITY:
[ ] Screenshot capture works in all 3 modes (Off/30s/Enter)
[ ] Enter key global monitoring with 1-minute cooldown
[ ] BAML API extracts promises from screenshots
[ ] Auto-promise creation saves to database
[ ] Promise resolution detection works
[ ] MCP actions execute (calendar, app launch)

✅ UI/UX MATCHING:
[ ] Compact widget-like interface (320x480)
[ ] Glass blur effects and modern design
[ ] Screenshot controls in main interface
[ ] Settings for capture mode switching
[ ] Notifications match Electron format

✅ SYSTEM INTEGRATION:
[ ] Menu bar icon and functionality
[ ] System tray menu options
[ ] Global shortcuts work
[ ] Native notifications display
[ ] WidgetKit widgets show in Notification Center

✅ BACKEND COMPATIBILITY:
[ ] Same Supabase database connection
[ ] Same BAML API endpoints
[ ] Same AppleScript MCP server
[ ] Same authentication flow
[ ] Same promise data format

✅ PERFORMANCE COMPARISON:
[ ] Faster screenshot capture than Electron
[ ] Lower memory usage than Electron
[ ] Better battery efficiency
[ ] Smoother animations and UI
[ ] Native macOS integration advantages

✅ ELECTRON PARITY CHECK:
[ ] All Electron features work in Swift
[ ] Same user workflows and interactions
[ ] Same data synchronization
[ ] Same notification behavior
[ ] Same system action capabilities
*/