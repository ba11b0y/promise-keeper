import SwiftUI

struct PromisesPane: View {
    @StateObject private var promiseManager = PromiseManager.shared
    @StateObject private var autoPromiseManager = AutoPromiseManager.shared
    @State private var newPromiseText = ""
    @State private var editingPromise: Promise?
    @State private var editingText = ""
    @State private var showingNewPromiseField = false
    @State private var selectedCaptureMode: ScreenshotManager.CaptureMode = .onEnter
    
    var body: some View {
        Pane {
            VStack(alignment: .leading, spacing: 0) {
                // Header with add button
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("My Promises")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("\(promiseManager.promises.count) promises")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        showingNewPromiseField.toggle()
                        if showingNewPromiseField {
                            newPromiseText = ""
                        }
                    }) {
                        Image(systemName: showingNewPromiseField ? "xmark.circle" : "plus.circle")
                            .font(.title2)
                    }
                    .buttonStyle(.plain)
                    .foregroundColor(.accentColor)
                }
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 12)
                
                Divider()
                
                // New promise input field
                if showingNewPromiseField {
                    VStack(spacing: 12) {
                        TextField("Enter your promise...", text: $newPromiseText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(3...6)
                        
                        HStack {
                            Button("Cancel") {
                                showingNewPromiseField = false
                                newPromiseText = ""
                            }
                            .buttonStyle(.bordered)
                            
                            Spacer()
                            
                            Button("Add Promise") {
                                Task {
                                    await promiseManager.createPromise(content: newPromiseText)
                                    if promiseManager.errorMessage == nil {
                                        newPromiseText = ""
                                        showingNewPromiseField = false
                                    }
                                }
                            }
                            .buttonStyle(PrimaryButtonStyle())
                            .disabled(newPromiseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 16)
                    
                    Divider()
                }
                
                // Error message
                if let errorMessage = promiseManager.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.triangle")
                            .foregroundColor(.orange)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        Spacer()
                        
                        Button("Dismiss") {
                            promiseManager.clearError()
                        }
                        .font(.caption)
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 8)
                    .background(Color.orange.opacity(0.1))
                    
                    Divider()
                }
                
                // Screenshot Controls (matching Electron app exactly)
                VStack(spacing: 12) {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Screenshot Mode:")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                            
                            Picker("Mode", selection: $selectedCaptureMode) {
                                ForEach(ScreenshotManager.CaptureMode.allCases, id: \.self) { mode in
                                    Text(mode.displayName).tag(mode)
                                }
                            }
                            .pickerStyle(.menu)
                            .onChange(of: selectedCaptureMode) { newMode in
                                autoPromiseManager.setCaptureMode(newMode)
                            }
                        }
                        
                        Spacer()
                        
                        Button("📸 Take Screenshot Now") {
                            Task {
                                await autoPromiseManager.processManualScreenshot()
                            }
                        }
                        .buttonStyle(.bordered)
                        .disabled(autoPromiseManager.isProcessing)
                    }
                    
                    // Processing status (identical to Electron app feedback)
                    if let status = autoPromiseManager.processingStatus {
                        HStack {
                            if autoPromiseManager.isProcessing {
                                ProgressView()
                                    .scaleEffect(0.6)
                            }
                            Text(status)
                                .font(.caption)
                                .foregroundColor(.secondary)
                            Spacer()
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .background(Color(.controlBackgroundColor).opacity(0.3))
                
                Divider()
                
                // Promises list
                if promiseManager.isLoading && promiseManager.promises.isEmpty {
                    VStack(spacing: 12) {
                        ProgressView()
                            .scaleEffect(0.8)
                        Text("Loading promises...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if promiseManager.promises.isEmpty {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 48))
                            .foregroundColor(.secondary.opacity(0.5))
                        
                        Text("No promises yet")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        
                        Text("Create your first promise to get started")
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        
                        Button("Add Your First Promise") {
                            showingNewPromiseField = true
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .padding(.top, 8)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(40)
                } else {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            ForEach(promiseManager.promises, id: \.identifiableId) { promise in
                                PromiseRowView(
                                    promise: promise,
                                    isEditing: editingPromise?.identifiableId == promise.identifiableId,
                                    editingText: $editingText,
                                    onEdit: { startEditing(promise) },
                                    onSave: { await savePromise(promise) },
                                    onCancel: { cancelEditing() },
                                    onDelete: { await promiseManager.deletePromise(String(promise.identifiableId)) }
                                )
                                
                                if promise.identifiableId != promiseManager.promises.last?.identifiableId {
                                    Divider()
                                        .padding(.leading, 20)
                                }
                            }
                        }
                    }
                }
            }
        }
        .task {
            await promiseManager.fetchPromises()
        }
        .onAppear {
            selectedCaptureMode = autoPromiseManager.getCaptureMode()
        }
    }
    
    // MARK: - Helper Methods
    
    private func startEditing(_ promise: Promise) {
        editingPromise = promise
        editingText = promise.content
    }
    
    private func savePromise(_ promise: Promise) async {
        guard let promiseId = promise.id else { return }
        await promiseManager.updatePromise(id: promiseId, content: editingText)
        editingPromise = nil
        editingText = ""
    }
    
    private func cancelEditing() {
        editingPromise = nil
        editingText = ""
    }
}

// MARK: - Promise Row View
struct PromiseRowView: View {
    let promise: Promise
    let isEditing: Bool
    @Binding var editingText: String
    
    let onEdit: () -> Void
    let onSave: () async -> Void
    let onCancel: () -> Void
    let onDelete: () async -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    if isEditing {
                        TextField("Promise", text: $editingText, axis: .vertical)
                            .textFieldStyle(.roundedBorder)
                            .lineLimit(2...8)
                    } else {
                        Text(promise.content)
                            .font(.body)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    HStack {
                        if promise.isRecent {
                            Text("New")
                                .font(.caption2)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.accentColor)
                                .foregroundColor(.white)
                                .cornerRadius(4)
                        }
                        
                        Text("Created \(promise.formattedCreatedDate)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        
                        if promise.created_at != promise.updated_at {
                            Text("• Updated \(promise.formattedUpdatedDate)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
                
                Spacer()
                
                // Action buttons
                if isEditing {
                    HStack(spacing: 8) {
                        Button("Cancel") {
                            onCancel()
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.small)
                        
                        Button("Save") {
                            Task { await onSave() }
                        }
                        .buttonStyle(PrimaryButtonStyle())
                        .controlSize(.small)
                        .disabled(editingText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    }
                } else {
                    HStack(spacing: 4) {
                        Button(action: onEdit) {
                            Image(systemName: "pencil")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.accentColor)
                        
                        Button(action: {
                            Task { await onDelete() }
                        }) {
                            Image(systemName: "trash")
                                .font(.caption)
                        }
                        .buttonStyle(.plain)
                        .foregroundColor(.red)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }
}

// MARK: - Button Styles
// Note: PrimaryButtonStyle is already defined in AuthView.swift

struct PromisesPane_Previews: PreviewProvider {
    static var previews: some View {
        PromisesPane()
            .frame(width: 400, height: 600)
    }
} 