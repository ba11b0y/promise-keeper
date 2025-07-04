import WidgetKit
import SwiftUI
import AppIntents
import Foundation
import os.log

// MARK: - Remote Data Models
struct JSONPlaceholderPost: Codable {
    let id: Int
    let userId: Int
    let title: String
    let body: String
}

// MARK: - Widget Data Models
struct WidgetPromise: Codable, Identifiable {
    let id: String
    let created_at: Date
    let updated_at: Date
    let content: String
    let owner_id: String
    let resolved: Bool
    
    var isResolved: Bool { resolved }
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
    static let appGroupIdentifier = "group.TX645N2QBW.com.example.mac.SidebarApp"
    static let dataFileName = "widget_data.json"
    static let changeNotificationName = "com.promisekeeper.widget.datachanged"
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
        NSLog("🌐 Rahul: Attempting to load data from remote URL")
        
        guard let url = URL(string: "https://raw.githubusercontent.com/anaygupta2004/hello-world/refs/heads/master/widget_data.json") else {
            NSLog("❌ Rahul: Invalid remote URL")
            return nil
        }
        
        // Create a semaphore for synchronous network call (required for widget timeline)
        let semaphore = DispatchSemaphore(value: 0)
        var result: WidgetData?
        
        let task = URLSession.shared.dataTask(with: url) { data, response, error in
            defer { semaphore.signal() }
            
            if let error = error {
                NSLog("❌ Rahul: Network error: \(error)")
                return
            }
            
            guard let data = data else {
                NSLog("❌ Rahul: No data received from remote URL")
                return
            }
            
            NSLog("✅ Rahul: Received \(data.count) bytes from remote URL")
            
            do {
                // Parse the widget data directly (same format as local file)
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                
                let widgetData = try decoder.decode(WidgetData.self, from: data)
                NSLog("✅ Rahul: Decoded WidgetData from remote URL - promises: \(widgetData.promises.count), auth: \(widgetData.isAuthenticated)")
                
                result = widgetData
                
            } catch {
                NSLog("❌ Rahul: Failed to decode remote data: \(error)")
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
            let nextUpdate = Calendar.current.date(byAdding: .minute, value: 5, to: Date()) ?? Date()
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
        .onAppear {
            NSLog("📱 Rahul: Widget View appeared - auth: \(entry.isAuthenticated), promises: \(entry.promises.count)")
            NSLog("📱 Rahul: Entry promises isEmpty: \(entry.promises.isEmpty)")
            NSLog("📱 Rahul: PromisesToShow count: \(promisesToShow.count)")
            
            // Log which view path is taken
            if entry.isAuthenticated && !entry.promises.isEmpty {
                NSLog("📱 Rahul: Showing authenticatedView - promises: \(entry.promises.count)")
            } else if entry.isAuthenticated {
                NSLog("📱 Rahul: Showing 'no promises' view - authenticated but 0 promises")
            } else {
                NSLog("📱 Rahul: Showing unauthenticatedView - not authenticated")
            }
            
            // Log each promise for debugging
            for (index, promise) in entry.promises.enumerated() {
                NSLog("📱 Rahul: Promise \(index + 1): '\(promise.content)' - resolved: \(promise.resolved)")
            }
            
            // Log promisesToShow details
            for (index, promise) in promisesToShow.enumerated() {
                NSLog("📱 Rahul: PromisesToShow \(index + 1): '\(promise.content)' - resolved: \(promise.isResolved)")
            }
        }
    }
    
    private var authenticatedView: some View {
        VStack(spacing: family == .systemMedium ? 8 : 12) {
            // Header Section (Optimized for widget)
            headerSection
            
            // Statistics Cards (Compact for widget)
            statisticsSection
            
            // Promises List (Optimized for widget)
            promisesListSection
        }
        .padding(family == .systemMedium ? 12 : 16)
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
            
            Button("Open App") {
                // This will open the main app
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .containerBackground(Color.clear, for: .widget)
    }
    
    // MARK: - Header Section (Widget Optimized)
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(userGreeting)
                    .font(.system(size: family == .systemMedium ? 16 : 20, weight: .medium))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
                    .lineLimit(1)
                
                Text("\(completionPercentage)% completed • \(totalPromises) total")
                    .font(.system(size: family == .systemMedium ? 11 : 13, weight: .regular))
                    .foregroundColor(Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 0.6))
                    .lineLimit(1)
            }
            
            Spacer()
            
            if family == .systemLarge {
                // Add Promise Button (Large widget only)
                Button(intent: AddPromiseIntent()) {
                    Image(systemName: "plus.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.blue)
                }
                .buttonStyle(.plain)
            }
        }
    }
    
    // MARK: - Statistics Section (Widget Optimized)
    private var statisticsSection: some View {
        HStack(spacing: family == .systemMedium ? 8 : 12) {
            PromiseStatCard(
                icon: "checkmark.circle.fill",
                iconColor: .green,
                value: "\(completedPromises)",
                label: "Completed",
                compact: family == .systemMedium
            )
            
            PromiseStatCard(
                icon: "clock.fill",
                iconColor: .orange,
                value: "\(pendingPromises)",
                label: "Pending",
                compact: family == .systemMedium
            )
            
            if family == .systemLarge {
                PromiseStatCard(
                    icon: "chart.line.uptrend.xyaxis",
                    iconColor: .blue,
                    value: "\(completionPercentage)%",
                    label: "Progress",
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
                    .font(.system(size: family == .systemMedium ? 13 : 15, weight: .semibold))
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
                    .onAppear {
                        NSLog("📱 Rahul: Showing 'No promises yet' - entry.promises.isEmpty: \(entry.promises.isEmpty)")
                    }
            } else {
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: family == .systemMedium ? 4 : 6) {
                        ForEach(promisesToShow) { promise in
                            WidgetPromiseRow(promise: promise, compact: family == .systemMedium)
                                .transition(.opacity)
                                .onAppear {
                                    NSLog("📱 Rahul: Rendering promise row: '\(promise.content)'")
                                }
                        }
                    }
                }
                .frame(maxHeight: family == .systemMedium ? 120 : 200)
                .onAppear {
                    NSLog("📱 Rahul: Showing promises list - promisesToShow.count: \(promisesToShow.count)")
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
    let icon: String
    let iconColor: Color
    let value: String
    let label: String
    let compact: Bool
    
    var body: some View {
        VStack(spacing: compact ? 4 : 6) {
            HStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: compact ? 14 : 16))
                    .foregroundColor(iconColor)
                
                Text(value)
                    .font(.system(size: compact ? 16 : 20, weight: .semibold))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255))
            }
            
            Text(label)
                .font(.system(size: compact ? 10 : 12, weight: .regular))
                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, compact ? 8 : 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.8))
                .shadow(color: Color.black.opacity(0.05), radius: 2, x: 0, y: 1)
        )
    }
}

// MARK: - Promise Row Component
struct WidgetPromiseRow: View {
    let promise: PromiseData
    let compact: Bool
    
    var body: some View {
        Button(intent: TogglePromiseIntent(promiseId: promise.id)) {
            HStack(spacing: compact ? 8 : 10) {
                Image(systemName: promise.isResolved ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: compact ? 16 : 18))
                    .foregroundColor(promise.isResolved ? .green : Color(red: 209/255, green: 213/255, blue: 219/255))
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(promise.content)
                        .font(.system(size: compact ? 12 : 14, weight: .regular))
                        .foregroundColor(promise.isResolved 
                            ? Color(red: 156/255, green: 163/255, blue: 175/255)
                            : Color(red: 17/255, green: 24/255, blue: 39/255))
                        .lineLimit(compact ? 1 : 2)
                        .strikethrough(promise.isResolved)
                    
                    if !compact {
                        Text(promise.created_at, style: .relative)
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 156/255, green: 163/255, blue: 175/255))
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
    PromiseData(id: "1", created_at: Date(), updated_at: Date(), content: "Complete project proposal", owner_id: "sample-user-id", resolved: false),
    PromiseData(id: "2", created_at: Date().addingTimeInterval(-3600), updated_at: Date().addingTimeInterval(-3600), content: "Call mom this weekend", owner_id: "sample-user-id", resolved: true),
    PromiseData(id: "3", created_at: Date().addingTimeInterval(-7200), updated_at: Date().addingTimeInterval(-7200), content: "Finish reading book", owner_id: "sample-user-id", resolved: false)
]