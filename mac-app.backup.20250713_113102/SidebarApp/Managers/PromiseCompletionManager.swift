import Foundation
import Combine
import AppKit
import UserNotifications
import WidgetKit

// MARK: - Promise Completion Manager
@MainActor
class PromiseCompletionManager: ObservableObject {
    @Published var isProcessing = false
    @Published var lastProcessedTime: Date?
    @Published var processingStatus: String?
    @Published var recentlyResolvedPromises: [String] = []
    
    private let screenshotManager = ScreenshotManager.shared
    private let bamlClient = BAMLAPIClient.shared
    private let promiseManager = PromiseManager.shared
    private let notificationManager = NotificationManager.shared
    private var mcpClient: MCPClient?
    
    // Singleton instance
    static let shared = PromiseCompletionManager()
    
    private init() {
        print("🎯 PromiseCompletionManager initialized")
        
        // Initialize MCP client lazily
        Task {
            mcpClient = MCPClient.shared
            await mcpClient?.initialize()
        }
    }
    
    // MARK: - Main Promise Completion Handler
    func handlePromiseCompletion() async {
        print("\n🎯 PROMISE COMPLETION: Starting analysis...")
        
        guard !isProcessing else {
            print("⚠️ Already processing, skipping...")
            return
        }
        
        isProcessing = true
        processingStatus = "Taking screenshot for promise completion analysis..."
        lastProcessedTime = Date()
        
        do {
            // Take screenshot
            guard let screenshotResult = await screenshotManager.captureScreenshot() else {
                processingStatus = "Failed to capture screenshot"
                print("❌ Failed to capture screenshot")
                isProcessing = false
                return
            }
            
            print("✅ Screenshot captured: \(screenshotResult.id)")
            
            // Analyze screenshot for promise completion
            await analyzeScreenshotForPromiseCompletion(screenshotResult)
            
        } catch {
            processingStatus = "Error during promise completion: \(error.localizedDescription)"
            print("❌ Error during promise completion: \(error)")
        }
        
        isProcessing = false
        
        // Clear status after delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            self.processingStatus = nil
        }
    }
    
    // MARK: - Screenshot Analysis for Promise Completion
    private func analyzeScreenshotForPromiseCompletion(_ screenshot: ScreenshotResult) async {
        processingStatus = "Analyzing screenshot for promise completion evidence..."
        
        do {
            // Convert screenshot to base64 PNG data format expected by BAML API
            let base64ImageData = "data:image/png;base64,\(screenshot.base64Data)"
            
            // Get current promises to check for completion
            let currentPromises = promiseManager.promises
            
            if currentPromises.isEmpty {
                processingStatus = "No active promises to check for completion"
                print("ℹ️ No active promises to check for completion")
                return
            }
            
            // Extract promise resolution information using BAML API
            let response = try await bamlClient.extractPromisesFromBase64(
                imageData: base64ImageData,
                screenshotId: screenshot.id,
                screenshotTimestamp: ISO8601DateFormatter().string(from: screenshot.timestamp)
            )
            
            print("📊 BAML Analysis Results:")
            print("   - New promises found: \(response.promises.count)")
            print("   - Resolved promises: \(response.resolved_promises?.count ?? 0)")
            
            // Process resolved promises
            if let resolvedPromises = response.resolved_promises, !resolvedPromises.isEmpty {
                processingStatus = "Found \(resolvedPromises.count) resolved promise(s). Updating..."
                
                await processResolvedPromises(resolvedPromises, screenshot: screenshot)
                
                // Show notification
                await showPromiseResolvedNotification(count: resolvedPromises.count)
                
                print("✅ Processed \(resolvedPromises.count) resolved promise(s)")
                
            } else {
                processingStatus = "No promise completion evidence found in screenshot"
                print("ℹ️ No promise completion evidence found in screenshot")
            }
            
        } catch {
            processingStatus = "Error analyzing screenshot: \(error.localizedDescription)"
            print("❌ Error analyzing screenshot: \(error)")
        }
    }
    
    // MARK: - Process Resolved Promises
    private func processResolvedPromises(_ resolvedPromises: [ResolvedPromise], screenshot: ScreenshotResult) async {
        var completedPromiseIds: [String] = []
        
        for resolvedPromise in resolvedPromises {
            // Find matching promise in current promises
            let matchingPromise = findMatchingPromise(for: resolvedPromise)
            
            if let promise = matchingPromise {
                print("🎯 Resolving promise: \(promise.content)")
                
                // Mark promise as resolved
                await promiseManager.togglePromiseResolution(String(promise.id ?? 0))
                
                if promiseManager.errorMessage == nil {
                    completedPromiseIds.append(String(promise.id ?? 0))
                    print("✅ Promise resolved: \(promise.content)")
                } else {
                    print("❌ Failed to resolve promise: \(promiseManager.errorMessage ?? "unknown error")")
                }
            } else {
                print("⚠️ No matching promise found for: \(resolvedPromise.content)")
            }
        }
        
        recentlyResolvedPromises = completedPromiseIds
        
        // Force widget update
        WidgetCenter.shared.reloadAllTimelines()
    }
    
    // MARK: - Find Matching Promise
    private func findMatchingPromise(for resolvedPromise: ResolvedPromise) -> Promise? {
        let currentPromises = promiseManager.promises
        
        // First try exact content match
        if let exactMatch = currentPromises.first(where: { $0.content == resolvedPromise.content }) {
            return exactMatch
        }
        
        // Then try partial content match (75% similarity)
        let threshold = 0.75
        for promise in currentPromises {
            let similarity = calculateSimilarity(resolvedPromise.content, promise.content)
            if similarity >= threshold {
                print("📍 Found similar promise (similarity: \(similarity)): \(promise.content)")
                return promise
            }
        }
        
        // Finally try keyword matching
        let resolvedKeywords = extractKeywords(from: resolvedPromise.content)
        for promise in currentPromises {
            let promiseKeywords = extractKeywords(from: promise.content)
            let commonKeywords = Set(resolvedKeywords).intersection(Set(promiseKeywords))
            
            if commonKeywords.count >= 2 || (commonKeywords.count == 1 && resolvedKeywords.count == 1) {
                print("📍 Found promise with matching keywords: \(promise.content)")
                return promise
            }
        }
        
        return nil
    }
    
    // MARK: - Text Similarity Calculation
    private func calculateSimilarity(_ text1: String, _ text2: String) -> Double {
        let words1 = Set(text1.lowercased().components(separatedBy: .whitespacesAndNewlines))
        let words2 = Set(text2.lowercased().components(separatedBy: .whitespacesAndNewlines))
        
        let intersection = words1.intersection(words2)
        let union = words1.union(words2)
        
        return union.isEmpty ? 0.0 : Double(intersection.count) / Double(union.count)
    }
    
    // MARK: - Extract Keywords
    private func extractKeywords(from text: String) -> [String] {
        let stopWords = Set(["the", "a", "an", "and", "or", "but", "in", "on", "at", "to", "for", "of", "with", "by", "from", "is", "are", "was", "were", "be", "been", "being", "have", "has", "had", "do", "does", "did", "will", "would", "should", "could", "can", "may", "might", "must", "shall", "i", "you", "he", "she", "it", "we", "they", "me", "him", "her", "us", "them", "my", "your", "his", "her", "its", "our", "their"])
        
        return text.lowercased()
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !stopWords.contains($0) && $0.count > 2 }
    }
    
    // MARK: - Notifications
    private func showPromiseResolvedNotification(count: Int) async {
        let title = "Promise Keeper"
        let body = "✅ \(count) promise\(count > 1 ? "s" : "") completed!"
        
        notificationManager.sendNotification(
            title: title,
            body: body
        )
    }
    
    // MARK: - Manual Promise Completion
    func manualPromiseCompletion(for promiseId: String) async {
        print("🎯 Manual promise completion for ID: \(promiseId)")
        
        // Take screenshot for evidence
        if let screenshotResult = await screenshotManager.captureScreenshot() {
            print("📸 Screenshot taken for manual completion: \(screenshotResult.id)")
            
            // Mark promise as resolved
            await promiseManager.togglePromiseResolution(promiseId)
            
            if promiseManager.errorMessage == nil {
                print("✅ Promise manually completed")
                
                // Show notification
                await showPromiseResolvedNotification(count: 1)
                
                // Force widget update
                WidgetCenter.shared.reloadAllTimelines()
            } else {
                print("❌ Failed to complete promise: \(promiseManager.errorMessage ?? "unknown error")")
            }
        }
    }
}