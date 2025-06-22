console.log('Promise Keeper app.js loading...');

class PromiseKeeperApp {
    constructor() {
        this.currentUser = null;
        
        // Initialize modular managers
        this.auth = new window.PromiseKeeperAuth.AuthManager(this);
        this.promises = new window.PromiseKeeperPromises.PromiseManager(this);
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
        // Auth form handlers
        document.getElementById('loginBtn').addEventListener('click', () => this.auth.handleLogin());
        document.getElementById('registerBtn').addEventListener('click', () => this.auth.handleRegister());
        document.getElementById('logoutBtn').addEventListener('click', () => this.auth.handleLogout());

        // Navigation between login and register
        document.getElementById('showRegisterBtn').addEventListener('click', () => this.ui.showRegisterPage());
        document.getElementById('showLoginBtn').addEventListener('click', () => this.ui.showLoginPage());

        // Promise form handlers
        document.getElementById('addPromiseBtn').addEventListener('click', () => this.promises.addPromise());
        document.getElementById('promiseInput').addEventListener('keydown', (e) => {
            if (e.key === 'Enter' && !e.shiftKey) {
                e.preventDefault();
                this.promises.addPromise();
            }
        });

        // Auth form enter key handling
        document.getElementById('loginPassword').addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                this.auth.handleLogin();
            }
        });

        document.getElementById('confirmPassword').addEventListener('keydown', (e) => {
            if (e.key === 'Enter') {
                this.auth.handleRegister();
            }
        });

        // Screenshot control handlers
        document.getElementById('autoScreenshotToggle').addEventListener('change', (e) => this.screenshots.toggleAutoScreenshot(e.target.checked));
        document.getElementById('takeScreenshotBtn').addEventListener('click', () => this.screenshots.takeScreenshotNow());

        // Debug panel handlers
        document.getElementById('debugToggle').addEventListener('click', () => this.debug.toggleDebugPanel());
        document.getElementById('debugClose').addEventListener('click', () => this.debug.closeDebugPanel());
        document.getElementById('uploadScreenshotBtn').addEventListener('click', () => this.screenshots.uploadScreenshot());
        document.getElementById('testBackendAuthBtn').addEventListener('click', () => this.debug.testBackendAuth());

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
                this.screenshots.processScreenshotForPromises(data);
            });
        }
    }
}

// Create and start the app
const app = new PromiseKeeperApp();

// Make app globally accessible for onclick handlers
window.app = app; 