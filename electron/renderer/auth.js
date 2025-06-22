console.log('Promise Keeper auth.js loading...');

class AuthManager {
    constructor(app) {
        this.app = app;
    }

    async handleLogin() {
        const email = document.getElementById('loginEmail').value;
        const password = document.getElementById('loginPassword').value;

        if (!email || !password) {
            window.PromiseKeeperUI.showLoginMessage('Please enter both email and password', 'error');
            return;
        }

        window.PromiseKeeperUI.showLoginMessage('Signing in...', 'loading');

        try {
            console.log('Attempting login with:', { email });
            
            const { data, error } = await window.PromiseKeeperConfig.supabaseClient.auth.signInWithPassword({
                email,
                password,
                options: {
                    skipBrowserRedirect: true
                }
            });

            console.log('Login response:', { data, error });

            if (error) {
                console.error('Login error:', error);
                window.PromiseKeeperUI.showLoginMessage(error.message, 'error');
            } else if (data.user) {
                console.log('Login successful:', data.user);
                this.app.currentUser = data.user;
                window.PromiseKeeperUI.showLoginMessage('Welcome back!', 'success');
                setTimeout(() => {
                    this.app.ui.showPromiseSection();
                    this.app.promises.loadPromises();
                }, 1000);
            } else {
                window.PromiseKeeperUI.showLoginMessage('Login failed - no user returned', 'error');
            }
        } catch (err) {
            console.error('Login exception:', err);
            window.PromiseKeeperUI.showLoginMessage('Login failed: ' + err.message, 'error');
        }
    }

    async handleRegister() {
        const email = document.getElementById('registerEmail').value;
        const password = document.getElementById('registerPassword').value;
        const confirmPassword = document.getElementById('confirmPassword').value;

        if (!email || !password || !confirmPassword) {
            window.PromiseKeeperUI.showRegisterMessage('Please fill in all fields', 'error');
            return;
        }

        if (password !== confirmPassword) {
            window.PromiseKeeperUI.showRegisterMessage('Passwords do not match', 'error');
            return;
        }

        if (password.length < 6) {
            window.PromiseKeeperUI.showRegisterMessage('Password must be at least 6 characters', 'error');
            return;
        }

        window.PromiseKeeperUI.showRegisterMessage('Creating account...', 'loading');

        try {
            console.log('Attempting registration with:', { email });
            
            // Sign up the user
            const { data: signupData, error: signupError } = await window.PromiseKeeperConfig.supabaseClient.auth.signUp({
                email,
                password,
                options: {
                    skipBrowserRedirect: true
                }
            });

            console.log('Signup response:', { signupData, signupError });

            if (signupError) {
                console.error('Signup error:', signupError);
                window.PromiseKeeperUI.showRegisterMessage(signupError.message, 'error');
                return;
            }

            // If signup was successful, immediately sign in
            if (signupData.user) {
                window.PromiseKeeperUI.showRegisterMessage('Account created! Signing you in...', 'success');
                
                // Wait a moment then sign in
                setTimeout(async () => {
                    const { data: loginData, error: loginError } = await window.PromiseKeeperConfig.supabaseClient.auth.signInWithPassword({
                        email,
                        password,
                        options: {
                            skipBrowserRedirect: true
                        }
                    });

                    if (loginError) {
                        console.error('Auto-login error:', loginError);
                        window.PromiseKeeperUI.showRegisterMessage('Account created but auto-login failed. Please sign in manually.', 'error');
                        setTimeout(() => this.app.ui.showLoginPage(), 2000);
                    } else if (loginData.user) {
                        console.log('Auto-login successful:', loginData.user);
                        this.app.currentUser = loginData.user;
                        this.app.ui.showPromiseSection();
                        this.app.promises.loadPromises();
                    }
                }, 1000);
            }
        } catch (err) {
            console.error('Registration exception:', err);
            window.PromiseKeeperUI.showRegisterMessage('Registration failed: ' + err.message, 'error');
        }
    }

    async handleLogout() {
        const { error } = await window.PromiseKeeperConfig.supabaseClient.auth.signOut();
        
        if (error) {
            window.PromiseKeeperUI.showLoginMessage(error.message, 'error');
        } else {
            this.app.currentUser = null;
            this.app.promises.promises = [];
            this.app.ui.showLoginPage();
        }
    }

    async checkExistingAuth() {
        // Check if user is already logged in
        const { data: { user } } = await window.PromiseKeeperConfig.supabaseClient.auth.getUser();
        
        if (user) {
            this.app.currentUser = user;
            this.app.ui.showPromiseSection();
            await this.app.promises.loadPromises();
            return true;
        } else {
            this.app.ui.showLoginPage();
            return false;
        }
    }
}

// Make available globally
window.PromiseKeeperAuth = {
    AuthManager
}; 