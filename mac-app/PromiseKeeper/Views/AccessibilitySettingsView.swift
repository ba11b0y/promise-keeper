import SwiftUI

struct AccessibilitySettingsView: View {
    @StateObject private var accessibilityHelper = AccessibilityHelper.shared
    @State private var showingInstructions = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Image(systemName: "lock.shield.fill")
                    .font(.title2)
                    .foregroundColor(.accentColor)
                
                Text("Accessibility Permission")
                    .font(.title2)
                    .fontWeight(.semibold)
            }
            
            // Status
            HStack {
                Circle()
                    .fill(accessibilityHelper.isAccessibilityEnabled ? Color.green : Color.red)
                    .frame(width: 10, height: 10)
                
                Text(accessibilityHelper.isAccessibilityEnabled ? "Permission Granted" : "Permission Required")
                    .foregroundColor(accessibilityHelper.isAccessibilityEnabled ? .green : .red)
                
                Spacer()
                
                if accessibilityHelper.isCheckingPermission {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(accessibilityHelper.isAccessibilityEnabled ? Color.green.opacity(0.1) : Color.red.opacity(0.1))
            )
            
            // Description
            Text("Promise Keeper needs accessibility permission to detect when you press Enter and automatically capture screenshots.")
                .font(.caption)
                .foregroundColor(.secondary)
            
            // Action buttons
            if !accessibilityHelper.isAccessibilityEnabled {
                VStack(spacing: 12) {
                    Button(action: {
                        accessibilityHelper.requestAccessibilityPermission()
                    }) {
                        Label("Enable Permission", systemImage: "checkmark.shield")
                            .frame(maxWidth: .infinity)
                    }
                    .controlSize(.large)
                    .buttonStyle(.borderedProminent)
                    
                    HStack {
                        Button(action: {
                            accessibilityHelper.openSystemPreferences()
                        }) {
                            Label("Open System Settings", systemImage: "gear")
                                .font(.caption)
                        }
                        .buttonStyle(.link)
                        
                        Spacer()
                        
                        Button(action: {
                            showingInstructions = true
                        }) {
                            Label("Instructions", systemImage: "questionmark.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.link)
                    }
                }
            } else {
                // Success state
                VStack(spacing: 12) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("Enter key detection is active")
                            .font(.callout)
                    }
                    
                    Text("The app will capture screenshots when you press Enter.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.green.opacity(0.05))
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
            }
        }
        .padding()
        .sheet(isPresented: $showingInstructions) {
            InstructionsView()
        }
    }
}

struct InstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Text("How to Enable Accessibility")
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Button("Done") {
                    dismiss()
                }
            }
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    InstructionStep(
                        number: 1,
                        title: "Click Enable Permission",
                        description: "This will open System Settings and prompt you to grant permission."
                    )
                    
                    InstructionStep(
                        number: 2,
                        title: "Find PromiseKeeper",
                        description: "In the Privacy & Security > Accessibility list, locate PromiseKeeper."
                    )
                    
                    InstructionStep(
                        number: 3,
                        title: "Toggle the Switch",
                        description: "Click the toggle switch next to PromiseKeeper to enable it."
                    )
                    
                    InstructionStep(
                        number: 4,
                        title: "Enter Your Password",
                        description: "You may need to enter your Mac password to confirm."
                    )
                    
                    InstructionStep(
                        number: 5,
                        title: "Return to App",
                        description: "Come back to PromiseKeeper - the permission should now be active!"
                    )
                    
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Label("Why is this needed?", systemImage: "info.circle.fill")
                            .font(.headline)
                        
                        Text("Accessibility permission allows PromiseKeeper to detect when you press the Enter key, even when the app is in the background. This enables automatic screenshot capture without interrupting your workflow.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
            }
        }
        .padding()
        .frame(width: 450, height: 500)
    }
}

struct InstructionStep: View {
    let number: Int
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text("\(number)")
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .frame(width: 30, height: 30)
                .background(Circle().fill(Color.accentColor))
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .fontWeight(.medium)
                Text(description)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }
}

// Preview
#Preview {
    AccessibilitySettingsView()
        .frame(width: 400)
}