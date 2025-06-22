console.log('Promise Keeper ui.js loading...');

class UIManager {
    constructor(app) {
        this.app = app;
    }

    showLoginPage() {
        document.getElementById('loginSection').style.display = 'block';
        document.getElementById('registerSection').style.display = 'none';
        document.getElementById('promiseSection').style.display = 'none';
        document.getElementById('userInfo').style.display = 'none';
        
        // Clear form
        document.getElementById('loginEmail').value = '';
        document.getElementById('loginPassword').value = '';
        clearLoginMessages();
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
        clearRegisterMessages();
    }

    showPromiseSection() {
        document.getElementById('loginSection').style.display = 'none';
        document.getElementById('registerSection').style.display = 'none';
        document.getElementById('promiseSection').style.display = 'flex';
        document.getElementById('userInfo').style.display = 'block';
        
        if (this.app.currentUser) {
            document.getElementById('userEmail').textContent = this.app.currentUser.email;
        }
        
        // Load screenshot preferences
        this.loadScreenshotPreferences();
        
        clearLoginMessages();
        clearRegisterMessages();
    }

    loadScreenshotPreferences() {
        const saved = localStorage.getItem('autoScreenshotEnabled');
        if (saved !== null) {
            this.app.screenshots.autoScreenshotEnabled = saved === 'true';
        }
        
        // Update the UI to reflect the current state
        const toggle = document.getElementById('autoScreenshotToggle');
        if (toggle) {
            toggle.checked = this.app.screenshots.autoScreenshotEnabled;
        }
    }
}

// Message display functions
function showLoginMessage(message, type = 'info') {
    const messageDiv = document.getElementById('loginMessage');
    messageDiv.className = type;
    messageDiv.textContent = message;
    messageDiv.style.display = 'block';
}

function showRegisterMessage(message, type = 'info') {
    const messageDiv = document.getElementById('registerMessage');
    messageDiv.className = type;
    messageDiv.textContent = message;
    messageDiv.style.display = 'block';
}

function clearLoginMessages() {
    const messageDiv = document.getElementById('loginMessage');
    messageDiv.style.display = 'none';
    messageDiv.textContent = '';
}

function clearRegisterMessages() {
    const messageDiv = document.getElementById('registerMessage');
    messageDiv.style.display = 'none';
    messageDiv.textContent = '';
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