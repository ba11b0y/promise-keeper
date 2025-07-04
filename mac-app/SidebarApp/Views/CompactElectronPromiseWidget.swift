import SwiftUI

// MARK: - Compact Electron Promise Widget (Optimized for Sidebar)
struct CompactElectronPromiseWidget: View {
    @StateObject private var promiseManager = PromiseManager()
    @StateObject private var autoPromiseManager = AutoPromiseManager.shared
    @EnvironmentObject var supabaseManager: SupabaseManager
    
    @State private var selectedCaptureMode: ScreenshotManager.CaptureMode = .onEnter
    @State private var showingSettings = false
    
    // Statistics
    private var totalPromises: Int { promiseManager.promises.count }
    private var completedPromises: Int { promiseManager.promises.filter { $0.isResolved }.count }
    private var pendingPromises: Int { totalPromises - completedPromises }
    private var completionPercentage: Int { totalPromises > 0 ? Int((Double(completedPromises) / Double(totalPromises)) * 100) : 0 }
    
    var body: some View {
        ZStack {
            // Translucent background
            LiquidBackgroundView()
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 16) {
                    // Compact Header
                    compactHeaderSection
                    
                    // Mini Statistics Cards
                    miniStatsSection
                    
                    // Quick Controls
                    quickControlsSection
                    
                    // Compact Promises List
                    compactPromisesList
                }
                .padding(16)
            }
        }
        .navigationTitle("Promise Widget")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button(action: { showingSettings = true }) {
                    Image(systemName: "gearshape")
                }
            }
        }
        .task {
            await promiseManager.fetchPromises()
        }
        .onAppear {
            selectedCaptureMode = autoPromiseManager.getCaptureMode()
        }
        .sheet(isPresented: $showingSettings) {
            compactSettingsSheet
        }
    }
    
    // MARK: - Compact Header
    private var compactHeaderSection: some View {
        VStack(spacing: 8) {
            Text("Promise Keeper")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: 0.9))
            
            Text("\(completionPercentage)% completed • \(totalPromises) total")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(Color(red: 0/255, green: 0/255, blue: 0/255, opacity: 0.7))
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(red: 255/255, green: 255/255, blue: 255/255, opacity: 0.02))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.05), lineWidth: 0.5)
                )
        )
    }
    
    // MARK: - Mini Statistics
    private var miniStatsSection: some View {
        HStack(spacing: 8) {
            MiniStatCard(
                value: totalPromises,
                label: "Total",
                color: Color(red: 249/255, green: 115/255, blue: 22/255)
            )
            
            MiniStatCard(
                value: completedPromises,
                label: "Done",
                color: Color(red: 34/255, green: 197/255, blue: 94/255)
            )
            
            MiniStatCard(
                value: pendingPromises,
                label: "Pending",
                color: Color(red: 239/255, green: 68/255, blue: 68/255)
            )
        }
    }
    
    // MARK: - Quick Controls
    private var quickControlsSection: some View {
        HStack(spacing: 12) {
            Button("📸 Capture") {
                Task {
                    await autoPromiseManager.processManualScreenshot()
                }
            }
            .buttonStyle(CompactWidgetButtonStyle())
            
            Button("⚙️ Settings") {
                showingSettings = true
            }
            .buttonStyle(CompactWidgetButtonStyle())
        }
    }
    
    // MARK: - Compact Promises List
    private var compactPromisesList: some View {
        LazyVStack(spacing: 6) {
            if promiseManager.promises.isEmpty {
                Text("No promises yet")
                    .font(.system(size: 14))
                    .foregroundColor(.secondary)
                    .padding(20)
            } else {
                ForEach(Array(promiseManager.promises.prefix(10).enumerated()), id: \.element.identifiableId) { index, promise in
                    CompactPromiseRow(
                        promise: promise,
                        onToggleResolved: { await togglePromiseResolution(String(promise.identifiableId)) }
                    )
                }
                
                if promiseManager.promises.count > 10 {
                    Button("View All \(promiseManager.promises.count) Promises") {
                        // This could expand to full view or navigate
                    }
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(8)
                }
            }
        }
    }
    
    // MARK: - Compact Settings
    private var compactSettingsSheet: some View {
        NavigationView {
            VStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Screenshot Mode")
                        .font(.system(size: 14, weight: .medium))
                    
                    Picker("Mode", selection: $selectedCaptureMode) {
                        Text("Off").tag(ScreenshotManager.CaptureMode.off)
                        Text("Every 30s").tag(ScreenshotManager.CaptureMode.interval)
                        Text("On Enter").tag(ScreenshotManager.CaptureMode.onEnter)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: selectedCaptureMode) {
                        autoPromiseManager.setCaptureMode(selectedCaptureMode)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Widget Settings")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button("Done") {
                        showingSettings = false
                    }
                }
            }
        }
        .frame(width: 300, height: 200)
    }
    
    // MARK: - Helper Methods
    private func togglePromiseResolution(_ id: String) async {
        await promiseManager.togglePromiseResolution(id)
    }
}

// MARK: - Mini Stat Card
struct MiniStatCard: View {
    let value: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text("\(value)")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)
            
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Compact Promise Row
struct CompactPromiseRow: View {
    let promise: Promise
    let onToggleResolved: () async -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            // Checkbox
            Button(action: {
                Task { await onToggleResolved() }
            }) {
                Image(systemName: promise.isResolved ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(promise.isResolved ? .green : .secondary)
                    .font(.system(size: 14))
            }
            .buttonStyle(.plain)
            
            // Promise text
            Text(promise.content)
                .font(.system(size: 12))
                .foregroundColor(promise.isResolved ? .secondary : .primary)
                .strikethrough(promise.isResolved)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            // Screenshot indicator
            if promise.isFromScreenshot {
                Image(systemName: "camera.fill")
                    .font(.system(size: 10))
                    .foregroundColor(.blue)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(promise.isResolved ? Color.green.opacity(0.05) : Color.clear)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
        )
    }
}

// MARK: - Compact Widget Button Style
struct CompactWidgetButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(.white)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 17/255, green: 24/255, blue: 39/255, opacity: configuration.isPressed ? 1.0 : 0.8))
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
            )
            .scaleEffect(configuration.isPressed ? 0.95 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct CompactElectronPromiseWidget_Previews: PreviewProvider {
    static var previews: some View {
        CompactElectronPromiseWidget()
            .environmentObject(SupabaseManager.shared)
            .frame(width: 300, height: 600)
    }
}