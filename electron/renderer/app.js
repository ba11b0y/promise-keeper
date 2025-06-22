console.log('Promise Keeper app.js loading...');

class PromiseKeeperApp {
    constructor() {
        this.currentUser = null;
        
        // Initialize modular managers
        this.auth = new window.PromiseKeeperAuth.AuthManager(this);
        this.promises = new window.PromiseKeeperPromises.PromiseManager(this);
        this.promiseListing = new window.PromiseKeeperListing.PromiseListingPage(this);
        this.screenshots = new window.PromiseKeeperScreenshots.ScreenshotManager(this);
        this.ui = new window.PromiseKeeperUI.UIManager(this);
        this.debug = new window.PromiseKeeperDebug.DebugManager(this);
        
        this.initializeApp();
    }

    async initializeApp() {
        await this.auth.checkExistingAuth();
        this.setupEventListeners();
        this.setupElectronEvents();
    }

    setupEventListeners() {
        // Auth form handlers (only for old auth elements that still exist)
        const loginBtn = document.getElementById('loginBtn');
        const registerBtn = document.getElementById('registerBtn');
        const logoutBtn = document.getElementById('logoutBtn');
        const showRegisterBtn = document.getElementById('showRegisterBtn');
        const showLoginBtn = document.getElementById('showLoginBtn');
        
        if (loginBtn) loginBtn.addEventListener('click', () => this.auth.handleLogin());
        if (registerBtn) registerBtn.addEventListener('click', () => this.auth.handleRegister());
        if (logoutBtn) logoutBtn.addEventListener('click', () => this.auth.handleLogout());
        if (showRegisterBtn) showRegisterBtn.addEventListener('click', () => this.ui.showRegisterPage());
        if (showLoginBtn) showLoginBtn.addEventListener('click', () => this.ui.showLoginPage());

        // Legacy promise form handlers (if old elements exist)
        const oldAddPromiseBtn = document.getElementById('addPromiseBtn');
        const oldPromiseInput = document.getElementById('promiseInput');
        
        if (oldAddPromiseBtn) oldAddPromiseBtn.addEventListener('click', () => this.promises.addPromise());
        if (oldPromiseInput) {
            oldPromiseInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    this.promises.addPromise();
                    // Also trigger screenshot if in enter mode
                    this.screenshots.onEnterKeyPressed();
                }
            });
        }

        // Auth form enter key handling
        const loginPassword = document.getElementById('loginPassword');
        const confirmPassword = document.getElementById('confirmPassword');
        
        if (loginPassword) {
            loginPassword.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') {
                    this.auth.handleLogin();
                    // Also trigger screenshot if in enter mode
                    this.screenshots.onEnterKeyPressed();
                }
            });
        }

        if (confirmPassword) {
            confirmPassword.addEventListener('keydown', (e) => {
                if (e.key === 'Enter') {
                    this.auth.handleRegister();
                    // Also trigger screenshot if in enter mode
                    this.screenshots.onEnterKeyPressed();
                }
            });
        }

        // Legacy screenshot control handlers (if old elements exist)
        const oldScreenshotModeSelect = document.getElementById('screenshotModeSelect');
        const oldTakeScreenshotBtn = document.getElementById('takeScreenshotBtn');
        
        if (oldScreenshotModeSelect) oldScreenshotModeSelect.addEventListener('change', async (e) => await this.screenshots.setScreenshotMode(e.target.value));
        if (oldTakeScreenshotBtn) oldTakeScreenshotBtn.addEventListener('click', () => this.screenshots.takeScreenshotNow());

        // Debug panel handlers
        const debugToggle = document.getElementById('debugToggle');
        const debugClose = document.getElementById('debugClose');
        const uploadScreenshotBtn = document.getElementById('uploadScreenshotBtn');
        const testBackendAuthBtn = document.getElementById('testBackendAuthBtn');
        
        if (debugToggle) debugToggle.addEventListener('click', () => this.debug.toggleDebugPanel());
        if (debugClose) debugClose.addEventListener('click', () => this.debug.closeDebugPanel());
        if (uploadScreenshotBtn) uploadScreenshotBtn.addEventListener('click', () => this.screenshots.uploadScreenshot());
        if (testBackendAuthBtn) testBackendAuthBtn.addEventListener('click', () => this.debug.testBackendAuth());

        // Keyboard shortcuts
        document.addEventListener('keydown', (e) => {
            // Ctrl+D or Cmd+D to toggle debug panel
            if ((e.ctrlKey || e.metaKey) && e.key === 'd') {
                e.preventDefault();
                this.debug.toggleDebugPanel();
            }
            // Escape to close debug panel
            if (e.key === 'Escape') {
                this.debug.closeDebugPanel();
                // Also close settings modal if open
                if (this.promiseListing && this.promiseListing.isSettingsOpen) {
                    this.promiseListing.closeSettings();
                }
            }
            // Global Enter key tracking for screenshot mode (only if not handled by specific elements)
            if (e.key === 'Enter' && !e.target.matches('input, textarea, button')) {
                this.screenshots.onEnterKeyPressed();
            }
        }, true); // Use capture phase to catch events before they're handled by specific elements
    }

    setupElectronEvents() {
        // Listen for focus input event from tray
        if (window.electronAPI) {
            window.electronAPI.onFocusInput(() => {
                // Try the new promise listing input first, then fall back to old input
                const newInput = document.getElementById('promiseInput');
                const oldInput = document.getElementById('promiseInput');
                
                if (newInput) {
                    newInput.focus();
                    // Also show the add promise form if it's hidden
                    if (this.promiseListing) {
                        this.promiseListing.showAddPromiseForm();
                    }
                } else if (oldInput) {
                    oldInput.focus();
                }
            });

            // Listen for screenshot processing requests from main process
            window.electronAPI.onProcessScreenshotForPromises((data) => {
                this.screenshots.processScreenshotForPromises(data);
            });
        }
    }
}

// Create and start the app
const app = new PromiseKeeperApp();

// Make app globally accessible for onclick handlers
window.app = app; 