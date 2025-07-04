import SwiftUI

// MARK: - Compact Promise View (Widget-like Interface)
struct CompactPromiseView: View {
    @StateObject private var promiseManager = PromiseManager()
    @StateObject private var autoPromiseManager = AutoPromiseManager.shared
    @StateObject private var supabaseManager = SupabaseManager.shared
    
    @State private var newPromiseText = ""
    @State private var showingNewPromiseField = false
    @State private var selectedCaptureMode: ScreenshotManager.CaptureMode = .onEnter
    @State private var isExpanded = false
    
    // Compact dimensions (matching Electron app)
    private let compactWidth: CGFloat = 320
    private let compactHeight: CGFloat = 480
    private let expandedWidth: CGFloat = 400
    private let expandedHeight: CGFloat = 600
    
    var body: some View {
        ZStack {
            // Glass background with heavy blur (widget-like)
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                .ignoresSafeArea()
            
            // Main compact content
            VStack(spacing: 0) {
                // Compact header
                compactHeaderSection
                
                if supabaseManager.isAuthenticated {
                    compactMainContentSection
                } else {
                    compactAuthSection
                }
            }
        }
        .frame(
            width: isExpanded ? expandedWidth : compactWidth,
            height: isExpanded ? expandedHeight : compactHeight
        )
        .background(Color.clear)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
        )
        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
        .task {
            if supabaseManager.isAuthenticated {
                await promiseManager.fetchPromises()
            }
        }
        .onAppear {
            selectedCaptureMode = autoPromiseManager.getCaptureMode()
        }
    }
    
    // MARK: - Compact Header Section
    private var compactHeaderSection: some View {
        HStack(spacing: 12) {
            // App icon and title
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.title2)
                    .foregroundColor(.blue)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text("Promise Keeper")
                        .font(.headline)
                        .fontWeight(.semibold)
                        .foregroundColor(.primary)
                    
                    if supabaseManager.isAuthenticated {
                        Text("\(promiseManager.promises.count) promises")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    } else {
                        Text("Sign in required")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
            
            Spacer()
            
            // Action buttons
            HStack(spacing: 8) {
                if supabaseManager.isAuthenticated {
                    // Expand/Collapse button
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            isExpanded.toggle()
                        }
                    }) {
                        Image(systemName: isExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                    
                    // Add promise button
                    Button(action: {
                        showingNewPromiseField.toggle()
                        if showingNewPromiseField {
                            newPromiseText = ""
                        }
                    }) {
                        Image(systemName: showingNewPromiseField ? "xmark.circle.fill" : "plus.circle.fill")
                            .font(.title3)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(16)
        .background(
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [.white.opacity(0.1), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
        )
    }
    
    // MARK: - Compact Auth Section
    // Note: This section should not be shown since MainScene now handles auth flow
    private var compactAuthSection: some View {
        VStack(spacing: 16) {
            Text("Loading...")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(20)
    }
    
    // MARK: - Compact Main Content Section
    private var compactMainContentSection: some View {
        VStack(spacing: 0) {
            // Add promise input (compact)
            if showingNewPromiseField {
                compactNewPromiseSection
                
                Divider()
                    .padding(.horizontal, 16)
            }
            
            // Screenshot controls (compact)
            compactScreenshotSection
            
            Divider()
                .padding(.horizontal, 16)
            
            // Promises list (compact)
            compactPromisesList
        }
    }
    
    // MARK: - Compact New Promise Section
    private var compactNewPromiseSection: some View {
        VStack(spacing: 12) {
            TextField("What promise do you want to make?", text: $newPromiseText, axis: .vertical)
                .textFieldStyle(CompactTextFieldStyle())
                .lineLimit(2...4)
            
            HStack(spacing: 8) {
                Button("Cancel") {
                    showingNewPromiseField = false
                    newPromiseText = ""
                }
                .buttonStyle(CompactButtonStyle(variant: .secondary))
                .font(.caption)
                
                Spacer()
                
                Button("Add") {
                    Task {
                        await promiseManager.createPromise(content: newPromiseText)
                        if promiseManager.errorMessage == nil {
                            newPromiseText = ""
                            showingNewPromiseField = false
                        }
                    }
                }
                .buttonStyle(CompactButtonStyle(variant: .primary))
                .font(.caption)
                .disabled(newPromiseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
        }
        .padding(16)
        .background(Color.blue.opacity(0.05))
    }
    
    // MARK: - Compact Screenshot Section
    private var compactScreenshotSection: some View {
        VStack(spacing: 8) {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Screenshots")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.primary)
                    
                    Picker("Mode", selection: $selectedCaptureMode) {
                        ForEach(ScreenshotManager.CaptureMode.allCases, id: \.self) { mode in
                            Text(mode == .off ? "Off" : mode == .interval ? "30s" : "Enter").tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedCaptureMode) { newMode in
                        autoPromiseManager.setCaptureMode(newMode)
                    }
                }
                
                Button("📸") {
                    Task {
                        await autoPromiseManager.processManualScreenshot()
                    }
                }
                .buttonStyle(CompactButtonStyle(variant: .secondary))
                .font(.caption)
                .disabled(autoPromiseManager.isProcessing)
            }
            
            // Processing status (compact)
            if let status = autoPromiseManager.processingStatus {
                HStack(spacing: 6) {
                    if autoPromiseManager.isProcessing {
                        ProgressView()
                            .scaleEffect(0.5)
                    }
                    Text(status)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                    Spacer()
                }
            }
        }
        .padding(12)
    }
    
    // MARK: - Compact Promises List
    private var compactPromisesList: some View {
        ScrollView {
            LazyVStack(spacing: 6) {
                if promiseManager.isLoading && promiseManager.promises.isEmpty {
                    // Compact loading state
                    VStack(spacing: 8) {
                        ProgressView()
                            .scaleEffect(0.7)
                        Text("Loading...")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                } else if promiseManager.promises.isEmpty {
                    // Compact empty state
                    VStack(spacing: 12) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 32))
                            .foregroundColor(.secondary.opacity(0.4))
                        
                        Text("No promises yet")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.secondary)
                        
                        Button("Add your first promise") {
                            showingNewPromiseField = true
                        }
                        .buttonStyle(CompactButtonStyle())
                        .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(20)
                } else {
                    // Promises list (compact)
                    ForEach(promiseManager.promises.prefix(isExpanded ? 10 : 5), id: \.identifiableId) { promise in
                        CompactPromiseCard(promise: promise)
                    }
                    
                    if promiseManager.promises.count > (isExpanded ? 10 : 5) {
                        Button("View all \(promiseManager.promises.count) promises") {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                isExpanded = true
                            }
                        }
                        .buttonStyle(CompactButtonStyle(variant: .secondary))
                        .font(.caption)
                        .padding(.vertical, 8)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 16)
        }
    }
}

// MARK: - Compact Promise Card
struct CompactPromiseCard: View {
    let promise: Promise
    @State private var isHovered = false
    
    var body: some View {
        HStack(spacing: 10) {
            // Promise indicator
            Circle()
                .fill(promise.isResolved ? Color.green : (promise.isFromScreenshot ? Color.blue : Color.orange))
                .frame(width: 8, height: 8)
            
            // Promise content
            VStack(alignment: .leading, spacing: 4) {
                Text(promise.content)
                    .font(.caption)
                    .lineLimit(2)
                    .foregroundColor(.primary)
                
                HStack(spacing: 6) {
                    // Indicators
                    if promise.isFromScreenshot {
                        Label("📸", systemImage: "")
                            .font(.caption2)
                    }
                    
                    if promise.isRecent {
                        Label("New", systemImage: "")
                            .font(.caption2)
                            .foregroundColor(.orange)
                    }
                    
                    Spacer()
                    
                    Text(promise.formattedCreatedDate)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(Color.white.opacity(isHovered ? 0.2 : 0.05), lineWidth: 0.5)
                )
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Compact Button Style
struct CompactButtonStyle: ButtonStyle {
    enum Variant {
        case primary, secondary
    }
    
    let variant: Variant
    
    init(variant: Variant = .primary) {
        self.variant = variant
    }
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(variant == .primary ? .regularMaterial : .ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(
                                variant == .primary ? Color.blue.opacity(0.3) : Color.white.opacity(0.2),
                                lineWidth: 0.5
                            )
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

// MARK: - Compact Text Field Style
struct CompactTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(8)
            .background(
                RoundedRectangle(cornerRadius: 6)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                    )
            )
    }
}

struct CompactPromiseView_Previews: PreviewProvider {
    static var previews: some View {
        CompactPromiseView()
    }
}