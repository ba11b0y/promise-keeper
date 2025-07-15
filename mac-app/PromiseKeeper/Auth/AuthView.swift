import SwiftUI

struct AuthView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var isShowingSignUp = false
    @State private var email = ""
    @State private var password = ""
    @State private var fullName = ""
    @State private var isPasswordVisible = false
    
    var body: some View {
        ZStack {
            // Liquid Background Effect (matching Electron app)
            LiquidBackgroundView()
                .ignoresSafeArea()
            
            // Main Glass Container (exact copy of Electron design)
            VStack {
                Spacer()
                
                // Glass Panel Container
                ZStack {
                    // Ultra-subtle glass panel (matching Electron)
                    RoundedRectangle(cornerRadius: 24)
                        .fill(Color(red: 248/255, green: 250/255, blue: 255/255, opacity: 0.35))
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                        )
                        .shadow(color: .black.opacity(0.03), radius: 16, x: 0, y: 8)
                    
                    // Inner highlight (matching Electron)
                    RoundedRectangle(cornerRadius: 23.5)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.03), Color.clear],
                                startPoint: .top,
                                endPoint: .center
                            )
                        )
                        .padding(0.5)
                    
                    // Content
                    VStack(spacing: 32) {
                        // Auth Header (exact copy of Electron)
                        authHeaderSection
                        
                        // Error/Success Messages
                        if let errorMessage = supabaseManager.errorMessage {
                            authMessage(text: errorMessage, type: .error)
                        }
                        
                        // Auth Form (exact copy of Electron styling)
                        authFormSection
                        
                        // Toggle Sign Up/In (exact copy of Electron)
                        authToggleSection
                    }
                    .padding(40)
                }
                .frame(maxWidth: 400)
                .padding(20)
                
                Spacer()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: isShowingSignUp)
    }
    
    // MARK: - Auth Header (exact copy of Electron design)
    private var authHeaderSection: some View {
        VStack(spacing: 12) {
            // Brand Container (exact copy of Electron)
            HStack(spacing: 12) {
                // Brand Icon (exact copy of Electron)
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 59/255, green: 130/255, blue: 246/255, opacity: 0.2),
                                    Color(red: 147/255, green: 51/255, blue: 234/255, opacity: 0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                        .frame(width: 32, height: 32)
                    
                    Image(systemName: "sparkles")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(Color(red: 59/255, green: 130/255, blue: 246/255, opacity: 0.8))
                }
                
                // Brand Title (exact copy of Electron)
                Text("PromiseKeeper")
                    .font(.system(size: 28, weight: .light, design: .default))
                    .foregroundColor(Color(red: 15/255, green: 23/255, blue: 42/255, opacity: 0.9))
                    .tracking(-0.02)
            }
            .opacity(1) // Remove animation for now to match Electron
            
            // Auth Subtitle (exact copy of Electron)
            Text(isShowingSignUp ? "Create your account to get started." : "Welcome back. Sign in to continue.")
                .font(.system(size: 15, weight: .regular))
                .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255, opacity: 0.8))
                .multilineTextAlignment(.center)
                .opacity(1) // Remove animation for now to match Electron
        }
    }
    
    // MARK: - Auth Form (exact copy of Electron styling)
    private var authFormSection: some View {
        VStack(spacing: 20) {
            // Full Name (only for signup - exact copy of Electron)
            if isShowingSignUp {
                VStack(alignment: .leading, spacing: 8) {
                    Text("FULL NAME")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255, opacity: 0.9))
                        .tracking(0.05)
                    
                    TextField("Enter your full name", text: $fullName)
                        .textFieldStyle(ModernAuthTextFieldStyle())
                }
            }
            
            // Email (exact copy of Electron)
            VStack(alignment: .leading, spacing: 8) {
                Text("EMAIL ADDRESS")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255, opacity: 0.9))
                    .tracking(0.05)
                
                TextField("Enter your email", text: $email)
                    .textFieldStyle(ModernAuthTextFieldStyle())
            }
            
            // Password (exact copy of Electron with toggle)
            VStack(alignment: .leading, spacing: 8) {
                Text("PASSWORD")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(Color(red: 51/255, green: 65/255, blue: 85/255, opacity: 0.9))
                    .tracking(0.05)
                
                ZStack(alignment: .trailing) {
                    Group {
                        if isPasswordVisible {
                            TextField("Enter your password", text: $password)
                        } else {
                            SecureField("Enter your password", text: $password)
                        }
                    }
                    .textFieldStyle(ModernAuthTextFieldStyle(hasTrailingButton: true))
                    
                    // Password Toggle Button (exact copy of Electron)
                    Button(action: { isPasswordVisible.toggle() }) {
                        Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                            .font(.system(size: 16))
                            .foregroundColor(Color(red: 100/255, green: 116/255, blue: 139/255, opacity: 0.7))
                    }
                    .padding(.trailing, 16)
                    .buttonStyle(.plain)
                }
            }
            
            // Submit Button (exact copy of Electron design)
            Button(action: handleSubmit) {
                HStack(spacing: 8) {
                    if supabaseManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text(isShowingSignUp ? "Create Account" : "Sign In")
                            .font(.system(size: 15, weight: .medium))
                            .tracking(0.02)
                        
                        Image(systemName: "arrow.right")
                            .font(.system(size: 16, weight: .medium))
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(Color.black.opacity(0.7))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
                .foregroundColor(.white)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                )
                .shadow(color: .black.opacity(0.12), radius: 6, x: 0, y: 4)
                .shadow(color: .white.opacity(0.08), radius: 0, x: 0, y: 1)
            }
            .disabled(isFormValid == false || supabaseManager.isLoading)
            .buttonStyle(ModernAuthButtonStyle())
        }
        .opacity(1) // Remove animation for now to match Electron
    }
    
    // MARK: - Auth Toggle (exact copy of Electron)
    private var authToggleSection: some View {
        Button(action: { isShowingSignUp.toggle() }) {
            HStack(spacing: 0) {
                Text(isShowingSignUp ? "Already have an account? " : "Don't have an account? ")
                    .font(.system(size: 14))
                    .foregroundColor(Color(red: 71/255, green: 85/255, blue: 105/255, opacity: 0.8))
                
                Text(isShowingSignUp ? "Sign in" : "Sign up")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(Color(red: 15/255, green: 23/255, blue: 42/255, opacity: 0.9))
            }
        }
        .buttonStyle(.plain)
        .opacity(1) // Remove animation for now to match Electron
    }
    
    // MARK: - Auth Message (exact copy of Electron styling)
    private func authMessage(text: String, type: MessageType) -> some View {
        Text(text)
            .font(.system(size: 14))
            .foregroundColor(type.textColor)
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(type.backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(type.borderColor, lineWidth: 1)
            )
            .cornerRadius(12)
    }
    
    // MARK: - Helper Properties
    private var isFormValid: Bool {
        let emailValid = !email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let passwordValid = !password.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        let nameValid = !isShowingSignUp || !fullName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        
        return emailValid && passwordValid && nameValid
    }
    
    // MARK: - Actions
    private func handleSubmit() {
        Task {
            if isShowingSignUp {
                await supabaseManager.signUp(email: email, password: password)
            } else {
                await supabaseManager.signIn(email: email, password: password)
            }
        }
    }
}

// MARK: - Message Type
enum MessageType {
    case error, success, loading
    
    var textColor: Color {
        switch self {
        case .error: return Color(red: 185/255, green: 28/255, blue: 28/255)
        case .success: return Color(red: 21/255, green: 128/255, blue: 61/255)
        case .loading: return Color(red: 29/255, green: 78/255, blue: 216/255)
        }
    }
    
    var backgroundColor: Color {
        switch self {
        case .error: return Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.1)
        case .success: return Color(red: 34/255, green: 197/255, blue: 94/255, opacity: 0.1)
        case .loading: return Color(red: 59/255, green: 130/255, blue: 246/255, opacity: 0.1)
        }
    }
    
    var borderColor: Color {
        switch self {
        case .error: return Color(red: 239/255, green: 68/255, blue: 68/255, opacity: 0.2)
        case .success: return Color(red: 34/255, green: 197/255, blue: 94/255, opacity: 0.2)
        case .loading: return Color(red: 59/255, green: 130/255, blue: 246/255, opacity: 0.2)
        }
    }
}

// Note: Styles are now defined in SharedStyles.swift

// MARK: - Liquid Background View (matching Electron app)
struct LiquidBackgroundView: View {
    @State private var animate = false
    
    var body: some View {
        ZStack {
            // Translucent base with frosted glass effect
            Rectangle()
                .fill(.ultraThinMaterial)
                .overlay(
                    LinearGradient(
                        colors: [
                            Color(red: 248/255, green: 250/255, blue: 255/255, opacity: 0.3),
                            Color(red: 240/255, green: 244/255, blue: 255/255, opacity: 0.2),
                            Color(red: 230/255, green: 230/255, blue: 250/255, opacity: 0.1)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            
            // Animated liquid blobs (simplified version of Electron's liquid background)
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 59/255, green: 130/255, blue: 246/255, opacity: 0.15),
                            Color(red: 59/255, green: 130/255, blue: 246/255, opacity: 0.05),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 200
                    )
                )
                .frame(width: 400, height: 400)
                .offset(x: animate ? 100 : -100, y: animate ? -50 : 50)
                .animation(.easeInOut(duration: 8).repeatForever(autoreverses: true), value: animate)
            
            Circle()
                .fill(
                    RadialGradient(
                        colors: [
                            Color(red: 147/255, green: 51/255, blue: 234/255, opacity: 0.12),
                            Color(red: 147/255, green: 51/255, blue: 234/255, opacity: 0.04),
                            Color.clear
                        ],
                        center: .center,
                        startRadius: 0,
                        endRadius: 300
                    )
                )
                .frame(width: 600, height: 600)
                .offset(x: animate ? -150 : 150, y: animate ? 100 : -100)
                .animation(.easeInOut(duration: 10).repeatForever(autoreverses: true), value: animate)
        }
        .onAppear {
            animate = true
        }
    }
}

// Note: VisualEffectView is already defined in ModernPromiseView.swift

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .frame(width: 400, height: 600)
            .environmentObject(SupabaseManager.shared)
    }
}