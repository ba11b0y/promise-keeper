import Foundation
import WidgetKit
import os.log

/// Unified data manager for atomic, thread-safe widget data operations
public final class UnifiedDataManager {
    // MARK: - Singleton
    public static let shared = UnifiedDataManager()
    
    // MARK: - Properties
    private let appGroupID: String
    private let dataFileName: String
    private let changeNotificationName: String
    
    // Thread-safe access
    private let queue = DispatchQueue(label: "com.promisekeeper.unifieddatamanager", attributes: .concurrent)
    
    // JSON coding
    private let encoder: JSONEncoder = {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }()
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    // Logging
    private let logger = Logger(subsystem: "com.promisekeeper", category: "UnifiedDataManager")
    
    // MARK: - Initialization
    private init() {
        self.appGroupID = WidgetConfiguration.appGroupIdentifier
        self.dataFileName = WidgetConfiguration.dataFileName
        self.changeNotificationName = WidgetConfiguration.changeNotificationName
        
        // Verify app group access on init
        verifyAppGroupAccess()
        
        // Register for change notifications (for widget)
        registerForChangeNotifications()
    }
    
    // MARK: - Public API
    
    /// Save widget data atomically
    /// - Parameter data: The widget data to save
    /// - Returns: Success/failure
    @discardableResult
    public func save(_ data: WidgetData) -> Bool {
        var success = false
        
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                guard let url = self.dataFileURL else {
                    self.logger.error("Failed to get data file URL")
                    return
                }
                
                // Encode data
                let encoded = try self.encoder.encode(data)
                
                // Write atomically to prevent partial writes
                try encoded.write(to: url, options: [.atomic, .completeFileProtection])
                
                self.logger.info("Successfully saved widget data: \(data.promises.count) promises")
                success = true
                
                // Post change notification
                self.postChangeNotification()
                
                // Reload widget timelines
                DispatchQueue.main.async {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                
            } catch {
                self.logger.error("Failed to save widget data: \(error.localizedDescription)")
            }
        }
        
        // Wait for write to complete
        queue.sync(flags: .barrier) {}
        return success
    }
    
    /// Load widget data atomically
    /// - Returns: The loaded widget data, or nil if not found/error
    public func load() -> WidgetData? {
        queue.sync {
            guard let url = self.dataFileURL else {
                logger.error("Failed to get data file URL")
                return nil
            }
            
            guard FileManager.default.fileExists(atPath: url.path) else {
                logger.info("No widget data file found")
                return nil
            }
            
            do {
                let data = try Data(contentsOf: url)
                let widgetData = try decoder.decode(WidgetData.self, from: data)
                
                logger.info("Successfully loaded widget data: \(widgetData.promises.count) promises")
                return widgetData
                
            } catch {
                logger.error("Failed to load widget data: \(error.localizedDescription)")
                
                // If corrupt, return empty data instead of crashing
                return WidgetData()
            }
        }
    }
    
    /// Clear all widget data
    public func clear() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self,
                  let url = self.dataFileURL else { return }
            
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                    self.logger.info("Cleared widget data")
                    
                    // Post change notification
                    self.postChangeNotification()
                    
                    // Reload widget timelines
                    DispatchQueue.main.async {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            } catch {
                self.logger.error("Failed to clear widget data: \(error.localizedDescription)")
            }
        }
    }
    
    /// Update only authentication state (optimized for auth changes)
    public func updateAuthState(userId: String?, userEmail: String?, isAuthenticated: Bool) {
        // Load existing data
        var currentData = load() ?? WidgetData()
        
        // Create updated data preserving promises
        let updatedData = WidgetData(
            promises: currentData.promises,
            userId: userId,
            userEmail: userEmail,
            isAuthenticated: isAuthenticated,
            lastUpdated: Date(),
            version: currentData.version
        )
        
        // Save atomically
        save(updatedData)
    }
    
    // MARK: - Private Methods
    
    private var dataFileURL: URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            logger.error("Failed to access App Group: \(self.appGroupID)")
            return nil
        }
        
        // Create directory if needed
        let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: dataDirectory.path) {
            do {
                try FileManager.default.createDirectory(
                    at: dataDirectory,
                    withIntermediateDirectories: true,
                    attributes: [.protectionKey: FileProtectionType.complete]
                )
            } catch {
                logger.error("Failed to create data directory: \(error.localizedDescription)")
                return nil
            }
        }
        
        return dataDirectory.appendingPathComponent(dataFileName)
    }
    
    private func verifyAppGroupAccess() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            logger.error("❌ CRITICAL: Cannot access App Group '\(appGroupID)'")
            logger.error("Ensure App Group is enabled in Signing & Capabilities for both targets")
            return
        }
        
        logger.info("✅ App Group accessible at: \(containerURL.path)")
        
        // Test write access
        let testFile = containerURL.appendingPathComponent(".write_test")
        let testData = "test".data(using: .utf8)!
        
        do {
            try testData.write(to: testFile)
            try FileManager.default.removeItem(at: testFile)
            logger.info("✅ App Group write access verified")
        } catch {
            logger.error("❌ App Group write access failed: \(error.localizedDescription)")
        }
    }
    
    private func postChangeNotification() {
        // Post Darwin notification for cross-process communication
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(changeNotificationName as CFString),
            nil,
            nil,
            true
        )
        
        logger.debug("Posted change notification: \(self.changeNotificationName)")
    }
    
    private func registerForChangeNotifications() {
        // Register for Darwin notifications (widget listens to app changes)
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, name, _, _ in
                // Handle notification on main queue
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .widgetDataDidChange,
                        object: nil
                    )
                }
            },
            changeNotificationName as CFString,
            nil,
            .deliverImmediately
        )
        
        logger.debug("Registered for change notifications")
    }
}

// MARK: - Notification Names
public extension Notification.Name {
    static let widgetDataDidChange = Notification.Name("widgetDataDidChange")
}

// MARK: - Convenience Extensions
public extension UnifiedDataManager {
    /// Quick check if user is authenticated
    var isAuthenticated: Bool {
        load()?.isAuthenticated ?? false
    }
    
    /// Get current promises
    var promises: [WidgetPromise] {
        load()?.promises ?? []
    }
    
    /// Get promise statistics
    var statistics: (total: Int, completed: Int, pending: Int, percentage: Int) {
        guard let data = load() else {
            return (0, 0, 0, 0)
        }
        
        return (
            total: data.totalPromises,
            completed: data.completedPromises,
            pending: data.pendingPromises,
            percentage: data.completionPercentage
        )
    }
}