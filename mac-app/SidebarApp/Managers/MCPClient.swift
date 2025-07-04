import Foundation
import Combine

// MARK: - MCP Client (Model Context Protocol)
@MainActor
class MCPClient: ObservableObject {
    @Published var isConnected = false
    @Published var errorMessage: String?
    
    private var mcpProcess: Process?
    private let mcpServerPath: String
    
    // Singleton instance
    static let shared = MCPClient()
    
    private init() {
        // Path to the AppleScript MCP server in the project
        self.mcpServerPath = Bundle.main.path(forResource: "applescript-mcp", ofType: nil) ?? 
                           "/Users/anaygupta/Downloads/promise-keeper/applescript-mcp"
    }
    
    deinit {
        Task { @MainActor in
            disconnect()
        }
    }
    
    // MARK: - Connection Management
    func initialize() async {
        await connect()
    }
    
    func cleanup() async {
        disconnect()
    }
    
    private func connect() async {
        guard !isConnected else { return }
        
        do {
            try await startMCPServer()
            isConnected = true
            print("✅ MCP Client connected successfully")
        } catch {
            errorMessage = "Failed to connect to MCP server: \(error.localizedDescription)"
            print("❌ MCP connection failed: \(error)")
        }
    }
    
    private func disconnect() {
        if let process = mcpProcess, process.isRunning {
            process.terminate()
            process.waitUntilExit()
        }
        mcpProcess = nil
        isConnected = false
        print("🔌 MCP Client disconnected")
    }
    
    private func startMCPServer() async throws {
        let process = Process()
        
        // Set up the process to run the AppleScript MCP server
        process.executableURL = URL(fileURLWithPath: "/usr/bin/node")
        process.arguments = ["\(mcpServerPath)/dist/index.js"]
        process.currentDirectoryURL = URL(fileURLWithPath: mcpServerPath)
        
        // Set up pipes for communication
        let inputPipe = Pipe()
        let outputPipe = Pipe()
        let errorPipe = Pipe()
        
        process.standardInput = inputPipe
        process.standardOutput = outputPipe
        process.standardError = errorPipe
        
        // Start the process
        try process.run()
        self.mcpProcess = process
        
        print("🚀 Started MCP server process: \(process.processIdentifier)")
    }
    
    // MARK: - Messages Operations
    func listChats(includeParticipantDetails: Bool = false) async throws -> [ChatInfo] {
        return try await executeMCPCommand(
            category: "messages",
            command: "list_chats",
            parameters: ["includeParticipantDetails": includeParticipantDetails]
        )
    }
    
    func getMessages(limit: Int = 100) async throws -> [MessageInfo] {
        return try await executeMCPCommand(
            category: "messages", 
            command: "get_messages",
            parameters: ["limit": limit]
        )
    }
    
    func searchMessages(searchText: String, sender: String? = nil, chatId: String? = nil, limit: Int = 50, daysBack: Int = 30) async throws -> [MessageInfo] {
        var parameters: [String: Any] = [
            "searchText": searchText,
            "limit": limit,
            "daysBack": daysBack
        ]
        
        if let sender = sender {
            parameters["sender"] = sender
        }
        
        if let chatId = chatId {
            parameters["chatId"] = chatId
        }
        
        return try await executeMCPCommand(
            category: "messages",
            command: "search_messages", 
            parameters: parameters
        )
    }
    
    func sendMessage(recipient: String, body: String? = nil, auto: Bool = false) async throws -> String {
        var parameters: [String: Any] = [
            "recipient": recipient,
            "auto": auto
        ]
        
        if let body = body {
            parameters["body"] = body
        }
        
        return try await executeMCPCommand(
            category: "messages",
            command: "compose_message",
            parameters: parameters
        )
    }
    
    // MARK: - System Operations
    func launchApp(appName: String) async throws -> String {
        return try await executeMCPCommand(
            category: "system",
            command: "launch_app",
            parameters: ["name": appName]
        )
    }
    
    func quitApp(appName: String, force: Bool = false) async throws -> String {
        return try await executeMCPCommand(
            category: "system",
            command: "quit_app",
            parameters: ["name": appName, "force": force]
        )
    }
    
    func getFrontmostApp() async throws -> String {
        return try await executeMCPCommand(
            category: "system",
            command: "get_frontmost_app",
            parameters: [:]
        )
    }
    
    func setVolume(level: Int) async throws -> String {
        return try await executeMCPCommand(
            category: "system",
            command: "volume",
            parameters: ["level": level]
        )
    }
    
    func toggleDarkMode() async throws -> String {
        return try await executeMCPCommand(
            category: "system",
            command: "toggle_dark_mode",
            parameters: [:]
        )
    }
    
    func getBatteryStatus() async throws -> String {
        return try await executeMCPCommand(
            category: "system",
            command: "get_battery_status",
            parameters: [:]
        )
    }
    
    // MARK: - Calendar Operations
    func addCalendarEvent(title: String, startDate: String, endDate: String, calendar: String? = nil) async throws -> String {
        var parameters: [String: Any] = [
            "title": title,
            "startDate": startDate,
            "endDate": endDate
        ]
        
        if let calendar = calendar {
            parameters["calendar"] = calendar
        }
        
        return try await executeMCPCommand(
            category: "calendar",
            command: "add",
            parameters: parameters
        )
    }
    
    func listTodaysEvents() async throws -> String {
        return try await executeMCPCommand(
            category: "calendar",
            command: "list",
            parameters: [:]
        )
    }
    
    // MARK: - Private MCP Communication
    private func executeMCPCommand<T: Codable>(
        category: String,
        command: String,
        parameters: [String: Any]
    ) async throws -> T {
        guard isConnected, let process = mcpProcess, process.isRunning else {
            throw MCPError.notConnected
        }
        
        // Create MCP request
        let request = MCPRequest(
            jsonrpc: "2.0",
            id: UUID().uuidString,
            method: "tools/call",
            params: MCPToolCall(
                name: "\(category)_\(command)",
                arguments: parameters
            )
        )
        
        // Send request to MCP server via stdio
        let requestData = try JSONEncoder().encode(request)
        let requestString = String(data: requestData, encoding: .utf8)! + "\n"
        
        guard let inputPipe = process.standardInput as? Pipe else {
            throw MCPError.communicationFailed
        }
        
        inputPipe.fileHandleForWriting.write(requestString.data(using: .utf8)!)
        
        // Read response from MCP server
        guard let outputPipe = process.standardOutput as? Pipe else {
            throw MCPError.communicationFailed
        }
        
        let responseData = outputPipe.fileHandleForReading.availableData
        guard !responseData.isEmpty else {
            throw MCPError.noResponse
        }
        
        // Parse MCP response
        let response = try JSONDecoder().decode(MCPResponse<T>.self, from: responseData)
        
        if let error = response.error {
            throw MCPError.serverError(error.message)
        }
        
        guard let result = response.result else {
            throw MCPError.noResult
        }
        
        return result
    }
}

// MARK: - MCP Data Models
struct MCPRequest: Codable {
    let jsonrpc: String
    let id: String
    let method: String
    let params: MCPToolCall
}

struct MCPToolCall: Codable {
    let name: String
    let arguments: [String: Any]
    
    enum CodingKeys: String, CodingKey {
        case name, arguments
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        
        // Convert arguments dictionary to JSON data then back to Any for encoding
        let jsonData = try JSONSerialization.data(withJSONObject: arguments)
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData)
        try container.encode(jsonObject as! [String: String], forKey: .arguments)
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        
        // Decode arguments as JSON-compatible dictionary
        let argumentsData = try container.decode([String: String].self, forKey: .arguments)
        arguments = argumentsData
    }
    
    init(name: String, arguments: [String: Any]) {
        self.name = name
        self.arguments = arguments
    }
}

struct MCPResponse<T: Codable>: Codable {
    let jsonrpc: String
    let id: String
    let result: T?
    let error: MCPError?
    
    struct MCPError: Codable {
        let code: Int
        let message: String
    }
}

// MARK: - Domain Models
struct ChatInfo: Codable {
    let id: String
    let name: String
    let isGroupChat: Bool
}

struct MessageInfo: Codable {
    let messageDate: String
    let sender: String
    let messageText: String
    let chatName: String?
    let chatId: String?
    
    enum CodingKeys: String, CodingKey {
        case messageDate = "message_date"
        case sender
        case messageText = "message_text"
        case chatName = "chat_name"
        case chatId = "chat_id"
    }
}

// MARK: - MCP Errors
enum MCPError: LocalizedError {
    case notConnected
    case communicationFailed
    case noResponse
    case noResult
    case serverError(String)
    
    var errorDescription: String? {
        switch self {
        case .notConnected:
            return "MCP server not connected"
        case .communicationFailed:
            return "Failed to communicate with MCP server"
        case .noResponse:
            return "No response from MCP server"
        case .noResult:
            return "MCP server returned no result"
        case .serverError(let message):
            return "MCP server error: \(message)"
        }
    }
}