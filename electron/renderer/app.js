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
            this.showAuthSection();
        }

        this.setupEventListeners();
        this.setupElectronEvents();
    }

    setupEventListeners() {
        // Auth form handlers
        document.getElementById('loginBtn').addEventListener('click', () => this.handleLogin());
        document.getElementById('signupBtn').addEventListener('click', () => this.handleSignup());
        document.getElementById('logoutBtn').addEventListener('click', () => this.handleLogout());

        // Promise form handlers
        document.getElementById('addPromiseBtn').addEventListener('click', () => this.addPromise());
        document.getElementById('promiseInput').addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                this.addPromise();
            }
        });

        // Auth form enter key handling
        document.getElementById('password').addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                this.handleLogin();
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
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;

        if (!email || !password) {
            this.showMessage('Please enter both email and password', 'error');
            return;
        }

        this.showMessage('Signing in...', 'loading');

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
                this.showMessage(error.message, 'error');
            } else if (data.user) {
                console.log('Login successful:', data.user);
                this.currentUser = data.user;
                this.showMessage('Welcome back!', 'success');
                setTimeout(() => {
                    this.showPromiseSection();
                    this.loadPromises();
                }, 1000);
            } else {
                this.showMessage('Login failed - no user returned', 'error');
            }
        } catch (err) {
            console.error('Login exception:', err);
            this.showMessage('Login failed: ' + err.message, 'error');
        }
    }

    async handleSignup() {
        const email = document.getElementById('email').value;
        const password = document.getElementById('password').value;

        if (!email || !password) {
            this.showMessage('Please enter both email and password', 'error');
            return;
        }

        if (password.length < 6) {
            this.showMessage('Password must be at least 6 characters', 'error');
            return;
        }

        this.showMessage('Creating account...', 'loading');

        try {
            console.log('Attempting signup with:', { email });
            
            const { data, error } = await supabaseClient.auth.signUp({
                email,
                password,
                options: {
                    skipBrowserRedirect: true
                }
            });

            console.log('Signup response:', { data, error });

            if (error) {
                console.error('Signup error:', error);
                this.showMessage(error.message, 'error');
            } else {
                if (data.user && !data.user.email_confirmed_at) {
                    this.showMessage('Account created! Please check your email for verification, then sign in.', 'success');
                } else if (data.user) {
                    this.showMessage('Account created and verified! You can now sign in.', 'success');
                } else {
                    this.showMessage('Account creation completed.', 'success');
                }
            }
        } catch (err) {
            console.error('Signup exception:', err);
            this.showMessage('Signup failed: ' + err.message, 'error');
        }
    }

    async handleLogout() {
        const { error } = await supabaseClient.auth.signOut();
        
        if (error) {
            this.showMessage(error.message, 'error');
        } else {
            this.currentUser = null;
            this.promises = [];
            this.showAuthSection();
        }
    }

    async addPromise() {
        const input = document.getElementById('promiseInput');
        const content = input.value.trim();

        if (!content) {
            return;
        }

        if (!this.currentUser) {
            this.showMessage('Please log in first', 'error');
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
            this.showMessage('Failed to add promise: ' + error.message, 'error');
        } else {
            input.value = '';
            this.promises.unshift(data);
            this.renderPromises();
        }
    }

    async deletePromise(id) {
        const { error } = await supabaseClient
            .from('promises')
            .delete()
            .eq('id', id);

        if (error) {
            this.showMessage('Failed to delete promise: ' + error.message, 'error');
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
            this.showMessage('Failed to load promises: ' + error.message, 'error');
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

    showAuthSection() {
        document.getElementById('authSection').style.display = 'block';
        document.getElementById('promiseSection').style.display = 'none';
        document.getElementById('userInfo').style.display = 'none';
        
        // Clear form
        document.getElementById('email').value = '';
        document.getElementById('password').value = '';
        this.clearMessages();
    }

    showPromiseSection() {
        document.getElementById('authSection').style.display = 'none';
        document.getElementById('promiseSection').style.display = 'flex';
        document.getElementById('userInfo').style.display = 'block';
        
        if (this.currentUser) {
            document.getElementById('userEmail').textContent = this.currentUser.email;
        }
        
        this.clearMessages();
    }

    showMessage(message, type = 'info') {
        const messageDiv = document.getElementById('authMessage');
        messageDiv.className = type;
        messageDiv.textContent = message;
        messageDiv.style.display = 'block';
    }

    clearMessages() {
        const messageDiv = document.getElementById('authMessage');
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