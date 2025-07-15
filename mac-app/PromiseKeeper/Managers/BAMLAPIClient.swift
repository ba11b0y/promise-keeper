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
                      "https://promise-keeper-api-summer-water-1765.fly.dev"
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
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            print("❌ Network error: \(error)")
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cannotFindHost:
                    throw BAMLError.networkError("Cannot find server. Please check your internet connection or try again later.")
                case .notConnectedToInternet:
                    throw BAMLError.networkError("No internet connection. Please check your network settings.")
                case .timedOut:
                    throw BAMLError.networkError("Request timed out. The server might be temporarily unavailable.")
                default:
                    throw BAMLError.networkError("Network error: \(urlError.localizedDescription)")
                }
            }
            throw error
        }
        
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
            NSLog("❌ BAML API decode error: %@", error.localizedDescription)
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
        let token = await getAuthToken()
        print("🔑 Auth token available: \(token != nil ? "YES" : "NO")")
        if let token = token {
            print("🔑 Token prefix: \(String(token.prefix(20)))...")
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        } else {
            print("❌ No auth token available - this will likely fail")
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
        
        print("📤 Sending request to: \(url)")
        print("📤 Image data size: \(imageData.count) bytes")
        print("📤 Total body size: \(body.count) bytes")
        print("📤 Screenshot ID: \(screenshotId ?? "nil")")
        print("📤 Screenshot timestamp: \(screenshotTimestamp ?? "nil")")
        
        let data: Data
        let response: URLResponse
        
        do {
            (data, response) = try await session.data(for: request)
        } catch {
            print("❌ Network error: \(error)")
            if let urlError = error as? URLError {
                switch urlError.code {
                case .cannotFindHost:
                    throw BAMLError.networkError("Cannot find server. Please check your internet connection or try again later.")
                case .notConnectedToInternet:
                    throw BAMLError.networkError("No internet connection. Please check your network settings.")
                case .timedOut:
                    throw BAMLError.networkError("Request timed out. The server might be temporarily unavailable.")
                default:
                    throw BAMLError.networkError("Network error: \(urlError.localizedDescription)")
                }
            }
            throw error
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            print("❌ Invalid response type")
            throw BAMLError.invalidResponse
        }
        
        print("📥 Response status: \(httpResponse.statusCode)")
        print("📥 Response headers: \(httpResponse.allHeaderFields)")
        
        if httpResponse.statusCode != 200 {
            // Try to decode error details
            if let errorString = String(data: data, encoding: .utf8) {
                NSLog("❌ Error response body: %@", errorString)
                // Try to parse FastAPI error response
                if let errorData = errorString.data(using: .utf8),
                   let errorJson = try? JSONSerialization.jsonObject(with: errorData) as? [String: Any],
                   let detail = errorJson["detail"] as? String {
                    NSLog("❌ FastAPI error detail: %@", detail)
                }
            }
            throw BAMLError.httpError(httpResponse.statusCode)
        }
        
        do {
            let decoder = JSONDecoder()
            let result = try decoder.decode(PromiseListResponse.self, from: data)
            print("✅ Successfully decoded response with \(result.promises.count) promises")
            return result
        } catch {
            print("❌ BAML API decode error: \(error)")
            if let responseString = String(data: data, encoding: .utf8) {
                print("❌ Response body: \(responseString)")
            }
            throw BAMLError.decodingError(error)
        }
    }
    
    // MARK: - Authentication Helper
    private func getAuthToken() async -> String? {
        // Get token from Supabase session
        do {
            print("🔍 Attempting to get Supabase session...")
            let session = try await SupabaseManager.shared.client.auth.session
            print("✅ Got Supabase session, user ID: \(session.user.id)")
            print("🔑 Access token length: \(session.accessToken.count) characters")
            // Additional debug: check token format
            if session.accessToken.count < 50 {
                print("⚠️ Warning: Access token seems unusually short")
            }
            return session.accessToken
        } catch {
            print("❌ Failed to get auth token: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error description: \(error.localizedDescription)")
            // Additional debug: check if user is logged in
            if let currentUser = SupabaseManager.shared.client.auth.currentUser {
                print("ℹ️ Current user exists but session failed: \(currentUser.id)")
            } else {
                print("ℹ️ No current user found")
            }
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
    let platform: String?
    let person: String?
    let due_date: String?
    let action: PromiseAction?
    let formatted: FormattedPromise?
    
    // For Identifiable protocol
    var id: String { content }
}

struct FormattedPromise: Codable {
    let title: String
    let body: String
    let details: String?
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
    case networkError(String)
    
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
        case .networkError(let message):
            return message
        }
    }
}