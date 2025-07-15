import WidgetKit
import SwiftUI
import AppIntents
import Foundation
import os.log

// MARK: - Color Extension for Hex Support
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

// MARK: - Remote Data Models
struct JSONPlaceholderPost: Codable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

// MARK: - Widget Data Models
struct WidgetPromise: Codable, Identifiable {
    let promiseId: Int64?
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: UUID
    let resolved: Bool?
    let extracted_from_screenshot: Bool?
    let screenshot_id: String?
    let screenshot_timestamp: String?
    let resolved_screenshot_id: String?
    let resolved_screenshot_time: String?
    let resolved_reason: String?
    let extraction_data: String?
    let action: String?
    let metadata: String?
    let due_date: String?
    let person: String?
    let platform: String?
    
    var isResolved: Bool { resolved ?? false }
    
    // Identifiable conformance
    var id: String {
        return String(promiseId ?? 0)
    }
    
    // CodingKeys to map promiseId to "id" in JSON
    enum CodingKeys: String, CodingKey {
        case promiseId = "id"
        case created_at
        case updated_at
        case content
        case owner_id
        case resolved
        case extracted_from_screenshot
        case screenshot_id
        case screenshot_timestamp
        case resolved_screenshot_id
        case resolved_screenshot_time
        case resolved_reason
        case extraction_data
        case action
        case metadata
        case due_date
        case person
        case platform
    }
}

struct WidgetData: Codable {
    let promises: [WidgetPromise]
    let userId: String?
    let userEmail: String?
    let isAuthenticated: Bool
    let lastUpdated: Date
    let version: Int
    
    init(promises: [WidgetPromise] = [],
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

// MARK: - Widget Configuration Constants
struct WidgetConstants {
    static let appGroupIdentifier = "group.TX645N2QBW.com.example.mac.PromiseKeeper"
    static let dataFileName = "widget_data.json"
    static let changeNotificationName = "com.promisekeeper.widget.datachanged"
}

// MARK: - JWT Helper
private func extractUserIdFromToken(_ token: String) -> String? {
    let segments = token.split(separator: ".")
    guard segments.count > 1 else { return nil }
    
    var base64String = String(segments[1])
    // Pad the base64 string if needed
    let remainder = base64String.count % 4
    if remainder > 0 {
        base64String += String(repeating: "=", count: 4 - remainder)
    }
    
    guard let data = Data(base64Encoded: base64String) else { return nil }
    
    do {
        if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
           let sub = json["sub"] as? String {
            return sub
        }
    } catch {
        NSLog("❌ Failed to parse JWT payload: \(error)")
    }
    
    return nil
}

// MARK: - Unified Data Manager (widget access)
class WidgetUnifiedDataManager {
    static let shared = WidgetUnifiedDataManager()
    
    private let appGroupID = WidgetConstants.appGroupIdentifier
    private let dataFileName = WidgetConstants.dataFileName
    
    private let decoder: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }()
    
    private init() {
        // Log initialization
        NSLog("🔄 WidgetUnifiedDataManager initialized with App Group: \(appGroupID)")
    }
    
    func load() -> WidgetData? {
        NSLog("🔄 Rahul: WidgetUnifiedDataManager.load() START at \(Date())")
        
        // Try to fetch from remote URL first
        if let remoteData = loadFromRemoteURL() {
            NSLog("✅ Rahul: Successfully loaded data from remote URL")
            return remoteData
        }
        
        // Fallback to local file system if remote fails
        return loadFromLocalFile()
    }
    
    private func loadFromRemoteURL() -> WidgetData? {
        NSLog("🌐 Rahul: Attempting to load data from Supabase")
        
        // Get JWT token from keychain
        guard let accessToken = SharedSupabaseManager.getAccessTokenForWidget() else {
            NSLog("❌ Rahul: No valid access token found (expired or missing)")
            // Don't try to make network calls with expired token
            // Fall back to local data instead
            return nil
        }
        
        // Extract user ID from JWT token
        guard let userId = extractUserIdFromToken(accessToken) else {
            NSLog("❌ Rahul: Could not extract user ID from token")
            return nil
        }
        
        // Configure Supabase URL with owner_id filter - using the 'promises' table
        guard let url = URL(string: "https://msucqyacicicjkakvurq.supabase.co/rest/v1/promises?owner_id=eq.\(userId)&select=*") else {
            NSLog("❌ Rahul: Invalid Supabase URL")
            return nil
        }
        
        NSLog("✅ Rahul: Fetching widget data for user: \(userId)")
        
        // Create a semaphore for synchronous network call (required for widget timeline)
        let semaphore = DispatchSemaphore(value: 0)
        var result: WidgetData?
        
        // Create request with authentication headers
        var request = URLRequest(url: url)
        request.setValue("Bearer \(accessToken)", forHTTPHeaderField: "Authorization")
        request.setValue("eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zdWNxeWFjaWNpY2prYWt2dXJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjcyMDgsImV4cCI6MjA2NjEwMzIwOH0.dqV_-pUx8yJbyv2m1c-O5syFoKERKLEF0bDimtv0lro", forHTTPHeaderField: "apikey")
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpMethod = "GET"
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                NSLog("❌ Rahul: Network error: \(error)")
                return
            }
            
            // Check HTTP response status
            if let httpResponse = response as? HTTPURLResponse {
                NSLog("📡 Rahul: HTTP Response Status Code: \(httpResponse.statusCode)")
                if httpResponse.statusCode != 200 {
                    NSLog("❌ Rahul: Non-200 status code: \(httpResponse.statusCode)")
                    if let data = data, let errorString = String(data: data, encoding: .utf8) {
                        NSLog("❌ Rahul: Error response: \(errorString)")
                        
                        // If JWT expired (401), clear cached token and force re-authentication
                        if httpResponse.statusCode == 401 && errorString.contains("JWT expired") {
                            NSLog("🔄 Rahul: JWT expired, need fresh token from main app")
                            // Widget can't refresh tokens, user needs to open main app
                        }
                    }
                    return
                }
            }
            
            guard let data = data else {
                NSLog("❌ Rahul: No data received from Supabase")
                return
            }
            
            NSLog("✅ Rahul: Received \(data.count) bytes from Supabase")
            
            do {
                // Supabase returns an array of Promise records
                let decoder = JSONDecoder()
                
                // Custom date decoding strategy for Supabase timestamps
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.timeZone = TimeZone(secondsFromGMT: 0)
                
                decoder.dateDecodingStrategy = .custom { decoder in
                    let container = try decoder.singleValueContainer()
                    let dateString = try container.decode(String.self)
                    
                    // Try different date formats that Supabase might use
                    // Format 1: With milliseconds and timezone
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSSX"
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Format 2: With timezone but no milliseconds
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssX"
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Format 3: No timezone (assumes UTC)
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    // Format 4: With fractional seconds but no timezone
                    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSSSS"
                    if let date = formatter.date(from: dateString) {
                        return date
                    }
                    
                    throw DecodingError.dataCorruptedError(in: container, debugDescription: "Cannot decode date string \(dateString)")
                }
                
                // Decode the promises array from Supabase
                let promises = try decoder.decode([WidgetPromise].self, from: data)
                NSLog("✅ Rahul: Decoded \(promises.count) promises from Supabase")
                
                // Create WidgetData from the promises
                let widgetData = WidgetData(
                    promises: promises,
                    userId: userId,
                    userEmail: nil,
                    isAuthenticated: true,
                    lastUpdated: Date(),
                    version: 1
                )
                
                result = widgetData
                
            } catch {
                NSLog("❌ Rahul: Failed to decode Supabase data: \(error)")
                if let dataString = String(data: data, encoding: .utf8) {
                    NSLog("❌ Rahul: Raw response data: \(dataString.prefix(500))...")
                }
            }
        }
        
        task.resume()
        
        // Wait for network request to complete (max 5 seconds)
        let timeout = DispatchTime.now() + .seconds(5)
        if semaphore.wait(timeout: timeout) == .timedOut {
            NSLog("⏰ Rahul: Network request timed out")
            task.cancel()
            return nil
        }
        
        return result
    }
    
    private func loadFromLocalFile() -> WidgetData? {
        NSLog("📁 Rahul: Falling back to local file system")
        
        guard let containerURL = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: appGroupID
        ) else {
            NSLog("❌ Rahul: Cannot access App Group '\(appGroupID)'")
            return nil
        }
        
        NSLog("✅ Rahul: App Group accessible at: \(containerURL.path)")
        
        // Try to get security-scoped access to the container first
        let containerAccessing = containerURL.startAccessingSecurityScopedResource()
        NSLog("🔐 Rahul: Container security-scoped access: \(containerAccessing)")
        
        defer {
            if containerAccessing {
                containerURL.stopAccessingSecurityScopedResource()
                NSLog("🔐 Rahul: Stopped container security-scoped access")
            }
        }
        
        let dataDirectory = containerURL.appendingPathComponent("WidgetData", isDirectory: true)
        let dataFileURL = dataDirectory.appendingPathComponent(dataFileName)
        
        NSLog("📂 Rahul: Looking for data at: \(dataFileURL.path)")
        NSLog("📂 Rahul: Container URL: \(containerURL.path)")
        NSLog("📂 Rahul: Data file URL absolute string: \(dataFileURL.absoluteString)")
        NSLog("📂 Rahul: URL scheme: \(dataFileURL.scheme ?? "none")")
        
        // Try to get security-scoped bookmark data
        do {
            let resourceValues = try dataFileURL.resourceValues(forKeys: [.isDirectoryKey, .fileSizeKey, .isReadableKey])
            NSLog("📂 Rahul: URL resource values: \(resourceValues)")
        } catch {
            NSLog("📂 Rahul: Could not get resource values: \(error)")
        }
        
        // Check file existence using URL-based resource values (sandbox-friendly)
        do {
            let resourceValues = try dataFileURL.resourceValues(forKeys: [.isRegularFileKey])
            guard resourceValues.isRegularFile == true else {
                NSLog("📱 Rahul: No unified data file found at URL")
                return nil
            }
        } catch {
            NSLog("📱 Rahul: Cannot access file resource values: \(error)")
            return nil
        }
        
        do {
            // Try multiple read approaches
            var data: Data?
            
            // Approach 1: Security-scoped resource access (required for widgets on real devices)
            // Make file explicitly accessible (ignore return value like in working examples)
            _ = dataFileURL.startAccessingSecurityScopedResource()
            
            defer {
                dataFileURL.stopAccessingSecurityScopedResource()
                NSLog("🔐 Rahul: Stopped file security-scoped access")
            }
            
            NSLog("🔐 Rahul: Made file explicitly accessible, attempting read...")
            
            do {
                data = try Data(contentsOf: dataFileURL, options: [.uncached, .mappedIfSafe])
                NSLog("✅ Rahul: Read succeeded with explicit security-scoped Data(contentsOf:)")
            } catch {
                NSLog("❌ Rahul: Explicit security-scoped Data(contentsOf:) failed: \(error)")
            }
            
            // If security-scoped access failed or didn't work, try fallback methods
            if data == nil {
                NSLog("🔄 Rahul: Trying fallback methods...")
                
                // Approach 2: Try NSFileCoordinator (might be needed for app group files)
                var coordinatorError: NSError?
                let coordinator = NSFileCoordinator()
                coordinator.coordinate(readingItemAt: dataFileURL, options: [], error: &coordinatorError) { (url) in
                    do {
                        data = try Data(contentsOf: url)
                        NSLog("✅ Rahul: Read succeeded with NSFileCoordinator")
                    } catch {
                        NSLog("❌ Rahul: NSFileCoordinator read failed: \(error)")
                    }
                }
                
                if let coordError = coordinatorError {
                    NSLog("❌ Rahul: NSFileCoordinator coordination failed: \(coordError)")
                }
                
                // Approach 3: Try regular FileManager (might work in simulator)
                if data == nil, let fileData = FileManager.default.contents(atPath: dataFileURL.path) {
                    data = fileData
                    NSLog("✅ Rahul: Read succeeded with regular FileManager.contents")
                } else if data == nil {
                    NSLog("❌ Rahul: Regular FileManager.contents also failed - trying UserDefaults fallback")
                    
                    // Approach 4: UserDefaults fallback (more reliable for widgets)
                    if let userDefaults = UserDefaults(suiteName: appGroupID) {
                        // Try new unified data format first
                        if let defaultsData = userDefaults.data(forKey: "widget_data") {
                            data = defaultsData
                            NSLog("✅ Rahul: Read succeeded with UserDefaults (unified format)")
                        }
                        // Fall back to legacy format
                        else if let promisesData = userDefaults.data(forKey: "widget_promises") {
                            let isAuth = userDefaults.bool(forKey: "widget_is_authenticated")
                            let userId = userDefaults.string(forKey: "widget_user_id")
                            let lastSync = userDefaults.object(forKey: "widget_last_sync_time") as? Date ?? Date()
                            
                            // Convert legacy format to new format
                            do {
                                let promises = try decoder.decode([WidgetPromise].self, from: promisesData)
                                let widgetData = WidgetData(
                                    promises: promises,
                                    userId: userId,
                                    userEmail: nil,
                                    isAuthenticated: isAuth,
                                    lastUpdated: lastSync
                                )
                                let encoder = JSONEncoder()
                                encoder.dateEncodingStrategy = .iso8601
                                data = try encoder.encode(widgetData)
                                NSLog("✅ Rahul: Read succeeded with UserDefaults (legacy format) - converted to unified")
                            } catch {
                                NSLog("❌ Rahul: Failed to convert legacy UserDefaults data: \(error)")
                            }
                        } else {
                            NSLog("❌ Rahul: UserDefaults fallback also failed - no data found")
                        }
                    } else {
                        NSLog("❌ Rahul: Cannot access UserDefaults for app group")
                    }
                }
            }
            
            guard let finalData = data else {
                NSLog("❌ Rahul: All read methods failed")
                return nil
            }
            
            let widgetData = try decoder.decode(WidgetData.self, from: finalData)
            NSLog("✅ Rahul: Successfully decoded data - promises: \(widgetData.promises.count), auth: \(widgetData.isAuthenticated)")
            
            // Log promise details
            NSLog("📋 Rahul: Promise details:")
            for (index, promise) in widgetData.promises.enumerated() {
                NSLog("  Promise \(index + 1): '\(promise.content)' - resolved: \(promise.resolved), id: \(promise.id)")
            }
            
            return widgetData
        } catch {
            NSLog("❌ Rahul: Failed to decode data: \(error)")
            return nil
        }
    }
    
    // MARK: - Legacy Fallback
    // Commented out to force widget to use only file-based storage
    /*
    private func loadFromUserDefaults() -> WidgetData? {
        guard let defaults = UserDefaults(suiteName: appGroupID) else {
            print("❌ Widget Fallback: Cannot access UserDefaults for App Group")
            return nil
        }
        
        struct LegacyKeys {
            static let promises = "widget_promises"
            static let isAuthenticated = "widget_is_authenticated"
            static let userId = "widget_user_id"
        }
        
        guard let data = defaults.data(forKey: LegacyKeys.promises) else {
            print("📱 Widget Fallback: No legacy promises data found")
            return nil
        }
        
        do {
            let legacyPromises = try decoder.decode([WidgetPromise].self, from: data)
            let isAuth = (defaults.object(forKey: LegacyKeys.isAuthenticated) as? NSNumber)?.boolValue ?? false
            let uid = defaults.string(forKey: LegacyKeys.userId)
            
            print("✅ Widget Fallback: Loaded legacy data – promises=\(legacyPromises.count), auth=\(isAuth)")
            
            return WidgetData(
                promises: legacyPromises,
                userId: uid,
                userEmail: nil,
                isAuthenticated: isAuth,
                lastUpdated: Date()
            )
        } catch {
            print("❌ Widget Fallback: Failed to decode legacy promises: \(error)")
            return nil
        }
    }
    */
}

// MARK: - App Intents for Widget Interactions
struct TogglePromiseIntent: AppIntent {
    static var title: LocalizedStringResource = "Toggle Promise"
    
    @Parameter(title: "Promise ID")
    var promiseId: String
    
    init() {
        self.promiseId = ""
    }
    
    init(promiseId: String) {
        self.promiseId = promiseId
    }
    
    func perform() async throws -> some IntentResult {
        // TODO: Implement promise toggling by communicating with main app
        print("Widget toggle attempted for promise \(promiseId) - opening main app")
        return .result()
    }
}

struct AddPromiseIntent: AppIntent {
    static var title: LocalizedStringResource = "Add Promise"
    static var openAppWhenRun: Bool = true
    
    func perform() async throws -> some IntentResult {
        return .result()
    }
}

// Widget-specific type alias to avoid ambiguity
typealias PromiseData = WidgetPromise

// MARK: - Widget Entry
struct PromiseEntry: TimelineEntry {
    let date: Date
    let promises: [PromiseData]
    let currentUserId: String?
    let isAuthenticated: Bool
}

// MARK: - Promise Provider (Real Supabase Data)
struct PromiseProvider: TimelineProvider {
    func placeholder(in context: Context) -> PromiseEntry {
        PromiseEntry(
            date: Date(),
            promises: samplePromises,
            currentUserId: "sample-user-id",
            isAuthenticated: true
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (PromiseEntry) -> ()) {
        NSLog("📱 Widget: getSnapshot() called - context: \(context)")
        Task {
            let entry = await fetchRealData()
            NSLog("📱 Widget: getSnapshot() returning entry with \(entry.promises.count) promises")
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        NSLog("📱 Widget: getTimeline() called - context: \(context)")
        Task {
            NSLog("📱 Widget: Starting fetchRealData in getTimeline")
            let entry = await fetchRealData()
            let nextUpdate = Calendar.current.date(byAdding: .second, value: 1, to: Date()) ?? Date()
            let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
            NSLog("📱 Widget: timeline created with \(entry.promises.count) promises, next update at \(nextUpdate)")
            completion(timeline)
        }
    }
    
    private func fetchRealData() async -> PromiseEntry {
        NSLog("📱 Widget: fetchRealData() called - WIDGET IS RUNNING!")
        
        // Add debug info about the process
        NSLog("🔍 Widget Process Info: Process=\(ProcessInfo.processInfo.processName), Bundle=\(Bundle.main.bundleIdentifier ?? "unknown")")
        
        NSLog("📱 Rahul: About to call WidgetUnifiedDataManager.shared.load()")
        
        // Load data using the unified data manager
        let data = WidgetUnifiedDataManager.shared.load()
        
        NSLog("📱 Rahul: WidgetUnifiedDataManager.shared.load() returned: \(data != nil ? "data" : "nil")")
        
        if let data = data {
            NSLog("✅ Widget: Data loaded - promises=\(data.promises.count), auth=\(data.isAuthenticated), user=\(data.userEmail ?? "none"), lastUpdated=\(data.lastUpdated)")
            
            // Log first promise for debugging
            if let firstPromise = data.promises.first {
                NSLog("   - First promise: \(firstPromise.content.prefix(50))...")
            }
        } else {
            NSLog("❌ Rahul: Widget failed to load unified data - data is nil")
        }
        
        let widgetData = data ?? WidgetData()
        
        NSLog("📱 Widget: Returning entry with \(widgetData.promises.count) promises, authenticated: \(widgetData.isAuthenticated)")
        
        // Use promises directly from WidgetData
        return PromiseEntry(
            date: Date(),
            promises: widgetData.promises,
            currentUserId: widgetData.userId,
            isAuthenticated: widgetData.isAuthenticated
        )
    }
}

// MARK: - Widget Entry View (Exact Electron Design)
struct PromiseWidgetEntryView: View {
    var entry: PromiseEntry
    @Environment(\.widgetFamily) var family

    var body: some View {
        Group {
            if entry.isAuthenticated && !entry.promises.isEmpty {
                authenticatedView
            } else if entry.isAuthenticated {
                // Authenticated but no promises yet
                VStack(spacing: 12) {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32))
                        .foregroundStyle(.green)
                    
                    Text("No promises yet")
                        .font(.headline)
                    
                    Text("Add your first promise in the app")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                .containerBackground(Color.clear, for: .widget)
            } else {
                unauthenticatedView
            }
        }
    }
    
    private var authenticatedView: some View {
        VStack(spacing: family == .systemMedium ? 6 : 10) {
            // Logo and Brand Section
            HStack(spacing: 8) {
                // Logo icon
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 59/255, green: 130/255, blue: 246/255, opacity: 0.2),
                                    Color(red: 147/255, green: 51/255, blue: 234/255, opacity: 0.2)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 24, height: 24)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255, opacity: 0.8))
                }
                
                Text("PromiseKeeper")
                    .font(.system(size: family == .systemMedium ? 18 : 20, weight: .light))
                    .foregroundColor(Color(red: 15/255, green: 23/255, blue: 42/255, opacity: 0.9))
                    .kerning(-0.02)
                
                Spacer()
            }
            .padding(.bottom, family == .systemMedium ? 2 : 4)
            
            // Header Section (Optimized for widget)
            headerSection
            
            // Statistics Cards (Compact for widget)
            statisticsSection
            
            // Promises List (Optimized for widget)
            promisesListSection
        }
        .padding(.horizontal, family == .systemMedium ? 4 : 6)
        .padding(.bottom, family == .systemMedium ? 4 : 6)
        .padding(.top, family == .systemMedium ? 2 : 0)
        .containerBackground(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 250/255, green: 250/255, blue: 252/255),
                    Color(red: 245/255, green: 245/255, blue: 248/255)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ), for: .widget
        )
    }
    
    private var unauthenticatedView: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.crop.circle.badge.exclamationmark")
                .font(.system(size: 32))
                .foregroundStyle(.secondary)
            
            Text("Sign in to view promises")
                .font(.headline)
                .foregroundStyle(.primary)
            
            Link("Open App", destination: URL(string: "sidebarapp://open")!)
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .containerBackground(Color.clear, for: .widget)
    }
    
    // MARK: - Header Section (Widget Optimized)
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 1) {
                Text(userGreeting)
                    .font(.system(size: family == .systemMedium ? 14 : 16, weight: .medium))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
                    .lineLimit(1)
                
                Text("\(completionPercentage)% completed • \(totalPromises) total")
                    .font(.system(size: family == .systemMedium ? 10 : 11, weight: .regular))
                    .foregroundColor(Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if family == .systemLarge {
                // Add Promise Button (Large widget only)
                Button(intent: AddPromiseIntent()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Statistics Section (Widget Optimized)
    private var statisticsSection: some View {
        HStack(spacing: family == .systemMedium ? 8 : 10) {
            // Total Promises (Orange)
            PromiseStatCard(
                value: "\(totalPromises)",
                label: "Total",
                gradientColors: [
                    Color(red: 249/255, green: 115/255, blue: 22/255, opacity: 0.4),
                    Color(red: 254/255, green: 215/255, blue: 170/255, opacity: 0.25)
                ],
                borderColor: Color(red: 249/255, green: 115/255, blue: 22/255, opacity: 0.25),
                backgroundColor: Color(red: 249/255, green: 115/255, blue: 22/255, opacity: 0.08),
                compact: family == .systemMedium
            )
            
            // Completed (Green)
            PromiseStatCard(
                value: "\(completedPromises)",
                label: "Completed",
                gradientColors: [
                    Color(red: 34/255, green: 197/255, blue: 94/255, opacity: 0.4),
                    Color(red: 134/255, green: 239/255, blue: 172/255, opacity: 0.25)
                ],
                borderColor: Color(red: 34/255, green: 197/255, blue: 94/255, opacity: 0.25),
                backgroundColor: Color(red: 34/255, green: 197/255, blue: 94/255, opacity: 0.08),
                compact: family == .systemMedium
            )
            
            // Pending (Red) - only show on large widget
            if family == .systemLarge {
                PromiseStatCard(
                    value: "\(pendingPromises)",
                    label: "Pending",
                    gradientColors: [
                        Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.4),
                        Color(red: 252/255, green: 165/255, blue: 165/255, opacity: 0.25)
                    ],
                    borderColor: Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.25),
                    backgroundColor: Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.08),
                    compact: false
                )
            }
        }
    }
    
    // MARK: - Promises List Section (Widget Optimized)
    private var promisesListSection: some View {
        VStack(alignment: .leading, spacing: family == .systemMedium ? 6 : 8) {
            HStack {
                Text("All Promises")
                    .font(.system(size: family == .systemMedium ? 13 : 15, weight: .medium))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
                
                Spacer()
                
                if promisesToShow.count > maxPromises {
                    Text("+\(promisesToShow.count - maxPromises) more")
                        .font(.system(size: family == .systemMedium ? 10 : 11, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
            
            if entry.promises.isEmpty {
                Text("No promises yet")
                    .font(.system(size: family == .systemMedium ? 12 : 14))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 20)
            } else {
                VStack(alignment: .leading, spacing: family == .systemMedium ? 4 : 6) {
                    ForEach(promisesToShow.prefix(maxPromises)) { promise in
                        WidgetPromiseRow(promise: promise, compact: family == .systemMedium)
                    }
                }
            }
        }
    }
    
    // MARK: - Helpers
    private var userGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let greeting = hour < 12 ? "Good Morning" : hour < 18 ? "Good Afternoon" : "Good Evening"
        return greeting
    }
    
    private var totalPromises: Int {
        entry.promises.count
    }
    
    private var completedPromises: Int {
        entry.promises.filter { $0.isResolved }.count
    }
    
    private var pendingPromises: Int {
        totalPromises - completedPromises
    }
    
    private var completionPercentage: Int {
        guard totalPromises > 0 else { return 0 }
        return Int((Double(completedPromises) / Double(totalPromises)) * 100)
    }
    
    private var promisesToShow: [PromiseData] {
        // Show unresolved promises first, then resolved
        let unresolved = entry.promises.filter { !$0.isResolved }
        let resolved = entry.promises.filter { $0.isResolved }
        return unresolved + resolved
    }
    
    private var maxPromises: Int {
        family == .systemMedium ? 4 : 8
    }
    
}

// MARK: - Stat Card Component
struct PromiseStatCard: View {
    let value: String
    let label: String
    let gradientColors: [Color]
    let borderColor: Color
    let backgroundColor: Color
    let compact: Bool
    
    var body: some View {
        VStack(spacing: compact ? 4 : 6) {
            Text(value)
                .font(.system(size: compact ? 16 : 20, weight: .semibold))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
                .kerning(-0.02)
            
            Text(label.uppercased())
                .font(.system(size: compact ? 9 : 10, weight: .medium))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
                .kerning(0.08)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, compact ? 8 : 12)
        .padding(.vertical, compact ? 4 : 6)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: compact ? 8 : 12)
                    .fill(backgroundColor)
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: compact ? 8 : 12)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: gradientColors),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ).opacity(0.25)
                    )
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: compact ? 8 : 12)
                .strokeBorder(borderColor, lineWidth: 0.5)
        )
        .shadow(color: Color.black.opacity(0.03), radius: 4, x: 0, y: 2)
    }
}

// MARK: - Promise Row Component
struct WidgetPromiseRow: View {
    let promise: PromiseData
    let compact: Bool
    
    var body: some View {
        Button(intent: TogglePromiseIntent(promiseId: String(promise.promiseId ?? 0))) {
            HStack(spacing: compact ? 8 : 10) {
                Image(systemName: promise.isResolved ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: compact ? 16 : 18))
                    .foregroundColor(promise.isResolved ? .green : Color(red: 209/255, green: 213/255, blue: 219/255))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(promise.content)
                        .font(.system(size: compact ? 12 : 14, weight: .medium))
                        .foregroundColor(promise.isResolved 
                            ? Color(red: 156/255, green: 163/255, blue: 175/255)
                            : Color(red: 17/255, green: 24/255, blue: 39/255))
                        .lineLimit(compact ? 1 : 2)
                        .strikethrough(promise.isResolved)
                    
                    if !compact {
                        // Show metadata row with person, platform, due date
                        HStack(spacing: 6) {
                            // Platform icon
                            if let platform = promise.platform {
                                Image(systemName: platformIconName(for: platform))
                                    .font(.system(size: 9))
                                    .foregroundColor(Color(hex: platformColor(for: platform)))
                            }
                            
                            // Person
                            if let person = promise.person {
                                HStack(spacing: 2) {
                                    Image(systemName: "person.fill")
                                        .font(.system(size: 9))
                                    Text(person)
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
                            }
                            
                            // Due date
                            if let dueDate = promise.due_date,
                               let formattedDue = formatDueDate(dueDate) {
                                HStack(spacing: 2) {
                                    Image(systemName: "calendar")
                                        .font(.system(size: 9))
                                    Text(formattedDue)
                                        .font(.system(size: 10))
                                }
                                .foregroundColor(isOverdue(dueDate) 
                                    ? Color(red: 239/255, green: 68/255, blue: 68/255)
                                    : Color(red: 156/255, green: 163/255, blue: 175/255))
                            } else {
                                // Show created date if no due date
                                Text(promise.created_at, style: .relative)
                                    .font(.system(size: 11))
                                    .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
                            }
                            
                            Spacer()
                        }
                    }
                }
                
                Spacer()
            }
            .padding(.vertical, compact ? 6 : 8)
            .padding(.horizontal, compact ? 10 : 12)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.6))
            )
        }
        .buttonStyle(.plain)
    }
    
    // Helper functions for platform icons and colors
    private func platformIconName(for platform: String) -> String {
        switch platform.lowercased() {
        case "messages", "imessage":
            return "message.fill"
        case "discord":
            return "gamecontroller.fill"
        case "slack":
            return "number.square.fill"
        case "email", "mail":
            return "envelope.fill"
        case "whatsapp":
            return "phone.circle.fill"
        case "teams", "microsoft teams":
            return "person.3.fill"
        case "telegram":
            return "paperplane.fill"
        default:
            return "bubble.left.and.bubble.right"
        }
    }
    
    private func platformColor(for platform: String) -> String {
        switch platform.lowercased() {
        case "messages", "imessage":
            return "#34C759"
        case "discord":
            return "#5865F2"
        case "slack":
            return "#4A154B"
        case "whatsapp":
            return "#25D366"
        case "teams", "microsoft teams":
            return "#5059C9"
        case "telegram":
            return "#0088CC"
        default:
            return "#007AFF"
        }
    }
    
    private func formatDueDate(_ dueDateString: String) -> String? {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let date = formatter.date(from: dueDateString) else { return nil }
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
    
    private func isOverdue(_ dueDateString: String) -> Bool {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        guard let dueDate = formatter.date(from: dueDateString) else { return false }
        return dueDate < Date()
    }
}

// MARK: - Main Widget
struct PromiseWidget: Widget {
    let kind: String = "PromiseWidget"
    
    init() {
        // Try multiple logging methods
        NSLog("📱 Rahul: PromiseWidget init() called at \(Date()) - VERSION 2025-07-04-05:00")
        print("📱 Rahul: PromiseWidget init() called at \(Date()) - VERSION 2025-07-04-05:00")
        os_log("📱 Rahul: PromiseWidget init() called at %@ - VERSION 2025-07-04-05:00", log: OSLog.default, type: .default, "\(Date())")
        
        // Set up Darwin notification listener for data changes
        let notificationName = WidgetConstants.changeNotificationName as CFString
        let callback: CFNotificationCallback = { _, _, _, _, _ in
            NSLog("📱 Rahul: Received data change notification")
            WidgetCenter.shared.reloadAllTimelines()
        }
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            callback,
            notificationName,
            nil,
            .deliverImmediately
        )
        
        NSLog("📱 Rahul: Widget initialized and listening for notifications")
    }

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: PromiseProvider()) { entry in
            PromiseWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Promise Keeper")
        .description("Track your promises and commitments with the same beautiful interface.")
        .supportedFamilies([.systemMedium, .systemLarge])
    }
}

// MARK: - Sample Data (fallback)
let samplePromises = [
    PromiseData(promiseId: 1, created_at: Date(), updated_at: Date(), content: "Complete project proposal", owner_id: UUID(), resolved: false, extracted_from_screenshot: false, screenshot_id: nil, screenshot_timestamp: nil, resolved_screenshot_id: nil, resolved_screenshot_time: nil, resolved_reason: nil, extraction_data: nil, action: nil, metadata: nil, due_date: "2025-07-20", person: "Jane", platform: "Slack"),
    PromiseData(promiseId: 2, created_at: Date().addingTimeInterval(-3600), updated_at: Date().addingTimeInterval(-3600), content: "Call mom this weekend", owner_id: UUID(), resolved: true, extracted_from_screenshot: false, screenshot_id: nil, screenshot_timestamp: nil, resolved_screenshot_id: nil, resolved_screenshot_time: nil, resolved_reason: nil, extraction_data: nil, action: nil, metadata: nil, due_date: nil, person: "Mom", platform: "Phone"),
    PromiseData(promiseId: 3, created_at: Date().addingTimeInterval(-7200), updated_at: Date().addingTimeInterval(-7200), content: "Finish reading book", owner_id: UUID(), resolved: false, extracted_from_screenshot: false, screenshot_id: nil, screenshot_timestamp: nil, resolved_screenshot_id: nil, resolved_screenshot_time: nil, resolved_reason: nil, extraction_data: nil, action: nil, metadata: nil, due_date: "2025-07-18", person: nil, platform: nil)
]