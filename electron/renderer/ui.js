console.log('Promise Keeper ui.js loading...');

class UIManager {
    constructor(app) {
        this.app = app;
        this.isSignUp = false;
        this.liquidBg = null;
        this.initializeModernAuth();
    }

    initializeModernAuth() {
        // Initialize liquid background
        setTimeout(() => {
            this.liquidBg = new window.LiquidBackground('liquidBgContainer');
        }, 100);

        // Set up event listeners for modern auth
        this.setupAuthEventListeners();
    }

    setupAuthEventListeners() {
        // Password toggle
        const passwordToggle = document.getElementById('passwordToggle');
        const passwordInput = document.getElementById('authPassword');
        const eyeIcon = document.querySelector('.eye-icon');
        const eyeOffIcon = document.querySelector('.eye-off-icon');

        if (passwordToggle && passwordInput) {
            passwordToggle.addEventListener('click', () => {
                const isPassword = passwordInput.type === 'password';
                passwordInput.type = isPassword ? 'text' : 'password';
                eyeIcon.style.display = isPassword ? 'none' : 'block';
                eyeOffIcon.style.display = isPassword ? 'block' : 'none';
            });
        }

        // Form toggle
        const authToggle = document.getElementById('authToggle');
        if (authToggle) {
            authToggle.addEventListener('click', () => {
                this.toggleAuthMode();
            });
        }

        // Form submission
        const authForm = document.getElementById('authForm');
        if (authForm) {
            authForm.addEventListener('submit', (e) => {
                e.preventDefault();
                this.handleModernAuth();
            });
        }
    }

    toggleAuthMode() {
        this.isSignUp = !this.isSignUp;
        this.updateAuthForm();
        
        // Clear form and messages
        this.clearAuthForm();
        clearLoginMessages();
        clearRegisterMessages();
    }

    updateAuthForm() {
        const nameGroup = document.getElementById('nameGroup');
        const authSubtitle = document.getElementById('authSubtitle');
        const buttonText = document.getElementById('buttonText');
        const toggleText = document.getElementById('toggleText');
        const toggleAction = document.getElementById('toggleAction');

        if (this.isSignUp) {
            nameGroup.style.display = 'block';
            authSubtitle.textContent = 'Create your account to start keeping promises';
            buttonText.textContent = 'Create Account';
            toggleText.textContent = 'Already have an account? ';
            toggleAction.textContent = 'Sign in';
        } else {
            nameGroup.style.display = 'none';
            authSubtitle.textContent = 'Welcome back. Sign in to continue.';
            buttonText.textContent = 'Sign In';
            toggleText.textContent = "Don't have an account? ";
            toggleAction.textContent = 'Sign up';
        }
    }

    clearAuthForm() {
        document.getElementById('authEmail').value = '';
        document.getElementById('authPassword').value = '';
        document.getElementById('fullName').value = '';
    }

    async handleModernAuth() {
        const email = document.getElementById('authEmail').value;
        const password = document.getElementById('authPassword').value;
        const fullName = document.getElementById('fullName').value;
        const authButton = document.getElementById('authButton');
        const buttonText = document.getElementById('buttonText');
        const buttonIcon = document.querySelector('.button-icon');
        const loadingSpinner = document.getElementById('loadingSpinner');

        // Show loading state
        authButton.disabled = true;
        buttonText.style.opacity = '0';
        buttonIcon.style.opacity = '0';
        loadingSpinner.style.display = 'block';

        try {
            if (this.isSignUp) {
                await this.app.auth.handleModernRegister(email, password, fullName);
            } else {
                await this.app.auth.handleModernLogin(email, password);
            }
        } catch (error) {
            console.error('Auth error:', error);
        } finally {
            // Reset button state
            authButton.disabled = false;
            buttonText.style.opacity = '1';
            buttonIcon.style.opacity = '1';
            loadingSpinner.style.display = 'none';
        }
    }

    showLoginPage() {
        document.body.classList.add('modern-auth-active');
        document.getElementById('authSection').style.display = 'flex';
        document.getElementById('userInfo').style.display = 'none';
        
        // Hide the promise listing component
        if (this.app.promiseListing) {
            this.app.promiseListing.hide();
        }
        
        // Ensure we're in login mode
        this.isSignUp = false;
        this.updateAuthForm();
        this.clearAuthForm();
        clearLoginMessages();
        clearRegisterMessages();
    }

    showRegisterPage() {
        document.body.classList.add('modern-auth-active');
        document.getElementById('authSection').style.display = 'flex';
        document.getElementById('userInfo').style.display = 'none';
        
        // Hide the promise listing component
        if (this.app.promiseListing) {
            this.app.promiseListing.hide();
        }
        
        // Ensure we're in register mode
        this.isSignUp = true;
        this.toggleAuthMode();
        this.clearAuthForm();
        clearLoginMessages();
        clearRegisterMessages();
    }

    showPromiseSection() {
        document.body.classList.remove('modern-auth-active');
        document.getElementById('authSection').style.display = 'none';
        document.getElementById('userInfo').style.display = 'block';
        
        if (this.app.currentUser) {
            document.getElementById('userEmail').textContent = this.app.currentUser.email;
        }
        
        // Load screenshot preferences
        this.loadScreenshotPreferences();
        
        clearLoginMessages();
        clearRegisterMessages();

        // Clean up liquid background
        if (this.liquidBg) {
            this.liquidBg.destroy();
            this.liquidBg = null;
        }
        
        // Show the new Promise Listing component
        if (this.app.promiseListing) {
            this.app.promiseListing.show(this.app.currentUser);
        }
    }

    loadScreenshotPreferences() {
        const saved = localStorage.getItem('screenshotMode');
        if (saved !== null) {
            this.app.screenshots.screenshotMode = saved;
        } else {
            // Default to 'enter' mode for new users
            this.app.screenshots.screenshotMode = 'enter';
        }
        
        // Update the UI to reflect the current state
        const select = document.getElementById('screenshotModeSelect');
        if (select) {
            select.value = this.app.screenshots.screenshotMode;
        }
        
        // Notify main process of the current mode with retry logic
        this.setInitialScreenshotMode();
    }
    
    setInitialScreenshotMode() {
        // Set the screenshot mode - IPC handlers are now ready since they're set up before window creation
        this.app.screenshots.setScreenshotMode(this.app.screenshots.screenshotMode)
            .then(() => {
                console.log('Successfully set initial screenshot mode');
            })
            .catch(error => {
                console.error('Failed to set initial screenshot mode:', error);
                // Don't throw - not critical for app startup
            });
    }
}

// Message display functions
function showLoginMessage(message, type = 'info') {
    const messageDiv = document.getElementById('loginMessage');
    messageDiv.className = `auth-message ${type}`;
    messageDiv.textContent = message;
    messageDiv.style.display = 'block';
    
    // Auto-hide after delay for success/info messages
    if (type === 'success' || type === 'info') {
        setTimeout(() => {
            if (messageDiv.textContent === message) {
                clearLoginMessages();
            }
        }, 3000);
    }
}

function showRegisterMessage(message, type = 'info') {
    const messageDiv = document.getElementById('registerMessage');
    messageDiv.className = `auth-message ${type}`;
    messageDiv.textContent = message;
    messageDiv.style.display = 'block';
    
    // Auto-hide after delay for success/info messages
    if (type === 'success' || type === 'info') {
        setTimeout(() => {
            if (messageDiv.textContent === message) {
                clearRegisterMessages();
            }
        }, 3000);
    }
}

function clearLoginMessages() {
    const messageDiv = document.getElementById('loginMessage');
    messageDiv.style.display = 'none';
    messageDiv.textContent = '';
    messageDiv.className = 'auth-message';
}

function clearRegisterMessages() {
    const messageDiv = document.getElementById('registerMessage');
    messageDiv.style.display = 'none';
    messageDiv.textContent = '';
    messageDiv.className = 'auth-message';
}

function showUploadMessage(message, type = 'info') {
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

function showTestAuthMessage(message, type = 'info') {
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

function showAutoPromiseCreatedIndicator(promises, screenshotId) {
    if (!promises || promises.length === 0) return;

    // Create a temporary indicator showing the auto-created promises
    const indicator = document.createElement('div');
    indicator.className = 'auto-promise-indicator';
    
    const promisesList = promises.map(p => {
        const content = p.content || p.text || (typeof p === 'string' ? p : JSON.stringify(p));
        return content.length > 50 ? content.substring(0, 50) + '...' : content;
    }).join('<br>• ');

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
            <strong>✅ ${promises.length} Promise${promises.length > 1 ? 's' : ''} Auto-Created & Saved</strong><br>
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

// Make available globally
window.PromiseKeeperUI = {
    UIManager,
    showLoginMessage,
    showRegisterMessage,
    clearLoginMessages,
    clearRegisterMessages,
    showUploadMessage,
    showTestAuthMessage,
    showAutoPromiseCreatedIndicator
}; 