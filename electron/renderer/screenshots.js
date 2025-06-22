console.log('Promise Keeper screenshots.js loading...');

class ScreenshotManager {
    constructor(app) {
        this.app = app;
        this.autoScreenshotEnabled = false; // Default to off
        this.manualScreenshotRequested = false; // Flag for manual screenshots
    }

    async uploadScreenshot() {
        if (!this.app.currentUser) {
            window.PromiseKeeperUI.showUploadMessage('Please log in first', 'error');
            return;
        }

        // Show file picker
        const filePath = await window.electronAPI.files.showFilePicker();
        
        if (!filePath) {
            return; // User cancelled
        }

        window.PromiseKeeperUI.showUploadMessage('Uploading screenshot...', 'loading');

        try {
            // Read the file
            const response = await fetch(`file://${filePath}`);
            const blob = await response.blob();

            // Create FormData
            const formData = new FormData();
            formData.append('file', blob, 'screenshot.png');

            // Get the current user's access token
            const { data: { session } } = await window.PromiseKeeperConfig.supabaseClient.auth.getSession();
            
            if (!session || !session.access_token) {
                window.PromiseKeeperUI.showUploadMessage('No valid session found. Please log in again.', 'error');
                return;
            }

            // Call the API with authentication
            const apiResponse = await fetch(window.PromiseKeeperConfig.API_CONFIG.getUrl(window.PromiseKeeperConfig.API_CONFIG.endpoints.extractPromisesFileAuth), {
                method: 'POST',
                body: formData,
                headers: {
                    'Authorization': `Bearer ${session.access_token}`
                }
            });

            const result = await apiResponse.json();

            if (apiResponse.ok) {
                console.log('API Response:', result); // Debug log to see the structure
                
                // Display the extracted promises
                if (result.promises && result.promises.length > 0) {
                    // Extract text from promise objects for display
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

                    let message = `✅ Found and saved ${result.promises.length} promise${result.promises.length > 1 ? 's' : ''}:\n`;
                    promiseTexts.forEach((promise, index) => {
                        const shortPromise = promise.length > 60 ? promise.substring(0, 60) + '...' : promise;
                        message += `${index + 1}. ${shortPromise}\n`;
                    });
                    window.PromiseKeeperUI.showUploadMessage(message, 'success');

                    // Reload the promises list to show the newly saved promises
                    await this.app.promises.loadPromises();
                } else {
                    window.PromiseKeeperUI.showUploadMessage('No promises found in the image.', 'info');
                }
            } else {
                window.PromiseKeeperUI.showUploadMessage(`Error: ${result.detail || 'Unknown error'}`, 'error');
            }
        } catch (error) {
            console.error('Upload error:', error);
            window.PromiseKeeperUI.showUploadMessage(`Upload failed: ${error.message}`, 'error');
        }
    }

    async processScreenshotForPromises(data) {
        if (!this.app.currentUser) {
            console.log('Screenshot promise processing skipped: user not logged in');
            return;
        }

        // Allow processing if it's a manual screenshot or if auto-screenshot is enabled
        if (!this.autoScreenshotEnabled && !this.manualScreenshotRequested) {
            console.log('Screenshot promise processing skipped: auto-screenshot disabled');
            return;
        }

        // Reset manual screenshot flag
        if (this.manualScreenshotRequested) {
            this.manualScreenshotRequested = false;
            console.log('Processing manual screenshot...');
        }

        try {
            console.log('Processing screenshot for promises...', data.screenshotId);

            // Convert buffer to Blob
            const uint8Array = new Uint8Array(data.buffer);
            const blob = new Blob([uint8Array], { type: 'image/png' });

            // Create FormData
            const formData = new FormData();
            formData.append('file', blob, data.filename);
            // Add screenshot metadata
            formData.append('screenshot_id', data.screenshotId);
            formData.append('screenshot_timestamp', new Date(data.timestamp).toISOString());

            // Get the current user's access token
            const { data: { session } } = await window.PromiseKeeperConfig.supabaseClient.auth.getSession();
            
            if (!session || !session.access_token) {
                console.error('No valid session found for processing screenshot');
                return;
            }

            // Call the API using the existing configuration
            const apiResponse = await fetch(window.PromiseKeeperConfig.API_CONFIG.getUrl(window.PromiseKeeperConfig.API_CONFIG.endpoints.extractPromisesFileAuth), {
                method: 'POST',
                body: formData,
                headers: {
                    'Authorization': `Bearer ${session.access_token}`
                }
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
                
                // Since we're using the authenticated endpoint, promises are automatically saved to the database
                // Just reload the promises list to show the newly created ones
                await this.app.promises.loadPromises();

                // Show notification through main process
                if (window.electronAPI?.notifications) {
                    window.electronAPI.notifications.show(
                        'Promise Keeper',
                        `Found ${result.promises.length} promise${result.promises.length > 1 ? 's' : ''} in your screen and saved to database!`
                    );
                }

                // Show enhanced indicator (without individual promise creation)
                window.PromiseKeeperUI.showAutoPromiseCreatedIndicator(result.promises, data.screenshotId);
            } else if (!apiResponse.ok) {
                console.error('API error processing screenshot:', result);
            }
        } catch (error) {
            console.error('Error processing screenshot for promises:', error);
        }
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

    toggleAutoScreenshot(enabled) {
        this.autoScreenshotEnabled = enabled;
        console.log('Auto-screenshot:', enabled ? 'enabled' : 'disabled');
        
        // Store the preference in localStorage
        localStorage.setItem('autoScreenshotEnabled', enabled.toString());
        
        // Notify the main process about the change
        if (window.electronAPI?.screenshots?.setAutoScreenshotEnabled) {
            window.electronAPI.screenshots.setAutoScreenshotEnabled(enabled);
        }
    }

    async takeScreenshotNow() {
        if (!this.app.currentUser) {
            window.PromiseKeeperUI.showUploadMessage('Please log in first', 'error');
            return;
        }

        try {
            // Set flag to allow processing this screenshot even if auto-screenshot is disabled
            this.manualScreenshotRequested = true;
            
            // Request a screenshot from the main process - it will automatically call onProcessScreenshotForPromises
            if (window.electronAPI?.screenshots?.takeScreenshotNow) {
                console.log('Requesting manual screenshot...');
                await window.electronAPI.screenshots.takeScreenshotNow();
                window.PromiseKeeperUI.showUploadMessage('📸 Screenshot taken! Processing for promises...', 'info');
            } else {
                // Reset flag since we couldn't take screenshot
                this.manualScreenshotRequested = false;
                console.warn('Manual screenshot API not available');
                window.PromiseKeeperUI.showUploadMessage('Manual screenshot API not found - please restart the app', 'error');
            }
        } catch (error) {
            // Reset flag on error
            this.manualScreenshotRequested = false;
            console.error('Error requesting manual screenshot:', error);
            window.PromiseKeeperUI.showUploadMessage('Error requesting screenshot: ' + error.message, 'error');
        }
    }
}

// Make available globally
window.PromiseKeeperScreenshots = {
    ScreenshotManager
}; 