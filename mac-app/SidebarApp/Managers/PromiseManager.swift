import Foundation
import Combine
import Supabase
import WidgetKit

// MARK: - Promise Manager
@MainActor
class PromiseManager: ObservableObject {
    static let shared = PromiseManager()
    
    @Published var promises: [Promise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseManager = SupabaseManager.shared
    private let tableName = "promises"
    
    init() {
        print("📱 PromiseManager initialized")
        NSLog("📱 PromiseManager initialized")
        
        // Debug: Verify App Group access on init
        SharedDataManager.shared.debugPrintAllStoredData()
    }
    
    // MARK: - Fetch Promises
    func fetchPromises() async {
        guard let userId = supabaseManager.currentUser?.id else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("📱 Fetching promises for user: \(userId)")
            
            let fetchedPromises: [Promise] = try await supabaseManager.client
                .from(tableName)
                .select()
                .eq("owner_id", value: userId)
                .order("created_at", ascending: false)
                .execute()
                .value
            
            self.promises = fetchedPromises
            print("✅ Fetched \(fetchedPromises.count) promises from Supabase")
            NSLog("✅ Fetched \(fetchedPromises.count) promises from Supabase")
            
            // Log the first few promises to verify data
            if !fetchedPromises.isEmpty {
                print("📋 First few promises:")
                for (i, promise) in fetchedPromises.prefix(3).enumerated() {
                    print("   [\(i)] ID: \(promise.id ?? 0), Content: \(promise.content.prefix(50))...")
                }
            }
            
            // Update shared storage for widget
            updateSharedData()
            
        } catch {
            print("❌ Error fetching promises: \(error)")
            errorMessage = "Failed to load promises: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Create Promise
    func createPromise(content: String) async {
        guard let userId = supabaseManager.currentUser?.id else {
            errorMessage = "User not authenticated"
            return
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Promise content cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("📝 Creating new promise: \(content)")
            
            let newPromise = NewPromise.create(content: content.trimmingCharacters(in: .whitespacesAndNewlines), for: userId)
            
            let createdPromise: Promise = try await supabaseManager.client
                .from(tableName)
                .insert(newPromise)
                .select()
                .single()
                .execute()
                .value
            
            // Add to local array at the beginning (since we order by created_at desc)
            promises.insert(createdPromise, at: 0)
            print("✅ Promise created successfully")
            
            // Update shared storage for widget
            updateSharedData()
            
        } catch {
            print("❌ Error creating promise: \(error)")
            errorMessage = "Failed to create promise: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Update Promise
    func updatePromise(id: Int64, content: String) async {
        guard supabaseManager.currentUser?.id != nil else {
            errorMessage = "User not authenticated"
            return
        }
        
        guard !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            errorMessage = "Promise content cannot be empty"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("✏️ Updating promise: \(id)")
            
            let updateData = [
                "content": content.trimmingCharacters(in: .whitespacesAndNewlines),
                "updated_at": ISO8601DateFormatter().string(from: Date())
            ]
            
            let updatedPromise: Promise = try await supabaseManager.client
                .from(tableName)
                .update(updateData)
                .eq("id", value: Int(id))
                .select()
                .single()
                .execute()
                .value
            
            // Update local array
            if let index = promises.firstIndex(where: { $0.id == id }) {
                promises[index] = updatedPromise
            }
            print("✅ Promise updated successfully")
            
        } catch {
            print("❌ Error updating promise: \(error)")
            errorMessage = "Failed to update promise: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Toggle Promise Resolution (CRITICAL MISSING FUNCTIONALITY)
    func togglePromiseResolution(_ promiseId: String) async {
        // Convert String ID to Int64 by parsing the identifiableId format
        guard let promiseIdInt64 = Int64(promiseId) else {
            errorMessage = "Invalid promise ID format"
            return
        }
        
        guard let promise = promises.first(where: { $0.id == promiseIdInt64 }) else {
            errorMessage = "Promise not found"
            return
        }
        
        guard supabaseManager.currentUser?.id != nil else {
            errorMessage = "User not authenticated"
            return
        }
        
        let newResolvedState = !promise.isResolved
        print("🔄 Toggling promise \(promise.id) resolution to: \(newResolvedState)")
        
        do {
            let now = ISO8601DateFormatter().string(from: Date())
            
            // Create proper encodable update data
            let updateData: PromiseUpdateData
            if newResolvedState {
                updateData = PromiseUpdateData(
                    resolved: newResolvedState,
                    updated_at: now,
                    resolved_screenshot_time: now,
                    resolved_reason: "Promise marked as resolved by user",
                    resolved_screenshot_id: "user_action_\(Date().timeIntervalSince1970)"
                )
            } else {
                updateData = PromiseUpdateData(
                    resolved: newResolvedState,
                    updated_at: now,
                    resolved_screenshot_time: nil,
                    resolved_reason: nil,
                    resolved_screenshot_id: nil
                )
            }
            
            let updatedPromise: Promise = try await supabaseManager.client
                .from(tableName)
                .update(updateData)
                .eq("id", value: Int(promise.id ?? 0))
                .select()
                .single()
                .execute()
                .value
            
            // Update local array
            if let index = promises.firstIndex(where: { $0.id == promise.id }) {
                promises[index] = updatedPromise
            }
            
            // Update shared storage for widget
            updateSharedData()
            
            print("✅ Promise resolution toggled successfully: \(newResolvedState)")
            
        } catch {
            print("❌ Error toggling promise resolution: \(error)")
            errorMessage = "Failed to update promise: \(error.localizedDescription)"
        }
    }
    
    // MARK: - Delete Promise (Updated for String IDs)
    func deletePromise(_ promiseId: String) async {
        // Convert String ID to Int64 by parsing the identifiableId format
        guard let promiseIdInt64 = Int64(promiseId) else {
            errorMessage = "Invalid promise ID format"
            return
        }
        
        guard let promise = promises.first(where: { $0.id == promiseIdInt64 }) else {
            errorMessage = "Promise not found"
            return
        }
        
        guard supabaseManager.currentUser?.id != nil else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🗑️ Deleting promise: \(promise.id)")
            
            try await supabaseManager.client
                .from(tableName)
                .delete()
                .eq("id", value: Int(promise.id ?? 0))
                .execute()
            
            // Remove from local array
            promises.removeAll { $0.id == promiseIdInt64 }
            print("✅ Promise deleted successfully")
            
            // Update shared storage for widget
            updateSharedData()
            
        } catch {
            print("❌ Error deleting promise: \(error)")
            errorMessage = "Failed to delete promise: \(error.localizedDescription)"
        }
        
        isLoading = false
    }
    
    // MARK: - Utility Methods
    func clearError() {
        errorMessage = nil
    }
    
    func refreshPromises() async {
        await fetchPromises()
    }
    
    // MARK: - Shared Data Management for Widget
    func updateSharedData() {
        print("🔄 updateSharedData() called with \(promises.count) promises")
        NSLog("🔄 updateSharedData() called with \(promises.count) promises")
        
        // Pull whatever is already stored so that we never accidentally
        // overwrite a valid auth state with a stale "false" value.
        let current = UnifiedSharedDataManager.shared.load() ?? WidgetData()

        let newUserId = supabaseManager.currentUser?.id.uuidString ?? current.userId
        let newUserEmail = supabaseManager.currentUser?.email ?? current.userEmail

        // Preserve true once it has been written – this prevents the race
        // where the promise-sync happens before the auth listener finishes.
        let newIsAuthenticated = current.isAuthenticated || supabaseManager.isAuthenticated

        UnifiedSharedDataManager.shared.syncPromisesFromApp(
            promises,
            userId: newUserId,
            userEmail: newUserEmail,
            isAuthenticated: newIsAuthenticated
        ) { promise in
            WidgetPromiseData(
                id: String(promise.id ?? 0),
                created_at: promise.created_at,
                updated_at: promise.updated_at,
                content: promise.content,
                owner_id: promise.owner_id.uuidString,
                resolved: promise.resolved ?? false
            )
        }

        // Legacy fallback: also write to SharedDataManager for widgets running old logic
        SharedDataManager.shared.syncPromisesFromApp(
            promises,
            userId: newUserId,
            isAuthenticated: newIsAuthenticated
        ) { promise in
            WidgetPromise(
                id: String(promise.id ?? 0),
                created_at: promise.created_at,
                updated_at: promise.updated_at,
                content: promise.content,
                owner_id: promise.owner_id.uuidString,
                resolved: promise.resolved ?? false
            )
        }

        print("📱 Updated shared data for widget (auth=\(newIsAuthenticated)): \(promises.count) promises (legacy + new)")
    }
}

// MARK: - Promise Update Data (Encodable struct for Supabase updates)
struct PromiseUpdateData: Codable {
    let resolved: Bool
    let updated_at: String
    let resolved_screenshot_time: String?
    let resolved_reason: String?
    let resolved_screenshot_id: String?
}

// Note: WidgetPromise and SharedDataManager are now in SharedDataManager.swift