import SwiftUI

// MARK: - Modern Promise View with Widget-like Glass Effects
struct ModernPromiseView: View {
    @StateObject private var promiseManager = PromiseManager.shared
    @StateObject private var autoPromiseManager = AutoPromiseManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    @State private var newPromiseText = ""
    @State private var showingNewPromiseField = false
    @State private var selectedCaptureMode: ScreenshotManager.CaptureMode = .onEnter
    
    var body: some View {
        ZStack {
            // Glass background with blur effect (matching Electron app)
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            // Main content
            VStack(spacing: 0) {
                // Header with glass panel effect
                headerSection
                
                // Authentication or main content
                if supabaseManager.isAuthenticated {
                    mainContentSection
                } else {
                    authenticationSection
                }
            }
        }
        .background(Color.clear)
        .task {
            if supabaseManager.isAuthenticated {
                await promiseManager.fetchPromises()
            }
        }
        .onAppear {
            selectedCaptureMode = autoPromiseManager.getCaptureMode()
        }
    }
    
    // MARK: - Header Section
    private var headerSection: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text("Promise Keeper")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                
                if supabaseManager.isAuthenticated {
                    Text("\(promiseManager.promises.count) promises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text("Welcome back")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if supabaseManager.isAuthenticated {
                Button(action: {
                    showingNewPromiseField.toggle()
                    if showingNewPromiseField {
                        newPromiseText = ""
                    }
                }) {
                    Image(systemName: showingNewPromiseField ? "xmark.circle.fill" : "plus.circle.fill")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
    
    // MARK: - Authentication Section
    private var authenticationSection: some View {
        VStack(spacing: 24) {
            Spacer()
            
            // Authentication form with glass effect
            VStack(spacing: 20) {
                Text("Sign in to continue")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                // TODO: Add authentication form similar to AuthView
                Button("Open Authentication") {
                    // This would open the existing AuthView
                }
                .buttonStyle(GlassButtonStyle())
            }
            .padding(32)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(.regularMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.2), lineWidth: 1)
                    )
            )
            .padding(.horizontal, 24)
            
            Spacer()
        }
    }
    
    // MARK: - Main Content Section
    private var mainContentSection: some View {
        VStack(spacing: 16) {
            // New promise input (matching Electron app)
            if showingNewPromiseField {
                newPromiseInputSection
            }
            
            // Screenshot controls (identical to Electron app)
            screenshotControlsSection
            
            // Promises list
            promisesListSection
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 16)
    }
    
    // MARK: - New Promise Input Section
    private var newPromiseInputSection: some View {
        VStack(spacing: 16) {
            TextField("What promise do you want to make today?", text: $newPromiseText, axis: .vertical)
                .textFieldStyle(GlassTextFieldStyle())
                .lineLimit(2...6)
            
            HStack {
                Button("Cancel") {
                    showingNewPromiseField = false
                    newPromiseText = ""
                }
                .buttonStyle(GlassButtonStyle(variant: .secondary))
                
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
                .buttonStyle(GlassButtonStyle(variant: .primary))
                .disabled(newPromiseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Screenshot Controls Section
    private var screenshotControlsSection: some View {
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
                .buttonStyle(GlassButtonStyle(variant: .secondary))
                .disabled(autoPromiseManager.isProcessing)
            }
            
            // Processing status
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
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.blue.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.blue.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Promises List Section
    private var promisesListSection: some View {
        VStack(spacing: 0) {
            if promiseManager.isLoading && promiseManager.promises.isEmpty {
                loadingStateView
            } else if promiseManager.promises.isEmpty {
                emptyStateView
            } else {
                promisesList
            }
        }
    }
    
    private var loadingStateView: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(0.8)
            Text("Loading promises...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Image(systemName: "sparkles")
                .font(.system(size: 48))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text("No promises yet")
                .font(.headline)
                .foregroundColor(.primary)
            
            Text("Create your first promise to get started")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Add Your First Promise") {
                showingNewPromiseField = true
            }
            .buttonStyle(GlassButtonStyle(variant: .primary))
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                )
        )
    }
    
    private var promisesList: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ForEach(promiseManager.promises, id: \.identifiableId) { promise in
                    ModernPromiseCard(promise: promise)
                }
            }
            .padding(.vertical, 8)
        }
    }
}

// MARK: - Modern Promise Card
struct ModernPromiseCard: View {
    let promise: Promise
    @State private var isHovered = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Promise content
            Text(promise.content)
                .font(.body)
                .lineLimit(nil)
                .foregroundColor(.primary)
            
            // Metadata row
            HStack {
                // Promise indicators
                HStack(spacing: 6) {
                    if promise.isFromScreenshot {
                        Label("Screenshot", systemImage: "camera.fill")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .foregroundColor(.blue)
                            .cornerRadius(4)
                    }
                    
                    if promise.isResolved {
                        Label("Resolved", systemImage: "checkmark.circle.fill")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.green.opacity(0.2))
                            .foregroundColor(.green)
                            .cornerRadius(4)
                    }
                    
                    if promise.isRecent {
                        Label("New", systemImage: "sparkles")
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.orange.opacity(0.2))
                            .foregroundColor(.orange)
                            .cornerRadius(4)
                    }
                }
                
                Spacer()
                
                // Date
                Text(promise.formattedCreatedDate)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(.regularMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(isHovered ? 0.3 : 0.1), lineWidth: 0.5)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Custom Styles
struct GlassButtonStyle: ButtonStyle {
    enum Variant {
        case primary, secondary
    }
    
    let variant: Variant
    
    init(variant: Variant = .primary) {
        self.variant = variant
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(variant == .primary ? .regularMaterial : .ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct GlassTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
    }
}

// Note: VisualEffectView is now defined in SharedStyles.swift

struct ModernPromiseView_Previews: PreviewProvider {
    static var previews: some View {
        ModernPromiseView()
            .frame(width: 400, height: 600)
    }
}