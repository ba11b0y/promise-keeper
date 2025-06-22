console.log('Promise Keeper debug.js loading...');

class DebugManager {
    constructor(app) {
        this.app = app;
    }

    toggleDebugPanel() {
        const panel = document.getElementById('debugPanel');
        panel.classList.toggle('open');
    }

    closeDebugPanel() {
        const panel = document.getElementById('debugPanel');
        panel.classList.remove('open');
    }

    async testBackendAuth() {
        if (!this.app.currentUser) {
            window.PromiseKeeperUI.showTestAuthMessage('Please log in first', 'error');
            return;
        }

        window.PromiseKeeperUI.showTestAuthMessage('Testing backend authentication...', 'loading');

        try {
            // Get the current user's access token
            const { data: { session } } = await window.PromiseKeeperConfig.supabaseClient.auth.getSession();
            
            if (!session || !session.access_token) {
                window.PromiseKeeperUI.showTestAuthMessage('No valid session found. Please log in again.', 'error');
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
                window.PromiseKeeperUI.showTestAuthMessage(
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
                            window.PromiseKeeperUI.showTestAuthMessage(
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
                window.PromiseKeeperUI.showTestAuthMessage(
                    `❌ Backend Auth Failed!\nStatus: ${response.status}\nError: ${errorText}`, 
                    'error'
                );
            }
        } catch (error) {
            console.error('Backend auth test error:', error);
            window.PromiseKeeperUI.showTestAuthMessage(
                `❌ Backend Connection Failed!\nError: ${error.message}\nMake sure backend is running on localhost:8000`, 
                'error'
            );
        }
    }
}

// Make available globally
window.PromiseKeeperDebug = {
    DebugManager
}; 