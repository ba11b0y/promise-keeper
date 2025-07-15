import SwiftUI

// MARK: - Electron-Matching Promise View (Exact Recreation)
struct ElectronMatchingPromiseView: View {
    @StateObject private var promiseManager = PromiseManager.shared
    @StateObject private var autoPromiseManager = AutoPromiseManager.shared
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    @State private var newPromiseText = ""
    @State private var showingNewPromiseField = false
    @State private var selectedCaptureMode: ScreenshotManager.CaptureMode = .onEnter
    @State private var searchText = ""
    @State private var showingSettings = false
    
    // Statistics
    private var totalPromises: Int { promiseManager.promises.count }
    private var completedPromises: Int { promiseManager.promises.filter { $0.isResolved }.count }
    private var pendingPromises: Int { totalPromises - completedPromises }
    private var completionPercentage: Int { totalPromises > 0 ? Int((Double(completedPromises) / Double(totalPromises)) * 100) : 0 }
    
    // User greeting
    private var userGreeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        let timeOfDay = hour < 12 ? "Good morning" : hour < 17 ? "Good afternoon" : "Good evening"
        let userName = supabaseManager.currentUser?.email?.components(separatedBy: "@").first ?? "User"
        return "\(timeOfDay), \(userName)"
    }
    
    // Filtered promises
    private var filteredPromises: [Promise] {
        if searchText.isEmpty {
            return promiseManager.promises
        } else {
            return promiseManager.promises.filter { promise in
                promise.content.localizedCaseInsensitiveContains(searchText)
            }
        }
    }
    
    var body: some View {
        ZStack {
            // Liquid Background (matching Electron)
            LiquidBackgroundView()
                .ignoresSafeArea()
            
            // Main Content
            VStack(spacing: 0) {
                // Header Section (exact copy of Electron)
                headerSection
                
                // Statistics Cards (exact copy of Electron)
                statisticsSection
                
                // Controls Section (exact copy of Electron) 
                controlsSection
                
                // Add Promise Form (slides in like Electron)
                if showingNewPromiseField {
                    addPromiseFormSection
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .top).combined(with: .opacity)
                        ))
                }
                
                // Promises List (exact copy of Electron)
                promisesListSection
            }
        }
        .background(Color.clear)
        .task {
            await promiseManager.fetchPromises()
        }
        .onAppear {
            print("🎯 ElectronMatchingPromiseView appeared - PromiseManager should be initialized!")
            NSLog("🎯 ElectronMatchingPromiseView appeared - PromiseManager should be initialized!")
            selectedCaptureMode = autoPromiseManager.getCaptureMode()
        }
        .sheet(isPresented: $showingSettings) {
            settingsSheet
        }
    }
    
    // MARK: - Header Section (Exact Copy of Electron)
    private var headerSection: some View {
        VStack(spacing: 0) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(userGreeting)
                        .font(.system(size: 28, weight: .light))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
                        .tracking(-0.02)
                    
                    Text("\(completionPercentage)% of promises completed • \(totalPromises) total")
                        .font(.system(size: 15, weight: .regular))
                        .foregroundColor(Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 0.9))
                        .tracking(0.01)
                }
                
                Spacer()
                
                HStack(spacing: 8) {
                    // Settings Button
                    Button(action: { showingSettings = true }) {
                        HStack(spacing: 8) {
                            Image(systemName: "gearshape")
                                .font(.system(size: 16, weight: .medium))
                            Text("Settings")
                        }
                    }
                    .buttonStyle(ElectronGhostButtonStyle())
                    
                    // Sign Out Button
                    Button(action: handleSignOut) {
                        HStack(spacing: 8) {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                                .font(.system(size: 16, weight: .medium))
                            Text("Sign Out")
                        }
                    }
                    .buttonStyle(ElectronGhostButtonStyle())
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 24)
                    .fill(Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.02))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.04), radius: 20, x: 0, y: 8)
            )
        }
        .padding(.horizontal, 20)
        .padding(.top, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - Statistics Cards (Exact Copy of Electron)
    private var statisticsSection: some View {
        HStack(spacing: 10) {
            // Total Promises (Blue/Orange gradient like Electron)
            StatisticsCard(
                value: totalPromises,
                label: "Total Promises",
                gradientColors: [
                    Color(red: 249/255, green: 115/255, blue: 22/255, opacity: 0.4),
                    Color(red: 254/255, green: 215/255, blue: 170/255, opacity: 0.25)
                ],
                borderColor: Color(red: 249/255, green: 115/255, blue: 22/255, opacity: 0.25),
                backgroundColor: Color(red: 249/255, green: 115/255, blue: 22/255, opacity: 0.08)
            )
            
            // Completed Promises (Green gradient like Electron)
            StatisticsCard(
                value: completedPromises,
                label: "Completed",
                gradientColors: [
                    Color(red: 34/255, green: 197/255, blue: 94/255, opacity: 0.4),
                    Color(red: 134/255, green: 239/255, blue: 172/255, opacity: 0.25)
                ],
                borderColor: Color(red: 34/255, green: 197/255, blue: 94/255, opacity: 0.25),
                backgroundColor: Color(red: 34/255, green: 197/255, blue: 94/255, opacity: 0.08)
            )
            
            // Pending Promises (Red gradient like Electron)
            StatisticsCard(
                value: pendingPromises,
                label: "Pending",
                gradientColors: [
                    Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.4),
                    Color(red: 252/255, green: 165/255, blue: 165/255, opacity: 0.25)
                ],
                borderColor: Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.25),
                backgroundColor: Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.08)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 24)
    }
    
    // MARK: - Controls Section (Exact Copy of Electron)
    private var controlsSection: some View {
        VStack(spacing: 0) {
            HStack(spacing: 12) {
                // Search Container
                HStack(spacing: 0) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 0.8))
                        .padding(.leading, 14)
                    
                    TextField("Search promises...", text: $searchText)
                        .font(.system(size: 15))
                        .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
                        .padding(.vertical, 12)
                        .padding(.trailing, 16)
                        .background(Color.clear)
                }
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.02))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                )
                
                // New Promise Button
                Button(action: { withAnimation(.easeInOut(duration: 0.2)) { showingNewPromiseField.toggle() } }) {
                    HStack(spacing: 8) {
                        Image(systemName: showingNewPromiseField ? "xmark" : "plus")
                            .font(.system(size: 16, weight: .medium))
                        Text(showingNewPromiseField ? "Cancel" : "New Promise")
                    }
                }
                .buttonStyle(ElectronPrimaryButtonStyle())
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color(red: 173/255, green: 216/255, blue: 230/255, opacity: 0.15))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color(red: 173/255, green: 216/255, blue: 230/255, opacity: 0.2), lineWidth: 0.5)
                    )
                    .shadow(color: Color(red: 135/255, green: 206/255, blue: 235/255, opacity: 0.08), radius: 8, x: 0, y: 4)
            )
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Add Promise Form Section (Exact Copy of Electron)
    private var addPromiseFormSection: some View {
        VStack(spacing: 16) {
            TextField("I promise to...", text: $newPromiseText)
                .font(.system(size: 15))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.02))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16)
                                .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                        )
                )
            
            HStack(spacing: 8) {
                Button("Add Promise") {
                    Task {
                        await addPromise()
                    }
                }
                .buttonStyle(ElectronPrimaryButtonStyle())
                .disabled(newPromiseText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                
                Button("Cancel") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingNewPromiseField = false
                        newPromiseText = ""
                    }
                }
                .buttonStyle(ElectronGhostButtonStyle())
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.02))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.03), radius: 8, x: 0, y: 4)
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }
    
    // MARK: - Promises List Section (Exact Copy of Electron)
    private var promisesListSection: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if filteredPromises.isEmpty {
                    emptyStateView
                } else {
                    ForEach(Array(filteredPromises.enumerated()), id: \.element.identifiableId) { index, promise in
                        ElectronPromiseCard(
                            promise: promise,
                            onToggleResolved: { await togglePromiseResolution(String(promise.identifiableId)) },
                            onDelete: { await deletePromise(String(promise.identifiableId)) }
                        )
                        .transition(.asymmetric(
                            insertion: .move(edge: .top).combined(with: .opacity),
                            removal: .move(edge: .leading).combined(with: .opacity)
                        ))
                        .animation(.easeInOut(duration: 0.3).delay(Double(index) * 0.05), value: filteredPromises.count)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 40)
        }
    }
    
    // MARK: - Empty State View (Exact Copy of Electron)
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 100/255, green: 116/255, blue: 139/255, opacity: 0.03))
                .frame(width: 48, height: 48)
                .overlay(
                    Image(systemName: searchText.isEmpty ? "sparkles" : "magnifyingglass")
                        .font(.system(size: 24))
                        .foregroundColor(Color(red: 100/255, green: 116/255, blue: 139/255, opacity: 0.3))
                )
            
            Text(searchText.isEmpty ? "No promises yet" : "No promises match your search")
                .font(.system(size: 16, weight: .regular))
                .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255, opacity: 0.7))
            
            Text(searchText.isEmpty ? "Create your first promise to get started" : "Try adjusting your search terms")
                .font(.system(size: 13))
                .foregroundColor(Color(red: 100/255, green: 116/255, blue: 139/255, opacity: 0.5))
            
            if searchText.isEmpty {
                Button("Add Your First Promise") {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        showingNewPromiseField = true
                    }
                }
                .buttonStyle(ElectronPrimaryButtonStyle())
                .padding(.top, 8)
            }
        }
        .padding(60)
    }
    
    // MARK: - Settings Sheet
    private var settingsSheet: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Screenshot Configuration")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(Color(red: 15/255, green: 23/255, blue: 42/255, opacity: 0.9))
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Screenshot Mode")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255, opacity: 0.8))
                        
                        Picker("Screenshot Mode", selection: $selectedCaptureMode) {
                            Text("Off (Manual only)").tag(ScreenshotManager.CaptureMode.off)
                            Text("Every 30 seconds").tag(ScreenshotManager.CaptureMode.interval)
                            Text("On Enter key press").tag(ScreenshotManager.CaptureMode.onEnter)
                        }
                        .pickerStyle(.menu)
                        .onChange(of: selectedCaptureMode) {
                            autoPromiseManager.setCaptureMode(selectedCaptureMode)
                        }
                        
                        Text("Choose when to automatically capture screenshots for promise tracking. Enter mode captures at most once per minute when Enter is pressed globally.")
                            .font(.system(size: 11))
                            .foregroundColor(Color(red: 100/255, green: 116/255, blue: 139/255, opacity: 0.6))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    
                    Button("📸 Take Screenshot Now") {
                        Task {
                            await autoPromiseManager.processManualScreenshot()
                        }
                    }
                    .buttonStyle(ElectronSecondaryButtonStyle())
                }
                
                Spacer()
            }
            .padding(20)
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        showingSettings = false
                    }
                }
            }
        }
    }
    
    // MARK: - Helper Methods
    private func addPromise() async {
        let content = newPromiseText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !content.isEmpty else { return }
        
        await promiseManager.createPromise(content: content)
        if promiseManager.errorMessage == nil {
            withAnimation(.easeInOut(duration: 0.2)) {
                newPromiseText = ""
                showingNewPromiseField = false
            }
        }
    }
    
    private func togglePromiseResolution(_ id: String) async {
        await promiseManager.togglePromiseResolution(id)
    }
    
    private func deletePromise(_ id: String) async {
        await promiseManager.deletePromise(id)
    }
    
    private func handleSignOut() {
        Task {
            await supabaseManager.signOut()
        }
    }
}

// MARK: - Statistics Card (Exact Copy of Electron Design)
struct StatisticsCard: View {
    let value: Int
    let label: String
    let gradientColors: [Color]
    let borderColor: Color
    let backgroundColor: Color
    
    @State private var isHovered = false
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(value)")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
                .tracking(-0.02)
            
            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(Color(red: 107/255, green: 114/255, blue: 128/255, opacity: 0.9))
                .tracking(0.08)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 16)
        .padding(.vertical, 18)
        .background(
            ZStack {
                // Background color
                RoundedRectangle(cornerRadius: 20)
                    .fill(isHovered ? backgroundColor.opacity(0.15) : backgroundColor)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                
                // Gradient overlay
                RoundedRectangle(cornerRadius: 20)
                    .fill(
                        LinearGradient(
                            colors: gradientColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .opacity(isHovered ? 0.4 : 0.25)
            }
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20)
                .stroke(isHovered ? borderColor.opacity(0.4) : borderColor, lineWidth: 0.5)
        )
        .shadow(
            color: isHovered ? borderColor.opacity(0.15) : .black.opacity(0.03),
            radius: isHovered ? 12 : 8,
            x: 0,
            y: isHovered ? 8 : 4
        )
        .scaleEffect(isHovered ? 1.02 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Electron Promise Card (Exact Copy of Electron Design)
struct ElectronPromiseCard: View {
    let promise: Promise
    let onToggleResolved: () async -> Void
    let onDelete: () async -> Void
    
    @State private var isHovered = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            // Checkbox (exact copy of Electron)
            Button(action: {
                Task { await onToggleResolved() }
            }) {
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(
                            promise.isResolved ? 
                                Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9) :
                                Color.white.opacity(0.12),
                            lineWidth: 1
                        )
                        .background(
                            RoundedRectangle(cornerRadius: 6)
                                .fill(promise.isResolved ? 
                                    Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9) :
                                    Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.02)
                                )
                                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 6))
                        )
                        .frame(width: 18, height: 18)
                    
                    if promise.isResolved {
                        Image(systemName: "checkmark")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white)
                            .scaleEffect(promise.isResolved ? 1.0 : 0.0)
                            .animation(.easeInOut(duration: 0.15), value: promise.isResolved)
                    }
                }
            }
            .buttonStyle(.plain)
            .padding(.top, 2)
            
            // Promise Content
            VStack(alignment: .leading, spacing: 6) {
                Text(promise.content)
                    .font(.system(size: 15, weight: .regular))
                    .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .tracking(0.01)
                    .strikethrough(promise.isResolved)
                    .animation(.easeInOut(duration: 0.3), value: promise.isResolved)
            }
            
            Spacer()
            
            // Actions
            HStack(spacing: 4) {
                // Screenshot indicators (if applicable)
                if promise.isFromScreenshot {
                    Button(action: {}) {
                        Image(systemName: "camera.fill")
                            .font(.system(size: 12))
                            .foregroundColor(Color(red: 0/255, green: 122/255, blue: 255/255, opacity: 0.9))
                            .padding(4)
                    }
                    .buttonStyle(.plain)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.05))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                            )
                    )
                }
                
                // Delete button
                Button(action: {
                    Task { await onDelete() }
                }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.9))
                }
                .buttonStyle(.plain)
                .frame(width: 28, height: 28)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(isHovered ? Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.12) : Color.clear)
                )
                .opacity(isHovered ? 1.0 : 0.6)
            }
            .opacity(isHovered ? 1.0 : 0.6)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(promise.isResolved ? 
                    Color(red: 52/255, green: 199/255, blue: 89/255, opacity: isHovered ? 0.12 : 0.08) :
                    Color(red: 255/255, green: 255/255, blue: 255/255, opacity: isHovered ? 0.04 : 0.02)
                )
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(promise.isResolved ?
                            Color(red: 52/255, green: 199/255, blue: 89/255, opacity: isHovered ? 0.2 : 0.15) :
                            Color.white.opacity(isHovered ? 0.08 : 0.05),
                            lineWidth: 0.5
                        )
                )
                .shadow(
                    color: promise.isResolved ? 
                        Color(red: 52/255, green: 199/255, blue: 89/255, opacity: isHovered ? 0.15 : 0.04) :
                        .black.opacity(isHovered ? 0.04 : 0.02),
                    radius: isHovered ? 12 : 4,
                    x: 0,
                    y: isHovered ? 8 : 2
                )
        )
        .scaleEffect(isHovered ? 1.0 : 1.0)
        .offset(y: isHovered ? -2 : 0)
        .animation(.easeInOut(duration: 0.2), value: isHovered)
        .onHover { hovering in
            isHovered = hovering
        }
    }
}

// MARK: - Electron Button Styles (Exact Copy)
struct ElectronPrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(.white)
            .tracking(0.02)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: configuration.isPressed ? 1.0 : 0.9))
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )
                    .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 4)
                    .shadow(color: .white.opacity(0.08), radius: 0, x: 0, y: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .offset(y: configuration.isPressed ? 1 : -1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ElectronGhostButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color(red: 96/255, green: 96/255, blue: 96/255, opacity: configuration.isPressed ? 0.9 : 0.8))
            .tracking(0.02)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 255/255, green: 255/255, blue: 255/255, opacity: configuration.isPressed ? 0.04 : 0.02))
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(configuration.isPressed ? 0.12 : 0.08), lineWidth: 0.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .offset(y: configuration.isPressed ? 0.5 : -0.5)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ElectronSecondaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 15, weight: .medium))
            .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255, opacity: 0.9))
            .tracking(0.02)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.02))
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color(red: 59/255, green: 130/255, blue: 246/255, opacity: configuration.isPressed ? 0.2 : 0.15), lineWidth: 0.5)
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .offset(y: configuration.isPressed ? 0.5 : -0.5)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct ElectronMatchingPromiseView_Previews: PreviewProvider {
    static var previews: some View {
        ElectronMatchingPromiseView()
            .environmentObject(SupabaseManager.shared)
            .frame(width: 900, height: 700)
    }
}