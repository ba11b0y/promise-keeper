import Foundation
import os.log

/// A logger specifically for the PromiseWidget that writes to both os_log and a debug file
class WidgetLogger {
    static let shared = WidgetLogger()
    
    private let logger = Logger(subsystem: "com.promise-keeper.widget", category: "general")
    private let appGroupID = "group.TX645N2QBW.com.example.mac.SidebarApp"
    private let logFileName = "widget_debug.log"
    private let dateFormatter: ISO8601DateFormatter
    
    private var logFileURL: URL? {
        FileManager.default
            .containerURL(forSecurityApplicationGroupIdentifier: appGroupID)?
            .appendingPathComponent(logFileName)
    }
    
    private init() {
        dateFormatter = ISO8601DateFormatter()
        
        // Create initial log entry
        log("WidgetLogger initialized")
    }
    
    /// Log a message to both os_log and debug file
    func log(_ message: String, type: OSLogType = .default, function: String = #function, line: Int = #line) {
        // 1. Log to os_log (visible with proper filtering)
        let fullMessage = "[\(function):\(line)] \(message)"
        
        switch type {
        case .debug:
            logger.debug("\(fullMessage)")
        case .info:
            logger.info("\(fullMessage)")
        case .error:
            logger.error("\(fullMessage)")
        case .fault:
            logger.fault("\(fullMessage)")
        default:
            logger.log("\(fullMessage)")
        }
        
        // 2. Write to debug file
        writeToFile(message: fullMessage, type: type)
        
        // 3. Also store in UserDefaults for easy access
        storeInUserDefaults(message: fullMessage, type: type)
    }
    
    /// Log debug level message
    func debug(_ message: String, function: String = #function, line: Int = #line) {
        log(message, type: .debug, function: function, line: line)
    }
    
    /// Log info level message
    func info(_ message: String, function: String = #function, line: Int = #line) {
        log(message, type: .info, function: function, line: line)
    }
    
    /// Log error level message
    func error(_ message: String, function: String = #function, line: Int = #line) {
        log(message, type: .error, function: function, line: line)
    }
    
    /// Log critical fault
    func fault(_ message: String, function: String = #function, line: Int = #line) {
        log(message, type: .fault, function: function, line: line)
    }
    
    private func writeToFile(message: String, type: OSLogType) {
        guard let logFileURL = logFileURL else { return }
        
        let timestamp = dateFormatter.string(from: Date())
        let typeString = logTypeString(type)
        let logEntry = "[\(timestamp)] [\(typeString)] \(message)\n"
        
        guard let data = logEntry.data(using: .utf8) else { return }
        
        do {
            if FileManager.default.fileExists(atPath: logFileURL.path) {
                // Append to existing file
                let handle = try FileHandle(forWritingTo: logFileURL)
                handle.seekToEndOfFile()
                handle.write(data)
                handle.closeFile()
            } else {
                // Create new file
                try data.write(to: logFileURL)
            }
        } catch {
            // Can't log this error or we'll create infinite loop
        }
    }
    
    private func storeInUserDefaults(message: String, type: OSLogType) {
        guard let defaults = UserDefaults(suiteName: appGroupID) else { return }
        
        // Keep last 50 log entries in UserDefaults
        var logs = defaults.array(forKey: "widget_debug_logs") as? [[String: Any]] ?? []
        
        let entry: [String: Any] = [
            "timestamp": Date(),
            "message": message,
            "type": logTypeString(type)
        ]
        
        logs.append(entry)
        
        // Keep only last 50 entries
        if logs.count > 50 {
            logs = Array(logs.suffix(50))
        }
        
        defaults.set(logs, forKey: "widget_debug_logs")
        defaults.set(Date(), forKey: "widget_last_log_time")
    }
    
    private func logTypeString(_ type: OSLogType) -> String {
        switch type {
        case .debug: return "DEBUG"
        case .info: return "INFO"
        case .error: return "ERROR"
        case .fault: return "FAULT"
        default: return "LOG"
        }
    }
    
    /// Clear all debug logs
    func clearLogs() {
        // Clear file
        if let logFileURL = logFileURL {
            try? FileManager.default.removeItem(at: logFileURL)
        }
        
        // Clear UserDefaults
        if let defaults = UserDefaults(suiteName: appGroupID) {
            defaults.removeObject(forKey: "widget_debug_logs")
            defaults.removeObject(forKey: "widget_last_log_time")
        }
    }
    
    /// Get the path to the log file for debugging
    var logFilePath: String? {
        logFileURL?.path
    }
}

// MARK: - Convenience Global Functions
func widgetLog(_ message: String, type: OSLogType = .default, function: String = #function, line: Int = #line) {
    WidgetLogger.shared.log(message, type: type, function: function, line: line)
}

func widgetDebug(_ message: String, function: String = #function, line: Int = #line) {
    WidgetLogger.shared.debug(message, function: function, line: line)
}

func widgetInfo(_ message: String, function: String = #function, line: Int = #line) {
    WidgetLogger.shared.info(message, function: function, line: line)
}

func widgetError(_ message: String, function: String = #function, line: Int = #line) {
    WidgetLogger.shared.error(message, function: function, line: line)
}