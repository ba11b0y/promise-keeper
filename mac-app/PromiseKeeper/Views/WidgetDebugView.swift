import SwiftUI
import WidgetKit

struct WidgetDebugView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var logContent: String = "Loading logs..."
    @State private var userDefaultsLogs: [[String: Any]] = []
    @State private var lastLogTime: Date?
    @State private var autoRefresh = false
    @State private var showingOldDebugView = false
    
    private let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                Label("Widget Debug Logs", systemImage: "doc.text.magnifyingglass")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Toggle("Auto Refresh", isOn: $autoRefresh)
                    .toggleStyle(.checkbox)
                
                Button("Refresh") {
                    loadLogs()
                }
                .buttonStyle(.bordered)
                
                Button("Clear Logs") {
                    clearLogs()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.regular)
                
                Button("Old Debug View") {
                    showingOldDebugView = true
                }
                .buttonStyle(.link)
            }
            .padding()
            
            Divider()
            
            // Widget Status
            HStack {
                Label("Widget Status:", systemImage: "app.badge")
                    .foregroundStyle(.secondary)
                
                if isWidgetRunning() {
                    Text("Running")
                        .foregroundColor(.green)
                        .fontWeight(.medium)
                } else {
                    Text("Not Running")
                        .foregroundColor(.red)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Log file path
                if let logPath = getLogFilePath() {
                    Label("Log file:", systemImage: "folder")
                        .foregroundStyle(.secondary)
                    Text(logPath)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                }
            }
            .padding(.horizontal)
            
            // Last update time
            if let lastLogTime = lastLogTime {
                HStack {
                    Label("Last log:", systemImage: "clock")
                        .foregroundStyle(.secondary)
                    Text(lastLogTime, style: .relative)
                    Spacer()
                }
                .padding(.horizontal)
            }
            
            // Log content
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    Text("File Logs:")
                        .font(.headline)
                        .padding(.horizontal)
                    
                    Text(logContent)
                        .font(.system(.body, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                        .padding(.horizontal)
                    
                    if !userDefaultsLogs.isEmpty {
                        Text("Recent UserDefaults Logs:")
                            .font(.headline)
                            .padding(.horizontal)
                            .padding(.top)
                        
                        ForEach(userDefaultsLogs.indices, id: \.self) { index in
                            let log = userDefaultsLogs[index]
                            if let timestamp = log["timestamp"] as? Date,
                               let message = log["message"] as? String,
                               let type = log["type"] as? String {
                                HStack(alignment: .top, spacing: 8) {
                                    Text(timestamp, style: .time)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .frame(width: 60, alignment: .trailing)
                                    
                                    Text("[\(type)]")
                                        .font(.caption)
                                        .foregroundStyle(colorForLogType(type))
                                        .frame(width: 60)
                                    
                                    Text(message)
                                        .font(.caption)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .padding(.horizontal)
                            }
                        }
                    }
                }
            }
            .frame(maxHeight: .infinity)
            
            // Instructions
            GroupBox("How to view widget logs:") {
                VStack(alignment: .leading, spacing: 5) {
                    Text("1. Widget logs are written to a file in the App Group container")
                    Text("2. Use 'Auto Refresh' to see logs in real-time")
                    Text("3. To filter Console.app logs: log show --predicate 'subsystem == \"com.promise-keeper.widget\"' --last 1h")
                    Text("4. Widget must be added to home screen to start logging")
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .frame(width: 900, height: 700)
        .onAppear {
            loadLogs()
        }
        .onReceive(timer) { _ in
            if autoRefresh {
                loadLogs()
            }
        }
        .sheet(isPresented: $showingOldDebugView) {
            OldWidgetDebugView()
        }
    }
    
    private func loadLogs() {
        // Load file logs
        if let logFileURL = getLogFileURL() {
            do {
                logContent = try String(contentsOf: logFileURL, encoding: .utf8)
                if logContent.isEmpty {
                    logContent = "No logs yet. Make sure the widget is added to your home screen and is running."
                }
            } catch {
                logContent = "Error loading logs: \(error.localizedDescription)\n\nMake sure to add WidgetLogger.swift to your widget target."
            }
        } else {
            logContent = "No log file found at expected location."
        }
        
        // Load UserDefaults logs
        if let defaults = UserDefaults(suiteName: appGroupID) {
            userDefaultsLogs = defaults.array(forKey: "widget_debug_logs") as? [[String: Any]] ?? []
            lastLogTime = defaults.object(forKey: "widget_last_log_time") as? Date
        }
    }
    
    private func clearLogs() {
        // Clear file
        if let logFileURL = getLogFileURL() {
            try? FileManager.default.removeItem(at: logFileURL)
        }
        
        // Clear UserDefaults
        if let defaults = UserDefaults(suiteName: appGroupID) {
            defaults.removeObject(forKey: "widget_debug_logs")
            defaults.removeObject(forKey: "widget_last_log_time")
        }
        
        logContent = "Logs cleared."
        userDefaultsLogs = []
        lastLogTime = nil
    }
    
    private func getLogFileURL() -> URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent("widget_debug.log")
    }
    
    private func getLogFilePath() -> String? {
        getLogFileURL()?.path
    }
    
    private func colorForLogType(_ type: String) -> Color {
        switch type {
        case "ERROR", "FAULT": return .red
        case "INFO": return .blue
        case "DEBUG": return .purple
        default: return .primary
        }
    }
    
    private func isWidgetRunning() -> Bool {
        // Check if widget process is running
        let task = Process()
        task.launchPath = "/bin/sh"
        task.arguments = ["-c", "ps aux | grep -i PromiseWidgetExtension | grep -v grep"]
        
        let pipe = Pipe()
        task.standardOutput = pipe
        
        do {
            try task.run()
            task.waitUntilExit()
            
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8), !output.isEmpty {
                return true
            }
        } catch {
            print("Error checking widget process: \(error)")
        }
        
        return false
    }
}

// Keep the old debug view for reference
struct OldWidgetDebugView: View {
    @StateObject private var supabaseManager = SupabaseManager.shared
    @State private var debugOutput: String = ""
    @State private var isRunningDiagnostics = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Widget Authentication Debug (Old)")
                .font(.title)
                .fontWeight(.bold)
            
            // Current State
            GroupBox("Current State") {
                VStack(alignment: .leading, spacing: 10) {
                    Label("Main App Authenticated", systemImage: supabaseManager.isAuthenticated ? "checkmark.circle.fill" : "xmark.circle.fill")
                        .foregroundColor(supabaseManager.isAuthenticated ? .green : .red)
                    
                    if let user = supabaseManager.currentUser {
                        Text("User ID: \(user.id.uuidString)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("App Group ID:")
                        Text(SharedDataManager.appGroupIdentifier)
                            .font(.caption)
                            .textSelection(.enabled)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 5)
            }
            
            // Actions
            GroupBox("Debug Actions") {
                VStack(spacing: 10) {
                    Button("Run Comprehensive Diagnostics") {
                        runDiagnostics()
                    }
                    .disabled(isRunningDiagnostics)
                    
                    Button("Force Store Current Auth State") {
                        forceStoreAuthState()
                    }
                    
                    Button("Clear All Widget Data") {
                        clearWidgetData()
                    }
                    
                    Button("Reload Widget Timelines") {
                        reloadWidgets()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 5)
            }
            
            // Debug Output
            GroupBox("Debug Output") {
                ScrollView {
                    Text(debugOutput.isEmpty ? "No debug output yet. Run diagnostics to see results." : debugOutput)
                        .font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(height: 200)
            }
            
            Spacer()
        }
        .padding()
        .frame(width: 600, height: 650)
    }
    
    private func runDiagnostics() {
        isRunningDiagnostics = true
        debugOutput = "Running diagnostics...\n\n"
        
        // Capture console output
        let pipe = Pipe()
        let originalStdout = dup(STDOUT_FILENO)
        dup2(pipe.fileHandleForWriting.fileDescriptor, STDOUT_FILENO)
        
        // Run diagnostics
        WidgetDebugManager.shared.runComprehensiveDiagnostics()
        
        // Restore stdout
        fflush(stdout)
        dup2(originalStdout, STDOUT_FILENO)
        close(originalStdout)
        
        // Read captured output
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        if let output = String(data: data, encoding: .utf8) {
            debugOutput += output
        }
        
        // Also add current state info
        debugOutput += "\n\n--- Additional Info ---\n"
        debugOutput += "Bundle ID: \(Bundle.main.bundleIdentifier ?? "Unknown")\n"
        debugOutput += "Main App Auth: \(supabaseManager.isAuthenticated)\n"
        
        if let defaults = UserDefaults(suiteName: SharedDataManager.appGroupIdentifier) {
            debugOutput += "\nWidget Storage Values:\n"
            debugOutput += "- widget_is_authenticated: \(defaults.bool(forKey: "widget_is_authenticated"))\n"
            debugOutput += "- widget_user_id: \(defaults.string(forKey: "widget_user_id") ?? "nil")\n"
            debugOutput += "- widget_last_sync_time: \(defaults.object(forKey: "widget_last_sync_time") ?? "nil")\n"
        }
        
        isRunningDiagnostics = false
    }
    
    private func forceStoreAuthState() {
        debugOutput = "Forcing auth state storage...\n"
        
        if let user = supabaseManager.currentUser {
            SharedDataManager.shared.storeUserInfo(
                userId: user.id.uuidString,
                isAuthenticated: true
            )
            debugOutput += "✅ Stored authenticated state for user: \(user.id.uuidString)\n"
        } else {
            SharedDataManager.shared.storeUserInfo(
                userId: nil,
                isAuthenticated: false
            )
            debugOutput += "✅ Stored unauthenticated state\n"
        }
        
        // Verify storage
        let (userId, isAuth) = SharedDataManager.shared.loadUserInfo()
        debugOutput += "\nVerification:\n"
        debugOutput += "- Stored userId: \(userId ?? "nil")\n"
        debugOutput += "- Stored isAuthenticated: \(isAuth)\n"
        
        // Reload widgets
        WidgetCenter.shared.reloadAllTimelines()
        debugOutput += "\n✅ Widget timelines reloaded\n"
    }
    
    private func clearWidgetData() {
        SharedDataManager.shared.clearAllWidgetData()
        debugOutput = "✅ All widget data cleared\n"
        debugOutput += "Widgets should now show as unauthenticated\n"
    }
    
    private func reloadWidgets() {
        WidgetCenter.shared.reloadAllTimelines()
        debugOutput = "✅ Widget timelines reloaded\n"
        debugOutput += "Check widget in 5-10 seconds for updates\n"
    }
}