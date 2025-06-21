import SwiftUI

struct AuthView: View {
    @EnvironmentObject var supabaseManager: SupabaseManager
    @State private var isShowingSignUp = false
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 16) {
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.accentColor)
                
                Text("Welcome to Promise Keeper")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Text(isShowingSignUp ? "Create your account" : "Sign in to continue")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.top, 40)
            .padding(.bottom, 30)
            
            // Auth Form
            if isShowingSignUp {
                SignUpView(supabaseManager: supabaseManager)
            } else {
                SignInView(supabaseManager: supabaseManager)
            }
            
            Spacer()
            
            // Toggle between sign in and sign up
            HStack {
                Text(isShowingSignUp ? "Already have an account?" : "Don't have an account?")
                    .font(.footnote)
                    .foregroundColor(.secondary)
                
                Button(isShowingSignUp ? "Sign In" : "Sign Up") {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        isShowingSignUp.toggle()
                    }
                }
                .font(.footnote)
                .fontWeight(.medium)
            }
            .padding(.bottom, 30)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(NSColor.windowBackgroundColor))
    }
}

struct SignInView: View {
    @ObservedObject var supabaseManager: SupabaseManager
    @State private var email = ""
    @State private var password = ""
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(AuthTextFieldStyle())
                
                SecureField("Password", text: $password)
                    .textFieldStyle(AuthTextFieldStyle())
            }
            
            if let errorMessage = supabaseManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            Button(action: signIn) {
                HStack {
                    if supabaseManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Sign In")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(email.isEmpty || password.isEmpty || supabaseManager.isLoading)
        }
        .padding(.horizontal, 40)
    }
    
    private func signIn() {
        Task {
            await supabaseManager.signIn(email: email, password: password)
        }
    }
}

struct SignUpView: View {
    @ObservedObject var supabaseManager: SupabaseManager
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    
    var body: some View {
        VStack(spacing: 20) {
            VStack(spacing: 12) {
                TextField("Email", text: $email)
                    .textFieldStyle(AuthTextFieldStyle())
                
                SecureField("Password", text: $password)
                    .textFieldStyle(AuthTextFieldStyle())
                
                SecureField("Confirm Password", text: $confirmPassword)
                    .textFieldStyle(AuthTextFieldStyle())
            }
            
            if let errorMessage = supabaseManager.errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }
            
            if !password.isEmpty && !confirmPassword.isEmpty && password != confirmPassword {
                Text("Passwords don't match")
                    .font(.caption)
                    .foregroundColor(.red)
            }
            
            Button(action: signUp) {
                HStack {
                    if supabaseManager.isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text("Create Account")
                        .fontWeight(.medium)
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(email.isEmpty || password.isEmpty || confirmPassword.isEmpty || 
                     password != confirmPassword || supabaseManager.isLoading)
        }
        .padding(.horizontal, 40)
    }
    
    private func signUp() {
        Task {
            await supabaseManager.signUp(email: email, password: password)
        }
    }
}

// MARK: - Custom Styles

struct AuthTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(12)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color(NSColor.separatorColor), lineWidth: 1)
            )
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.vertical, 12)
            .padding(.horizontal, 20)
            .background(configuration.isPressed ? Color.accentColor.opacity(0.8) : Color.accentColor)
            .foregroundColor(.white)
            .cornerRadius(8)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}

struct AuthView_Previews: PreviewProvider {
    static var previews: some View {
        AuthView()
            .frame(width: 400, height: 500)
    }
} 