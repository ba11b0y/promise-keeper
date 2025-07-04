import Foundation
import Combine

// MARK: - BAML API Client
@MainActor
class BAMLAPIClient: ObservableObject {
    private let baseURL: String
    private let session = URLSession.shared
    
    // Singleton instance
    static let shared = BAMLAPIClient()
    
    private init() {
        // Use the same API base URL as the Electron app
        self.baseURL = ProcessInfo.processInfo.environment["API_BASE_URL_OVERRIDE"] ?? 
                      "https://promise-keeper-api-red-sunset-2072.fly.dev"
    }
    
    // MARK: - Promise Extraction
    func extractPromisesFromBase64(
        imageData: String,
        screenshotId: String? = nil,
        screenshotTimestamp: String? = nil
    ) async throws -> PromiseListResponse {
        let url = URL(string: "\(baseURL)/extract_promises_file_auth")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        // Add authorization header if user is authenticated
        if let token = await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        let requestBody = ImageBase64Request(image_data: imageData)
        let requestData = try JSONEncoder().encode(requestBody)
        request.httpBody = requestData
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BAMLError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw BAMLError.httpError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(PromiseListResponse.self, from: data)
            return result
        } catch {
            print("❌ BAML API decode error: \(error)")
            throw BAMLError.decodingError(error)
        }
    }
    
    func extractPromisesFromImageData(
        _ imageData: Data,
        screenshotId: String? = nil,
        screenshotTimestamp: String? = nil
    ) async throws -> PromiseListResponse {
        let url = URL(string: "\(baseURL)/extract_promises_file_auth")!
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Add authorization header if user is authenticated
        if let token = await getAuthToken() {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        // Create multipart form data
        let boundary = UUID().uuidString
        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        
        var body = Data()
        
        // Add file data
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"file\"; filename=\"screenshot.png\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/png\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n".data(using: .utf8)!)
        
        // Add screenshot_id if provided
        if let screenshotId = screenshotId {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"screenshot_id\"\r\n\r\n".data(using: .utf8)!)
            body.append(screenshotId.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        // Add screenshot_timestamp if provided
        if let screenshotTimestamp = screenshotTimestamp {
            body.append("--\(boundary)\r\n".data(using: .utf8)!)
            body.append("Content-Disposition: form-data; name=\"screenshot_timestamp\"\r\n\r\n".data(using: .utf8)!)
            body.append(screenshotTimestamp.data(using: .utf8)!)
            body.append("\r\n".data(using: .utf8)!)
        }
        
        body.append("--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.httpBody = body
        
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BAMLError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            throw BAMLError.httpError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(PromiseListResponse.self, from: data)
            return result
        } catch {
            print("❌ BAML API decode error: \(error)")
            throw BAMLError.decodingError(error)
        }
    }
    
    // MARK: - Authentication Helper
    private func getAuthToken() async -> String? {
        // Get token from Supabase session
        do {
            let session = try await SupabaseManager.shared.client.auth.session
            return session.accessToken
        } catch {
            print("❌ Failed to get auth token: \(error)")
            return nil
        }
    }
}

// MARK: - Request/Response Models
struct ImageBase64Request: Codable {
    let image_data: String
}

struct PromiseListResponse: Codable {
    let promises: [DetectedPromise]
    let resolved_promises: [ResolvedPromise]?
    let resolved_count: Int?
    
    init(promises: [DetectedPromise], resolved_promises: [ResolvedPromise]? = nil, resolved_count: Int? = nil) {
        self.promises = promises
        self.resolved_promises = resolved_promises
        self.resolved_count = resolved_count
    }
}

struct DetectedPromise: Codable, Identifiable {
    let content: String
    let to_whom: String?
    let deadline: String?
    let action: PromiseAction?
    
    // For Identifiable protocol
    var id: String { content }
}

struct ResolvedPromise: Codable {
    let content: String
    let to_whom: String?
    let deadline: String?
    let resolution_reasoning: String
    let resolution_evidence: String?
}

struct PromiseAction: Codable {
    let actionType: ActionType
    let start_time: String?
    let end_time: String?
    let whom_to: String?
    let app_name: String?
}

enum ActionType: String, Codable {
    case systemLaunchApp = "System_Launch_App"
    case calendarAdd = "Calendar_Add"
    case noAction = "NoAction"
}

// MARK: - BAML Errors
enum BAMLError: LocalizedError {
    case invalidResponse
    case httpError(Int)
    case decodingError(Error)
    case authenticationRequired
    
    var errorDescription: String? {
        switch self {
        case .invalidResponse:
            return "Invalid response from BAML API"
        case .httpError(let code):
            return "HTTP error: \(code)"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .authenticationRequired:
            return "Authentication required for BAML API"
        }
    }
}