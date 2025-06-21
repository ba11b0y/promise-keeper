import Foundation

struct EnvironmentConfig {
    // MARK: - Environment Variables
    
    static var supabaseURL: String {
        // Try to get from environment variable first
        if let envURL = ProcessInfo.processInfo.environment["SUPABASE_URL"], !envURL.isEmpty {
            return envURL
        }
        
        // Fall back to .env file
        if let envURL = loadFromEnvFile("SUPABASE_URL"), !envURL.isEmpty {
            return envURL
        }
        
        // Final fallback to config file
        return SupabaseConfig.supabaseURL
    }
    
    static var supabaseAnonKey: String {
        // Try to get from environment variable first
        if let envKey = ProcessInfo.processInfo.environment["SUPABASE_ANON_KEY"], !envKey.isEmpty {
            return envKey
        }
        
        // Fall back to .env file
        if let envKey = loadFromEnvFile("SUPABASE_ANON_KEY"), !envKey.isEmpty {
            return envKey
        }
        
        // Final fallback to config file
        return SupabaseConfig.supabaseAnonKey
    }
    
    // MARK: - .env File Loading
    
    private static var envCache: [String: String] = [:]
    private static var envLoaded = false
    
    private static func loadFromEnvFile(_ key: String) -> String? {
        if !envLoaded {
            loadEnvFile()
            envLoaded = true
        }
        return envCache[key]
    }
    
    private static func loadEnvFile() {
                 // Try multiple possible locations for .env file
         let possiblePaths = [
             // Root of the project (most common)
             "../../../.env",
             "../../../.env.local",
             "../../.env", 
             "../../.env.local",
             "../.env",
             "../.env.local",
             ".env",
             ".env.local",
             // Absolute path from bundle
             Bundle.main.bundlePath + "/../../../.env",
             Bundle.main.bundlePath + "/../../../.env.local",
             Bundle.main.bundlePath + "/../../.env",
             Bundle.main.bundlePath + "/../../.env.local"
         ]
        
        for relativePath in possiblePaths {
            if let envPath = findEnvFile(relativePath: relativePath) {
                print("📁 Found .env file at: \(envPath)")
                parseEnvFile(at: envPath)
                return
            }
        }
        
        print("⚠️ No .env file found. Using default configuration or Xcode environment variables.")
    }
    
    private static func findEnvFile(relativePath: String) -> String? {
        let fileManager = FileManager.default
        
        // Get the bundle path and construct the full path
        guard let bundlePath = Bundle.main.resourcePath else { return nil }
        let fullPath = URL(fileURLWithPath: bundlePath).appendingPathComponent(relativePath).path
        
        if fileManager.fileExists(atPath: fullPath) {
            return fullPath
        }
        
        // Also try relative to the current working directory
        let currentDir = fileManager.currentDirectoryPath
        let currentDirPath = URL(fileURLWithPath: currentDir).appendingPathComponent(relativePath).path
        
        if fileManager.fileExists(atPath: currentDirPath) {
            return currentDirPath
        }
        
        return nil
    }
    
    private static func parseEnvFile(at path: String) {
        do {
            let content = try String(contentsOfFile: path, encoding: .utf8)
            let lines = content.components(separatedBy: .newlines)
            
            for line in lines {
                let trimmedLine = line.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Skip empty lines and comments
                if trimmedLine.isEmpty || trimmedLine.hasPrefix("#") {
                    continue
                }
                
                // Parse KEY=VALUE format
                let parts = trimmedLine.components(separatedBy: "=")
                if parts.count >= 2 {
                    let key = parts[0].trimmingCharacters(in: .whitespacesAndNewlines)
                    let value = parts.dropFirst().joined(separator: "=")
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "\"'")) // Remove quotes
                    
                    envCache[key] = value
                }
            }
            
            print("✅ Loaded \(envCache.count) environment variables from .env file")
        } catch {
            print("❌ Error reading .env file: \(error)")
        }
    }
    
    // MARK: - Debug Info
    
    static func printConfiguration() {
        print("🔧 Environment Configuration:")
        print("   SUPABASE_URL: \(supabaseURL.prefix(30))...")
        print("   SUPABASE_ANON_KEY: \(supabaseAnonKey.prefix(20))...")
        print("   Source: \(getConfigSource())")
    }
    
    private static func getConfigSource() -> String {
        if ProcessInfo.processInfo.environment["SUPABASE_URL"] != nil {
            return "Xcode Environment Variables"
        } else if envCache["SUPABASE_URL"] != nil {
            return ".env file"
        } else {
            return "SupabaseConfig.swift"
        }
    }
} 