import Foundation
import Combine
import Supabase

// MARK: - Promise Manager
@MainActor
class PromiseManager: ObservableObject {
    @Published var promises: [Promise] = []
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let supabaseManager = SupabaseManager.shared
    private let tableName = "promises"
    
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
            print("✅ Fetched \(fetchedPromises.count) promises")
            
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
                .eq("id", value: id as! PostgrestFilterValue)
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
    
    // MARK: - Delete Promise
    func deletePromise(id: Int64) async {
        guard supabaseManager.currentUser?.id != nil else {
            errorMessage = "User not authenticated"
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            print("🗑️ Deleting promise: \(id)")
            
            try await supabaseManager.client
                .from(tableName)
                .delete()
                .eq("id", value: id as! PostgrestFilterValue)
                .execute()
            
            // Remove from local array
            promises.removeAll { $0.id == id }
            print("✅ Promise deleted successfully")
            
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
} 