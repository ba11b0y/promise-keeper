import SwiftUI

struct GeneralSettingsTab: View {
    @StateObject private var autoPromiseManager = AutoPromiseManager.shared
    @State private var selectedCaptureMode: ScreenshotManager.CaptureMode = .onEnter
    
    var body: some View {
        Form {
            Section("Screenshot Capture") {
                VStack(alignment: .leading, spacing: 12) {
                    Picker("Capture Mode:", selection: $selectedCaptureMode) {
                        ForEach(ScreenshotManager.CaptureMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(.menu)
                    .onChange(of: selectedCaptureMode) { _, newMode in
                        autoPromiseManager.setCaptureMode(newMode)
                    }
                    
                    Text(getModeDescription(selectedCaptureMode))
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.top, 4)
                }
            }
            
            Section("Manual Actions") {
                VStack(alignment: .leading, spacing: 8) {
                    Button("Take Screenshot Now") {
                        Task {
                            await autoPromiseManager.processManualScreenshot()
                        }
                    }
                    .buttonStyle(.bordered)
                    
                    Text("Manually capture and analyze a screenshot for promises")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            if let status = autoPromiseManager.processingStatus {
                Section("Status") {
                    HStack {
                        if autoPromiseManager.isProcessing {
                            ProgressView()
                                .scaleEffect(0.8)
                        }
                        Text(status)
                            .font(.caption)
                    }
                }
            }
            
            if let lastProcessed = autoPromiseManager.lastProcessedTime {
                Section("Last Screenshot") {
                    Text("Processed: \(lastProcessed, style: .relative) ago")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            #if DEBUG
            Section("Debug") {
                Button("Widget Sync Debug") {
                    NSApp.sendAction(#selector(NSApplication.orderFrontStandardAboutPanel(_:)), to: nil, from: nil)
                    if let window = NSApplication.shared.keyWindow {
                        let hostingController = NSHostingController(rootView: WidgetSyncDebugView())
                        let panel = NSPanel(contentViewController: hostingController)
                        panel.title = "Widget Sync Debug"
                        panel.styleMask = [.titled, .closable, .miniaturizable, .resizable]
                        panel.setContentSize(NSSize(width: 600, height: 700))
                        panel.center()
                        panel.makeKeyAndOrderFront(nil)
                    }
                }
                .buttonStyle(.bordered)
                
                Text("Debug widget data synchronization")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            #endif
        }
        .padding(20)
        .onAppear {
            selectedCaptureMode = autoPromiseManager.getCaptureMode()
        }
    }
    
    private func getModeDescription(_ mode: ScreenshotManager.CaptureMode) -> String {
        switch mode {
        case .off:
            return "Screenshots will only be taken manually when you click 'Take Screenshot Now'"
        case .interval:
            return "Screenshots will be taken automatically every 30 seconds to monitor for promises"
        case .onEnter:
            return "Screenshots will be taken when you press Enter (maximum once per minute to avoid spam)"
        }
    }
}

struct GeneralSettingsView_Previews: PreviewProvider {
    static var previews: some View {
        GeneralSettingsTab()
    }
}
