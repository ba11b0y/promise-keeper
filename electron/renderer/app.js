console.log('Promise Keeper app.js loading...');

// Supabase configuration
const SUPABASE_URL = "https://msucqyacicicjkakvurq.supabase.co";
const SUPABASE_ANON_KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Im1zdWNxeWFjaWNpY2prYWt2dXJxIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NTA1MjcyMDgsImV4cCI6MjA2NjEwMzIwOH0.dqV_-pUx8yJbyv2m1c-O5syFoKERKLEF0bDimtv0lro"

// Create Supabase client using the global supabase object
const supabaseClient = supabase.createClient(SUPABASE_URL, SUPABASE_ANON_KEY);

// Test connection
console.log('Supabase client initialized:', { 
    url: SUPABASE_URL, 
    hasKey: !!SUPABASE_ANON_KEY 
});

class PromiseKeeperApp {
    constructor() {
        this.currentUser = null;
        this.promises = [];
        this.initializeApp();
    }

    async initializeApp() {
        // Check if user is already logged in
        const { data: { user } } = await supabaseClient.auth.getUser();
        
        if (user) {
            this.currentUser = user;
            this.showPromiseSection();
            await this.loadPromises();
        } else {
            this.showLoginPage();
        }

        this.setupEventListeners();
        this.setupElectronEvents();
    }

    setupEventListeners() {
        // Auth form handlers
        document.getElementById('loginBtn').addEventListener('click', () => this.handleLogin());
        document.getElementById('registerBtn').addEventListener('click', () => this.handleRegister());
        document.getElementById('logoutBtn').addEventListener('click', () => this.handleLogout());

        // Navigation between login and register
        document.getElementById('showRegisterBtn').addEventListener('click', () => this.showRegisterPage());
        document.getElementById('showLoginBtn').addEventListener('click', () => this.showLoginPage());

        // Promise form handlers
        document.getElementById('addPromiseBtn').addEventListener('click', () => this.addPromise());
        document.getElementById('promiseInput').addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                this.addPromise();
            }
        });

        // Auth form enter key handling
        document.getElementById('loginPassword').addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                this.handleLogin();
            }
        });

        document.getElementById('confirmPassword').addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                this.handleRegister();
            }
        });
    }

    setupElectronEvents() {
        // Listen for focus input event from tray
        if (window.electronAPI) {
            window.electronAPI.onFocusInput(() => {
                const input = document.getElementById('promiseInput');
                if (input) {
                    input.focus();
                }
            });
        }
    }

    async handleLogin() {
        const email = document.getElementById('loginEmail').value;
        const password = document.getElementById('loginPassword').value;

        if (!email || !password) {
            this.showLoginMessage('Please enter both email and password', 'error');
            return;
        }

        this.showLoginMessage('Signing in...', 'loading');

        try {
            console.log('Attempting login with:', { email });
            
            const { data, error } = await supabaseClient.auth.signInWithPassword({
                email,
                password,
                options: {
                    skipBrowserRedirect: true
                }
            });

            console.log('Login response:', { data, error });

            if (error) {
                console.error('Login error:', error);
                this.showLoginMessage(error.message, 'error');
            } else if (data.user) {
                console.log('Login successful:', data.user);
                this.currentUser = data.user;
                this.showLoginMessage('Welcome back!', 'success');
                setTimeout(() => {
                    this.showPromiseSection();
                    this.loadPromises();
                }, 1000);
            } else {
                this.showLoginMessage('Login failed - no user returned', 'error');
            }
        } catch (err) {
            console.error('Login exception:', err);
            this.showLoginMessage('Login failed: ' + err.message, 'error');
        }
    }

    async handleRegister() {
        const email = document.getElementById('registerEmail').value;
        const password = document.getElementById('registerPassword').value;
        const confirmPassword = document.getElementById('confirmPassword').value;

        if (!email || !password || !confirmPassword) {
            this.showRegisterMessage('Please fill in all fields', 'error');
            return;
        }

        if (password !== confirmPassword) {
            this.showRegisterMessage('Passwords do not match', 'error');
            return;
        }

        if (password.length < 6) {
            this.showRegisterMessage('Password must be at least 6 characters', 'error');
            return;
        }

        this.showRegisterMessage('Creating account...', 'loading');

        try {
            console.log('Attempting registration with:', { email });
            
            // Sign up the user
            const { data: signupData, error: signupError } = await supabaseClient.auth.signUp({
                email,
                password,
                options: {
                    skipBrowserRedirect: true
                }
            });

            console.log('Signup response:', { signupData, signupError });

            if (signupError) {
                console.error('Signup error:', signupError);
                this.showRegisterMessage(signupError.message, 'error');
                return;
            }

            // If signup was successful, immediately sign in
            if (signupData.user) {
                this.showRegisterMessage('Account created! Signing you in...', 'success');
                
                // Wait a moment then sign in
                setTimeout(async () => {
                    const { data: loginData, error: loginError } = await supabaseClient.auth.signInWithPassword({
                        email,
                        password,
                        options: {
                            skipBrowserRedirect: true
                        }
                    });

                    if (loginError) {
                        console.error('Auto-login error:', loginError);
                        this.showRegisterMessage('Account created but auto-login failed. Please sign in manually.', 'error');
                        setTimeout(() => this.showLoginPage(), 2000);
                    } else if (loginData.user) {
                        console.log('Auto-login successful:', loginData.user);
                        this.currentUser = loginData.user;
                        this.showPromiseSection();
                        this.loadPromises();
                    }
                }, 1000);
            }
        } catch (err) {
            console.error('Registration exception:', err);
            this.showRegisterMessage('Registration failed: ' + err.message, 'error');
        }
    }

    async handleLogout() {
        const { error } = await supabaseClient.auth.signOut();
        
        if (error) {
            this.showLoginMessage(error.message, 'error');
        } else {
            this.currentUser = null;
            this.promises = [];
            this.showLoginPage();
        }
    }

    async addPromise() {
        const input = document.getElementById('promiseInput');
        const content = input.value.trim();

        if (!content) {
            return;
        }

        if (!this.currentUser) {
            this.showLoginMessage('Please log in first', 'error');
            return;
        }

        const { data, error } = await supabaseClient
            .from('promises')
            .insert([
                {
                    content: content,
                    owner_id: this.currentUser.id
                }
            ])
            .select()
            .single();

        if (error) {
            this.showLoginMessage('Failed to add promise: ' + error.message, 'error');
        } else {
            input.value = '';
            this.promises.unshift(data);
            this.renderPromises();

            // Show notification when promise is added
            if (window.electronAPI?.notifications) {
                window.electronAPI.notifications.show(
                    'Promise Added',
                    `New promise: ${content}`
                );
            }
        }
    }

    async deletePromise(id) {
        const { error } = await supabaseClient
            .from('promises')
            .delete()
            .eq('id', id);

        if (error) {
            this.showLoginMessage('Failed to delete promise: ' + error.message, 'error');
        } else {
            this.promises = this.promises.filter(p => p.id !== id);
            this.renderPromises();
        }
    }

    async loadPromises() {
        if (!this.currentUser) return;

        document.getElementById('promisesLoading').style.display = 'block';

        const { data, error } = await supabaseClient
            .from('promises')
            .select('*')
            .eq('owner_id', this.currentUser.id)
            .order('created_at', { ascending: false });

        document.getElementById('promisesLoading').style.display = 'none';

        if (error) {
            this.showLoginMessage('Failed to load promises: ' + error.message, 'error');
        } else {
            this.promises = data || [];
            this.renderPromises();
        }
    }

    renderPromises() {
        const container = document.getElementById('promisesList');
        const loading = document.getElementById('promisesLoading');
        
        if (this.promises.length === 0) {
            container.innerHTML = `
                <div class="empty-state">
                    <h3>No promises yet</h3>
                    <p>Add your first promise above to get started!</p>
                </div>
            `;
            return;
        }

        const promisesHTML = this.promises.map(promise => `
            <div class="promise-item">
                <div class="promise-content">${this.escapeHtml(promise.content)}</div>
                <div class="promise-meta">
                    <span class="promise-date">${this.formatDate(promise.created_at)}</span>
                    <button class="promise-delete" onclick="app.deletePromise(${promise.id})">Delete</button>
                </div>
            </div>
        `).join('');

        container.innerHTML = promisesHTML;
    }

    showLoginPage() {
        document.getElementById('loginSection').style.display = 'block';
        document.getElementById('registerSection').style.display = 'none';
        document.getElementById('promiseSection').style.display = 'none';
        document.getElementById('userInfo').style.display = 'none';
        
        // Clear form
        document.getElementById('loginEmail').value = '';
        document.getElementById('loginPassword').value = '';
        this.clearLoginMessages();
    }

    showRegisterPage() {
        document.getElementById('loginSection').style.display = 'none';
        document.getElementById('registerSection').style.display = 'block';
        document.getElementById('promiseSection').style.display = 'none';
        document.getElementById('userInfo').style.display = 'none';
        
        // Clear form
        document.getElementById('registerEmail').value = '';
        document.getElementById('registerPassword').value = '';
        document.getElementById('confirmPassword').value = '';
        this.clearRegisterMessages();
    }

    showPromiseSection() {
        document.getElementById('loginSection').style.display = 'none';
        document.getElementById('registerSection').style.display = 'none';
        document.getElementById('promiseSection').style.display = 'flex';
        document.getElementById('userInfo').style.display = 'block';
        
        if (this.currentUser) {
            document.getElementById('userEmail').textContent = this.currentUser.email;
        }
        
        this.clearLoginMessages();
        this.clearRegisterMessages();
    }

    showLoginMessage(message, type = 'info') {
        const messageDiv = document.getElementById('loginMessage');
        messageDiv.className = type;
        messageDiv.textContent = message;
        messageDiv.style.display = 'block';
    }

    showRegisterMessage(message, type = 'info') {
        const messageDiv = document.getElementById('registerMessage');
        messageDiv.className = type;
        messageDiv.textContent = message;
        messageDiv.style.display = 'block';
    }

    clearLoginMessages() {
        const messageDiv = document.getElementById('loginMessage');
        messageDiv.style.display = 'none';
        messageDiv.textContent = '';
    }

    clearRegisterMessages() {
        const messageDiv = document.getElementById('registerMessage');
        messageDiv.style.display = 'none';
        messageDiv.textContent = '';
    }

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
    }
}

// Initialize the app
const app = new PromiseKeeperApp();

// Make app available globally for button handlers
window.app = app; 