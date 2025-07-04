import Foundation

// MARK: - Unified Widget Promise Model
/// Single source of truth for promise data shared between app and widget
public struct WidgetPromise: Codable, Identifiable, Equatable {
    public let id: String
    public let created_at: Date
    public let updated_at: Date
    public let content: String
    public let owner_id: String
    public let resolved: Bool
    
    // MARK: - Computed Properties
    public var isResolved: Bool { resolved }
    public var createdAt: Date { created_at }
    public var updatedAt: Date { updated_at }
    
    // MARK: - Initializer
    public init(id: String, created_at: Date, updated_at: Date, content: String, owner_id: String, resolved: Bool) {
        self.id = id
        self.created_at = created_at
        self.updated_at = updated_at
        self.content = content
        self.owner_id = owner_id
        self.resolved = resolved
    }
}

// MARK: - Widget Data Container
/// Atomic container for all widget-related data
public struct WidgetData: Codable, Equatable {
    public let promises: [WidgetPromise]
    public let userId: String?
    public let userEmail: String?
    public let isAuthenticated: Bool
    public let lastUpdated: Date
    public let version: Int
    
    // MARK: - Computed Properties
    public var totalPromises: Int { promises.count }
    public var completedPromises: Int { promises.filter { $0.isResolved }.count }
    public var pendingPromises: Int { totalPromises - completedPromises }
    public var completionPercentage: Int {
        totalPromises > 0 ? Int((Double(completedPromises) / Double(totalPromises)) * 100) : 0
    }
    
    // MARK: - Initializer
    public init(promises: [WidgetPromise] = [],
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

// MARK: - Configuration
public struct WidgetConfiguration {
    public static let appGroupIdentifier = "group.TX645N2QBW.com.example.mac.SidebarApp"
    public static let dataFileName = "widget_data.json"
    public static let changeNotificationName = "com.promisekeeper.widget.datachanged"
    public static let keychainAccessGroup = "TX645N2QBW.com.example.mac.SidebarApp"
}