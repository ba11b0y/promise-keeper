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

// API Configuration
const API_CONFIG = {
    // Base URLs
    baseUrl: window.electronAPI?.env?.API_BASE_URL_OVERRIDE || "https://promise-keeper-api-red-sunset-2072.fly.dev",
    
    // API Endpoints
    endpoints: {
        extractPromisesFile: "/extract_promises_file"
    },
    
    // Build full URL
    getUrl(endpoint) {
        return this.baseUrl + endpoint;
    }
};

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

        // Debug panel handlers
        document.getElementById('debugToggle').addEventListener('click', () => this.toggleDebugPanel());
        document.getElementById('debugClose').addEventListener('click', () => this.closeDebugPanel());
        document.getElementById('uploadScreenshotBtn').addEventListener('click', () => this.uploadScreenshot());
        document.getElementById('testBackendAuthBtn').addEventListener('click', () => this.testBackendAuth());

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            // Ctrl+D or Cmd+D to toggle debug panel
            if ((e.ctrlKey || e.metaKey) && e.key === 'd') {
                e.preventDefault();
                this.toggleDebugPanel();
            }
            // Escape to close debug panel
            if (e.key === 'Escape') {
                this.closeDebugPanel();
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

            // Listen for screenshot processing requests from main process
            window.electronAPI.onProcessScreenshotForPromises((data) => {
                this.processScreenshotForPromises(data);
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

    async uploadScreenshot() {
        if (!this.currentUser) {
            this.showUploadMessage('Please log in first', 'error');
            return;
        }

        // Show file picker
        const filePath = await window.electronAPI.files.showFilePicker();
        
        if (!filePath) {
            return; // User cancelled
        }

        this.showUploadMessage('Uploading screenshot...', 'loading');

        try {
            // Read the file
            const response = await fetch(`file://${filePath}`);
            const blob = await response.blob();

            // Create FormData
            const formData = new FormData();
            formData.append('file', blob, 'screenshot.png');

            // Call the API
            const apiResponse = await fetch(API_CONFIG.getUrl(API_CONFIG.endpoints.extractPromisesFile), {
                method: 'POST',
                body: formData
            });

            const result = await apiResponse.json();

            if (apiResponse.ok) {
                console.log('API Response:', result); // Debug log to see the structure
                this.showUploadMessage('Screenshot processed successfully!', 'success');
                
                // Display the extracted promises
                if (result.promises && result.promises.length > 0) {
                    // Extract text from promise objects
                    const promiseTexts = result.promises.map(promise => {
                        // Handle different possible response formats
                        if (typeof promise === 'string') {
                            return promise;
                        } else if (promise.text) {
                            return promise.text;
                        } else if (promise.content) {
                            return promise.content;
                        } else if (promise.promise) {
                            return promise.promise;
                        } else {
                            // Fallback: convert object to string or use first property
                            return JSON.stringify(promise);
                        }
                    });

                    let message = 'Extracted promises:\n';
                    promiseTexts.forEach((promise, index) => {
                        message += `${index + 1}. ${promise}\n`;
                    });
                    this.showUploadMessage(message, 'success');

                    // Add the extracted promises to the input
                    const input = document.getElementById('promiseInput');
                    input.value = promiseTexts.join('\n');
                } else {
                    this.showUploadMessage('No promises found in the image.', 'info');
                }
            } else {
                this.showUploadMessage(`Error: ${result.detail || 'Unknown error'}`, 'error');
            }
        } catch (error) {
            console.error('Upload error:', error);
            this.showUploadMessage(`Upload failed: ${error.message}`, 'error');
        }
    }

    showUploadMessage(message, type = 'info') {
        const messageDiv = document.getElementById('uploadResult');
        messageDiv.className = type;
        messageDiv.textContent = message;
        messageDiv.style.display = 'block';
        
        // Auto-hide success and info messages after 5 seconds
        if (type === 'success' || type === 'info') {
            setTimeout(() => {
                messageDiv.style.display = 'none';
            }, 5000);
        }
    }

    async testBackendAuth() {
        if (!this.currentUser) {
            this.showTestAuthMessage('Please log in first', 'error');
            return;
        }

        this.showTestAuthMessage('Testing backend authentication...', 'loading');

        try {
            // Get the current user's access token
            const { data: { session } } = await supabaseClient.auth.getSession();
            
            if (!session || !session.access_token) {
                this.showTestAuthMessage('No valid session found. Please log in again.', 'error');
                return;
            }

            // Test the backend auth endpoint
            const backendUrl = 'http://localhost:8000'; // Local backend URL
            const response = await fetch(`${backendUrl}/auth/test`, {
                method: 'GET',
                headers: {
                    'Authorization': `Bearer ${session.access_token}`,
                    'Content-Type': 'application/json',
                }
            });

            if (response.ok) {
                const result = await response.json();
                this.showTestAuthMessage(
                    `✅ Backend Auth Success!\nMessage: ${result.message}\nUser ID: ${result.user_id}\nEmail: ${result.email}`, 
                    'success'
                );
                
                // Also test getting user info
                setTimeout(async () => {
                    try {
                        const userInfoResponse = await fetch(`${backendUrl}/auth/me`, {
                            method: 'GET',
                            headers: {
                                'Authorization': `Bearer ${session.access_token}`,
                                'Content-Type': 'application/json',
                            }
                        });
                        
                        if (userInfoResponse.ok) {
                            const userInfo = await userInfoResponse.json();
                            this.showTestAuthMessage(
                                `✅ Backend Auth Success!\n` +
                                `Message: ${result.message}\n` +
                                `User ID: ${result.user_id}\n` +
                                `Email: ${result.email}\n` +
                                `User Info: ${JSON.stringify(userInfo, null, 2)}`, 
                                'success'
                            );
                        }
                    } catch (error) {
                        console.error('User info test error:', error);
                    }
                }, 1000);
                
            } else {
                const errorText = await response.text();
                this.showTestAuthMessage(
                    `❌ Backend Auth Failed!\nStatus: ${response.status}\nError: ${errorText}`, 
                    'error'
                );
            }
        } catch (error) {
            console.error('Backend auth test error:', error);
            this.showTestAuthMessage(
                `❌ Backend Connection Failed!\nError: ${error.message}\nMake sure backend is running on localhost:8000`, 
                'error'
            );
        }
    }

    showTestAuthMessage(message, type = 'info') {
        const messageDiv = document.getElementById('testAuthResult');
        messageDiv.className = type;
        messageDiv.style.whiteSpace = 'pre-wrap'; // Preserve line breaks
        messageDiv.textContent = message;
        messageDiv.style.display = 'block';
        
        // Auto-hide success and info messages after 10 seconds
        if (type === 'success' || type === 'info') {
            setTimeout(() => {
                messageDiv.style.display = 'none';
            }, 10000);
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
        
        if (this.promises.length === 0) {
            container.innerHTML = '<div class="no-promises">No promises yet. Add your first promise above!</div>';
            return;
        }

        container.innerHTML = this.promises.map(promise => {
            const isFromScreenshot = promise.extracted_from_screenshot && promise.screenshot_id;
            const screenshotIndicator = isFromScreenshot ? 
                `<span class="screenshot-indicator" onclick="app.viewScreenshot('${promise.screenshot_id}')" title="Click to view source screenshot">
                    📸 From screenshot
                </span>` : '';
            
            return `
                <div class="promise-item ${isFromScreenshot ? 'from-screenshot' : ''}">
                    <div class="promise-content">${this.escapeHtml(promise.content)}</div>
                    <div class="promise-meta">
                        <span class="promise-date">${this.formatDate(promise.created_at)}</span>
                        ${screenshotIndicator}
                        <button class="delete-btn" onclick="app.deletePromise(${promise.id})">×</button>
                    </div>
                </div>
            `;
        }).join('');
    }

    async viewScreenshot(screenshotId) {
        try {
            const screenshotPath = await window.electronAPI.screenshots.getScreenshotPath(screenshotId);
            
            if (!screenshotPath) {
                console.error('Screenshot not found:', screenshotId);
                return;
            }

            this.showScreenshotModal(screenshotPath, screenshotId);
        } catch (error) {
            console.error('Error viewing screenshot:', error);
        }
    }

    showScreenshotModal(screenshotPath, screenshotId) {
        // Create modal overlay
        const modal = document.createElement('div');
        modal.className = 'screenshot-modal';
        modal.innerHTML = `
            <div class="screenshot-modal-overlay" onclick="this.parentElement.remove()">
                <div class="screenshot-modal-content" onclick="event.stopPropagation()">
                    <div class="screenshot-modal-header">
                        <h3>Promise Screenshot</h3>
                        <button class="close-btn" onclick="this.closest('.screenshot-modal').remove()">×</button>
                    </div>
                    <div class="screenshot-modal-body">
                        <img src="file://${screenshotPath}" alt="Promise Screenshot" style="max-width: 100%; max-height: 70vh; border-radius: 8px;" />
                        <p style="margin-top: 12px; color: #666; font-size: 12px;">
                            Screenshot ID: ${screenshotId}<br>
                            Path: ${screenshotPath}
                        </p>
                    </div>
                </div>
            </div>
        `;

        document.body.appendChild(modal);

        // Add modal styles
        if (!document.getElementById('screenshot-modal-styles')) {
            const styles = document.createElement('style');
            styles.id = 'screenshot-modal-styles';
            styles.textContent = `
                .screenshot-modal {
                    position: fixed;
                    top: 0;
                    left: 0;
                    width: 100%;
                    height: 100%;
                    z-index: 10000;
                }
                
                .screenshot-modal-overlay {
                    width: 100%;
                    height: 100%;
                    background: rgba(0, 0, 0, 0.8);
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    padding: 20px;
                }
                
                .screenshot-modal-content {
                    background: white;
                    border-radius: 12px;
                    max-width: 90vw;
                    max-height: 90vh;
                    overflow: auto;
                    box-shadow: 0 20px 60px rgba(0, 0, 0, 0.3);
                }
                
                .screenshot-modal-header {
                    display: flex;
                    justify-content: space-between;
                    align-items: center;
                    padding: 16px 20px;
                    border-bottom: 1px solid #eee;
                    background: #f8f9fa;
                    border-radius: 12px 12px 0 0;
                }
                
                .screenshot-modal-header h3 {
                    margin: 0;
                    color: #333;
                }
                
                .close-btn {
                    background: none;
                    border: none;
                    font-size: 24px;
                    cursor: pointer;
                    padding: 0;
                    width: 32px;
                    height: 32px;
                    display: flex;
                    align-items: center;
                    justify-content: center;
                    border-radius: 6px;
                    color: #666;
                }
                
                .close-btn:hover {
                    background: #e9ecef;
                    color: #333;
                }
                
                .screenshot-modal-body {
                    padding: 20px;
                    text-align: center;
                }
                
                .promise-item.from-screenshot {
                    border-left: 4px solid #4CAF50;
                    background: #f8fff8;
                }
                
                .screenshot-indicator {
                    color: #4CAF50;
                    font-size: 12px;
                    cursor: pointer;
                    padding: 2px 6px;
                    border-radius: 4px;
                    background: rgba(76, 175, 80, 0.1);
                    margin-left: 8px;
                }
                
                .screenshot-indicator:hover {
                    background: rgba(76, 175, 80, 0.2);
                }
                
                .promise-meta {
                    display: flex;
                    align-items: center;
                    justify-content: space-between;
                    margin-top: 8px;
                }
            `;
            document.head.appendChild(styles);
        }
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

    async processScreenshotForPromises(data) {
        if (!this.currentUser) {
            console.log('Screenshot promise processing skipped: user not logged in');
            return;
        }

        try {
            console.log('Processing screenshot for promises...', data.screenshotId);

            // Convert buffer to Blob
            const uint8Array = new Uint8Array(data.buffer);
            const blob = new Blob([uint8Array], { type: 'image/png' });

            // Create FormData
            const formData = new FormData();
            formData.append('file', blob, data.filename);

            // Call the API using the existing configuration
            const apiResponse = await fetch(API_CONFIG.getUrl(API_CONFIG.endpoints.extractPromisesFile), {
                method: 'POST',
                body: formData
            });

            const result = await apiResponse.json();

            if (apiResponse.ok && result.promises && result.promises.length > 0) {
                console.log('Found promises in screenshot:', result.promises);
                
                // Save the screenshot permanently since it contains promises
                const savedScreenshotPath = await window.electronAPI.screenshots.savePromiseScreenshot(
                    data.screenshotId, 
                    result.promises
                );
                
                console.log('Promise screenshot saved to:', savedScreenshotPath);
                
                // Create promises automatically with screenshot reference
                const createdPromises = [];
                for (const promise of result.promises) {
                    const createdPromise = await this.createPromiseFromExtraction(promise, data.screenshotId, data.timestamp);
                    if (createdPromise) {
                        createdPromises.push(createdPromise);
                    }
                }

                // Show notification through main process
                if (window.electronAPI?.notifications) {
                    window.electronAPI.notifications.show(
                        'Promise Keeper',
                        `Found ${result.promises.length} promise${result.promises.length > 1 ? 's' : ''} in your screen!`
                    );
                }

                // Show enhanced indicator with screenshot info
                this.showAutoPromiseCreatedIndicator(createdPromises, data.screenshotId);
            } else if (!apiResponse.ok) {
                console.error('API error processing screenshot:', result);
            }
        } catch (error) {
            console.error('Error processing screenshot for promises:', error);
        }
    }

    async createPromiseFromExtraction(promise, screenshotId, timestamp) {
        try {
            // Extract promise content
            let content = '';
            if (typeof promise === 'string') {
                content = promise;
            } else if (promise.content) {
                content = promise.content;
            } else if (promise.text) {
                content = promise.text;
            } else {
                content = JSON.stringify(promise);
            }

            if (!content.trim()) return null;

            // Create enhanced content with additional details if available
            if (promise.to_whom) {
                content += ` (to ${promise.to_whom})`;
            }
            if (promise.deadline) {
                content += ` (by ${promise.deadline})`;
            }

            const { data, error } = await supabaseClient
                .from('promises')
                .insert([
                    {
                        content: content.trim(),
                        owner_id: this.currentUser.id,
                        // Add screenshot metadata
                        screenshot_id: screenshotId,
                        screenshot_timestamp: new Date(timestamp).toISOString(),
                        extracted_from_screenshot: true,
                        extraction_data: JSON.stringify({
                            original_promise: promise,
                            to_whom: promise.to_whom,
                            deadline: promise.deadline
                        })
                    }
                ])
                .select()
                .single();

            if (error) {
                console.error('Failed to auto-create promise:', error);
                return null;
            } else {
                console.log('Auto-created promise successfully:', data);
                
                // Add to local promises list
                this.promises.unshift(data);
                this.renderPromises();

                return data;
            }
        } catch (error) {
            console.error('Error creating promise from extraction:', error);
            return null;
        }
    }

    showAutoPromiseCreatedIndicator(createdPromises, screenshotId) {
        if (!createdPromises || createdPromises.length === 0) return;

        // Create a temporary indicator showing the auto-created promises
        const indicator = document.createElement('div');
        indicator.className = 'auto-promise-indicator';
        
        const promisesList = createdPromises.map(p => 
            p.content.length > 50 ? p.content.substring(0, 50) + '...' : p.content
        ).join('<br>• ');

        indicator.innerHTML = `
            <div style="
                position: fixed;
                top: 20px;
                right: 20px;
                background: #4CAF50;
                color: white;
                padding: 12px 16px;
                border-radius: 6px;
                box-shadow: 0 4px 12px rgba(0,0,0,0.2);
                z-index: 1000;
                max-width: 320px;
                font-size: 14px;
                opacity: 0;
                transform: translateY(-20px);
                transition: all 0.3s ease;
            ">
                <strong>✅ ${createdPromises.length} Promise${createdPromises.length > 1 ? 's' : ''} Auto-Created</strong><br>
                <span style="font-size: 12px; opacity: 0.9;">• ${promisesList}</span><br>
                <span style="font-size: 10px; opacity: 0.7; margin-top: 4px; display: block;">
                    📸 From screenshot: ${screenshotId}
                </span>
            </div>
        `;
        
        document.body.appendChild(indicator);
        
        // Animate in
        setTimeout(() => {
            const indicatorEl = indicator.firstElementChild;
            indicatorEl.style.opacity = '1';
            indicatorEl.style.transform = 'translateY(0)';
        }, 100);
        
        // Remove after 6 seconds (longer since there's more info)
        setTimeout(() => {
            const indicatorEl = indicator.firstElementChild;
            indicatorEl.style.opacity = '0';
            indicatorEl.style.transform = 'translateY(-20px)';
            setTimeout(() => {
                if (indicator.parentNode) {
                    indicator.parentNode.removeChild(indicator);
                }
            }, 300);
        }, 6000);
    }

    toggleDebugPanel() {
        const panel = document.getElementById('debugPanel');
        panel.classList.toggle('open');
    }

    closeDebugPanel() {
        const panel = document.getElementById('debugPanel');
        panel.classList.remove('open');
    }
}

// Create and start the app
const app = new PromiseKeeperApp();

// Make app globally accessible for onclick handlers
window.app = app; 