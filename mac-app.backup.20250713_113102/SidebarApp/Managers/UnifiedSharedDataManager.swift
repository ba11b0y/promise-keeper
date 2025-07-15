import Foundation
import WidgetKit
import os.log

// MARK: - Widget Data Models  
struct WidgetPromiseData: Identifiable, Codable, Equatable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool
    
    // Convenience properties for compatibility
    var isResolved: Bool { resolved }
    var createdAt: Date { created_at }
    var updatedAt: Date { updated_at }
}

struct WidgetData: Codable, Equatable {
    let promises: [WidgetPromiseData]
    let userId: String?
    let userEmail: String?
    let isAuthenticated: Bool
    let lastUpdated: Date
    let version: Int
    
    var totalPromises: Int { promises.count }
    var completedPromises: Int { promises.filter { $0.isResolved }.count }
    var pendingPromises: Int { totalPromises - completedPromises }
    var completionPercentage: Int {
        totalPromises > 0 ? Int((Double(completedPromises) / Double(totalPromises)) * 100) : 0
    }
    
    init(promises: [WidgetPromiseData] = [],
         userId: String? = nil,
         userEmail: String? = nil,
         isAuthenticated: Bool = false,
         lastUpdated: Date = Date(),
         version: Int = 1) {
        self.promises = promises
        self.userId = userId
        self.userEmail = userEmail
        self.isAuthenticated = isAuthenticated
        self.lastUpdated = lastUpdated
        self.version = version
    }
}

// MARK: - Unified Data Manager
final class UnifiedSharedDataManager {
    static let shared = UnifiedSharedDataManager()
    
    // Configuration
    private let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
    private let dataFileName = "widget_data.json"
    private let changeNotificationName = "com.promisekeeper.widget.datachanged"
    
    // Thread safety
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
    private let logger = Logger(subsystem: "com.promisekeeper", category: "UnifiedSharedDataManager")
    
    private init() {
        verifyAppGroupAccess()
        registerForChangeNotifications()
    }
    
    // MARK: - Public API
    
    @discardableResult
    func save(_ data: WidgetData) -> Bool {
        var success = false
        
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self else { return }
            
            do {
                guard let url = self.dataFileURL else {
                    self.logger.error("Failed to get data file URL")
                    return
                }
                
                let encoded = try self.encoder.encode(data)
                
                // Create directory if needed
                let directory = url.deletingLastPathComponent()
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true, attributes: nil)
                
                // Write with specific options for better widget compatibility
                // Try atomic write first to avoid partial files, but don't fail if it doesn't work
                do {
                    try encoded.write(to: url, options: [.atomic])
                } catch {
                    // If atomic write fails, try without it
                    try encoded.write(to: url, options: [])
                }
                
                // Set permissions to be readable by everyone in the app group
                try FileManager.default.setAttributes([
                    .posixPermissions: 0o644,  // Read for all, write for owner
                    .protectionKey: FileProtectionType.none
                ], ofItemAtPath: url.path)
                
                // Also update directory permissions to ensure accessibility
                try FileManager.default.setAttributes([
                    .posixPermissions: 0o755,
                    .protectionKey: FileProtectionType.none
                ], ofItemAtPath: directory.path)
                
                // Remove quarantine attribute if present using multiple methods
                do {
                    // Method 1: Try using removexattr directly
                    let quarantineKey = "com.apple.quarantine"
                    if let quarantineData = quarantineKey.data(using: .utf8) {
                        let result = removexattr(url.path, quarantineKey, 0)
                        if result == 0 {
                            self.logger.info("Successfully removed quarantine attribute using removexattr")
                        } else {
                            self.logger.warning("removexattr failed with result: \(result)")
                        }
                    }
                } catch {
                    self.logger.warning("Could not remove quarantine attribute: \(error)")
                }
                
                // Method 2: Also try using Process as backup
                do {
                    let removeQuarantineTask = Process()
                    removeQuarantineTask.executableURL = URL(fileURLWithPath: "/usr/bin/xattr")
                    removeQuarantineTask.arguments = ["-d", "com.apple.quarantine", url.path]
                    try removeQuarantineTask.run()
                    removeQuarantineTask.waitUntilExit()
                    self.logger.info("Backup quarantine removal using xattr command")
                } catch {
                    self.logger.warning("Backup quarantine removal failed: \(error)")
                }
                
                // Extra verification
                let attr = try FileManager.default.attributesOfItem(atPath: url.path)
                self.logger.info("🔍 JSON saved at \(url.path) (size: \(attr[.size] as? Int ?? 0) bytes, protection: \((attr[.protectionKey] as? FileProtectionType)?.rawValue ?? "none"))")
                
                // Also save to UserDefaults as a fallback for widgets
                if let defaults = UserDefaults(suiteName: self.appGroupID) {
                    defaults.set(encoded, forKey: "widget_data")
                    defaults.synchronize()
                    self.logger.info("Also saved widget data to UserDefaults as fallback")
                }
                
                self.logger.info("Successfully saved widget data: \(data.promises.count) promises")
                success = true
                
                self.postChangeNotification()
                
                DispatchQueue.main.async {
                    WidgetCenter.shared.reloadAllTimelines()
                }
                
            } catch {
                self.logger.error("Failed to save widget data: \(error.localizedDescription)")
            }
        }
        
        queue.sync(flags: .barrier) {}
        return success
    }
    
    func load() -> WidgetData? {
        queue.sync {
            guard let url = self.dataFileURL else {
                self.logger.error("Failed to get data file URL")
                return nil
            }
            
            guard FileManager.default.fileExists(atPath: url.path) else {
                self.logger.info("No widget data file found")
                return nil
            }
            
            do {
                let data = try Data(contentsOf: url)
                let widgetData = try self.decoder.decode(WidgetData.self, from: data)
                
                self.logger.info("Successfully loaded widget data: \(widgetData.promises.count) promises")
                return widgetData
                
            } catch {
                self.logger.error("Failed to load widget data: \(error.localizedDescription)")
                return WidgetData()
            }
        }
    }
    
    func clear() {
        queue.async(flags: .barrier) { [weak self] in
            guard let self = self,
                  let url = self.dataFileURL else { return }
            
            do {
                if FileManager.default.fileExists(atPath: url.path) {
                    try FileManager.default.removeItem(at: url)
                    self.logger.info("Cleared widget data")
                    
                    self.postChangeNotification()
                    
                    DispatchQueue.main.async {
                        WidgetCenter.shared.reloadAllTimelines()
                    }
                }
            } catch {
                self.logger.error("Failed to clear widget data: \(error.localizedDescription)")
            }
        }
    }
    
    func updateAuthState(userId: String?, userEmail: String?, isAuthenticated: Bool) {
        let currentData = load() ?? WidgetData()
        
        // Never downgrade auth state from true to false
        let finalAuthState = currentData.isAuthenticated || isAuthenticated
        
        print("🔐 updateAuthState: current=\(currentData.isAuthenticated), new=\(isAuthenticated), final=\(finalAuthState)")
        
        let updatedData = WidgetData(
            promises: currentData.promises,
            userId: userId ?? currentData.userId,  // Preserve existing if not provided
            userEmail: userEmail ?? currentData.userEmail,  // Preserve existing if not provided
            isAuthenticated: finalAuthState,  // Never downgrade
            lastUpdated: Date(),
            version: currentData.version
        )
        
        save(updatedData)
    }
    
    // MARK: - Promise Conversion
    
    func syncPromisesFromApp<T>(_ promises: [T], userId: String?, userEmail: String?, isAuthenticated: Bool,
                                transform: (T) -> WidgetPromiseData) {
        print("🔄 UnifiedSharedDataManager.syncPromisesFromApp called with \(promises.count) promises")
        NSLog("🔄 UnifiedSharedDataManager.syncPromisesFromApp called with \(promises.count) promises")
        
        let widgetPromises = promises.map(transform)
        print("🔄 Transformed \(widgetPromises.count) promises for widget")
        
        // CRITICAL FIX: Merge with existing data to preserve auth state
        let currentData = load() ?? WidgetData()
        
        // Never downgrade auth state from true to false
        let finalAuthState = currentData.isAuthenticated || isAuthenticated
        
        print("🔒 Auth state merge: current=\(currentData.isAuthenticated), new=\(isAuthenticated), final=\(finalAuthState)")
        
        let widgetData = WidgetData(
            promises: widgetPromises,
            userId: userId ?? currentData.userId,  // Preserve existing if not provided
            userEmail: userEmail ?? currentData.userEmail,  // Preserve existing if not provided
            isAuthenticated: finalAuthState,  // Never downgrade from true to false
            lastUpdated: Date()
        )
        
        print("📦 Created WidgetData with \(widgetData.promises.count) promises, auth=\(finalAuthState)")
        
        let success = save(widgetData)
        
        if success {
            print("✅ Widget data updated: \(widgetPromises.count) promises, auth=\(finalAuthState)")
            NSLog("✅ Widget data updated: \(widgetPromises.count) promises, auth=\(finalAuthState)")
        } else {
            print("❌ Failed to update widget data")
            NSLog("❌ Failed to update widget data")
        }
    }
    
    // MARK: - Private Methods
    
    private var dataFileURL: URL? {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: self.appGroupID
        ) else {
            self.logger.error("Failed to access App Group: \(self.appGroupID)")
            return nil
        }
        
        let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
        
        do {
            // Always ensure directory exists with proper permissions
            try FileManager.default.createDirectory(
                at: dataDirectory,
                withIntermediateDirectories: true,
                attributes: [
                    .posixPermissions: 0o755,
                    .protectionKey: FileProtectionType.none
                ]
            )
        } catch {
            // Directory might already exist, which is fine
            if !FileManager.default.fileExists(atPath: dataDirectory.path) {
                self.logger.error("Failed to create data directory: \(error.localizedDescription)")
                return nil
            }
        }
        
        return dataDirectory.appendingPathComponent(self.dataFileName)
    }
    
    private func verifyAppGroupAccess() {
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: self.appGroupID
        ) else {
            self.logger.error("❌ CRITICAL: Cannot access App Group '\(self.appGroupID)'")
            return
        }
        
        self.logger.info("✅ App Group accessible at: \(containerURL.path)")
        
        let testFile = containerURL.appendingPathComponent(".write_test")
        let testData = "test".data(using: .utf8)!
        
        do {
            try testData.write(to: testFile)
            try FileManager.default.removeItem(at: testFile)
            self.logger.info("✅ App Group write access verified")
        } catch {
            self.logger.error("❌ App Group write access failed: \(error.localizedDescription)")
        }
        
        let widgetDataDir = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
        do {
            try FileManager.default.createDirectory(at: widgetDataDir, withIntermediateDirectories: true)
            // Remove any file protection attributes that might block the widget
            try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: widgetDataDir.path)
            let jsonPath = widgetDataDir.appendingPathComponent(self.dataFileName).path
            if FileManager.default.fileExists(atPath: jsonPath) {
                try FileManager.default.setAttributes([.protectionKey: FileProtectionType.none], ofItemAtPath: jsonPath)
            }
            self.logger.info("✅ Cleared file protection attributes for WidgetData directory")
        } catch {
            self.logger.error("Failed to clear protection attributes: \(error.localizedDescription)")
        }
    }
    
    private func postChangeNotification() {
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName(self.changeNotificationName as CFString),
            nil,
            nil,
            true
        )
        
        self.logger.debug("Posted change notification: \(self.changeNotificationName)")
    }
    
    private func registerForChangeNotifications() {
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            { _, _, name, _, _ in
                DispatchQueue.main.async {
                    NotificationCenter.default.post(
                        name: .widgetDataDidChange,
                        object: nil
                    )
                }
            },
            self.changeNotificationName as CFString,
            nil,
            .deliverImmediately
        )
        
        self.logger.debug("Registered for change notifications")
    }
}

// MARK: - Notification Names
extension Notification.Name {
    static let widgetDataDidChange = Notification.Name("widgetDataDidChange")
}

// MARK: - Convenience Extensions
extension UnifiedSharedDataManager {
    var isAuthenticated: Bool {
        load()?.isAuthenticated ?? false
    }
    
    var promises: [WidgetPromiseData] {
        load()?.promises ?? []
    }
    
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