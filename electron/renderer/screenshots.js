console.log('Promise Keeper screenshots.js loading...');

class ScreenshotManager {
    constructor(app) {
        this.app = app;
        this.screenshotMode = 'enter'; // 'off', 'interval', 'enter'
        this.manualScreenshotRequested = false; // Flag for manual screenshots
        this.lastEnterScreenshot = 0; // Track last enter screenshot time
        this.enterScreenshotCooldown = 60000; // 1 minute cooldown for enter mode
        
        // Initialize action handlers
        this.actionHandlers = new window.PromiseKeeperActionHandlers(app);
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
                
                // Process potential actions using our types utility
                const processedResult = window.PromiseKeeperTypes.processApiResponse(result);
                
                const hasNewPromises = processedResult.has_new_promises;
                const hasResolvedPromises = processedResult.has_resolved_promises;
                
                if (hasNewPromises || hasResolvedPromises) {
                    // Execute MCP actions if found
                    if (hasNewPromises) {
                        await this.processMCPActions(processedResult.promises);
                    }
                    
                    // Build comprehensive message
                    let message = '';
                    
                    if (hasNewPromises) {
                        // Extract text from promise objects for display
                        const promiseTexts = processedResult.promises.map(promise => {
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

                        message += `✅ Found and saved ${processedResult.promises.length} new promise${processedResult.promises.length > 1 ? 's' : ''}:\n`;
                        promiseTexts.forEach((promise, index) => {
                            const shortPromise = promise.length > 60 ? promise.substring(0, 60) + '...' : promise;
                            message += `${index + 1}. ${shortPromise}\n`;
                        });
                    }
                    
                    if (hasResolvedPromises) {
                        if (hasNewPromises) message += '\n';
                        message += `🎉 Resolved ${processedResult.resolved_count} promise${processedResult.resolved_count > 1 ? 's' : ''}:\n`;
                        processedResult.resolved_promises.forEach((resolvedPromise, index) => {
                            const shortPromise = resolvedPromise.content.length > 60 ? resolvedPromise.content.substring(0, 60) + '...' : resolvedPromise.content;
                            message += `${index + 1}. ${shortPromise}\n`;
                        });
                    }
                    
                    window.PromiseKeeperUI.showUploadMessage(message, 'success');

                    // Reload the promises list to show updates
                    await this.app.promiseListing.loadPromises();
                } else {
                    window.PromiseKeeperUI.showUploadMessage('No new promises found or resolved in the image.', 'info');
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

        // Allow processing if it's a manual screenshot or if screenshot mode allows it
        if (this.screenshotMode === 'off' && !this.manualScreenshotRequested) {
            console.log('Screenshot promise processing skipped: screenshot mode is off');
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

            if (apiResponse.ok) {
                console.log('Screenshot processing result:', result);
                
                const hasNewPromises = result.promises && result.promises.length > 0;
                const hasResolvedPromises = result.resolved_promises && result.resolved_promises.length > 0;
                
                if (hasNewPromises) {
                    console.log('Found new promises in screenshot:', result.promises);
                    
                    // Process potential actions using our types utility
                    const processedResult = window.PromiseKeeperTypes.processApiResponse(result);
                    
                    console.log('Processed result:', processedResult);
                    console.log('Has new promises:', processedResult.has_new_promises);
                    console.log('Processed promises:', processedResult.promises);
                    
                    // Execute MCP actions if found
                    if (processedResult.has_new_promises) {
                        console.log('About to process MCP actions...');
                        await this.processMCPActions(processedResult.promises);
                    }
                    
                    // Save the screenshot permanently since it contains promises
                    const savedScreenshotPath = await window.electronAPI.screenshots.savePromiseScreenshot(
                        data.screenshotId, 
                        result.promises
                    );
                    
                    console.log('Promise screenshot saved to:', savedScreenshotPath);
                    
                    // Create promises in database and notify the UI components
                    const createdPromises = [];
                    for (const promise of result.promises) {
                        const createdPromise = await this.app.promises.createPromiseFromExtraction(
                            promise, 
                            data.screenshotId, 
                            data.timestamp
                        );
                        
                        if (createdPromise) {
                            createdPromises.push(createdPromise);
                        }
                    }
                    
                    // Promises will be displayed after loadPromises() is called below
                }
                
                if (hasResolvedPromises) {
                    console.log('Found resolved promises in screenshot:', result.resolved_promises);
                }
                
                if (hasNewPromises || hasResolvedPromises) {
                    // Reload the promises list to show updates (both new and resolved)
                    await this.app.promiseListing.loadPromises();

                    // Show notification through main process
                    if (window.electronAPI?.notifications) {
                        // Attempt to pass metadata from the first detected promise (if any)
                        let metadata = undefined;
                        if (result.promises && result.promises.length > 0) {
                            const firstPromise = result.promises[0];
                            metadata = {
                                action: firstPromise.action || '',
                                start_date: firstPromise.deadline ? String(firstPromise.deadline) : undefined,
                                to_whom: firstPromise.to_whom ? String(firstPromise.to_whom) : undefined
                            };
                        }
                        window.electronAPI.notifications.show('Promise Keeper', result.promises[0].content, metadata);
                    }

                    // Show enhanced indicator for new promises
                    if (hasNewPromises) {
                        window.PromiseKeeperUI.showAutoPromiseCreatedIndicator(result.promises, data.screenshotId);
                        
                        // Promises will be displayed after loadPromises() is called above
                    }
                }
            } else if (!apiResponse.ok) {
                console.error('API error processing screenshot:', result);
            }
        } catch (error) {
            console.error('Error processing screenshot for promises:', error);
        }
    }

    /**
     * Process and execute MCP actions found in promises
     * @param {Array} promises - Array of processed promises with potential actions
     */
    async processMCPActions(promises) {
        console.log('processMCPActions called with:', promises);
        
        if (!promises || !Array.isArray(promises)) {
            console.log('No promises provided or not an array');
            return;
        }

        let totalMCPActions = 0;
        let executedMCPActions = 0;

        for (const promise of promises) {
            console.log('Checking promise:', promise);
            console.log('Promise has_mcp_actions:', promise.has_mcp_actions);
            console.log('Promise mcp_actions:', promise.mcp_actions);
            
            if (promise.has_mcp_actions) {
                console.log(`Processing MCP actions for promise: "${promise.content}"`);
                
                for (const action of promise.mcp_actions) {
                    totalMCPActions++;
                    console.log('Found MCP action:', action);
                    
                    try {
                        // Execute the MCP action (this will trigger our console.log statements)
                        const success = await this.actionHandlers.executeActionWithConfirmation(action, true); // Skip confirmation for automated actions
                        
                        if (success) {
                            executedMCPActions++;
                        }
                    } catch (error) {
                        console.error('Error executing MCP action:', error);
                    }
                }
            }
        }

        if (totalMCPActions > 0) {
            console.log(`MCP Actions Summary: ${executedMCPActions}/${totalMCPActions} actions executed successfully`);
        } else {
            console.log('No MCP actions found to execute');
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
                
                .promise-item.resolved {
                    border-left: 4px solid #2196F3;
                    background: #f3f8ff;
                    opacity: 0.8;
                }
                
                .promise-item.resolved .promise-content {
                    text-decoration: line-through;
                    color: #666;
                }
                
                .screenshot-indicator {
                    font-size: 11px;
                    cursor: pointer;
                    padding: 3px 6px;
                    border-radius: 4px;
                    margin-left: 4px;
                    transition: all 0.2s;
                    display: inline-block;
                }
                
                .screenshot-indicator.initial {
                    color: #4CAF50;
                    background: rgba(76, 175, 80, 0.1);
                    border: 1px solid rgba(76, 175, 80, 0.2);
                }
                
                .screenshot-indicator.initial:hover {
                    background: rgba(76, 175, 80, 0.2);
                }
                
                .screenshot-indicator.resolved {
                    color: #2196F3;
                    background: rgba(33, 150, 243, 0.1);
                    border: 1px solid rgba(33, 150, 243, 0.2);
                }
                
                .screenshot-indicator.resolved:hover {
                    background: rgba(33, 150, 243, 0.2);
                }
                
                .screenshot-indicators {
                    display: flex;
                    align-items: center;
                    gap: 4px;
                }
                
                .resolution-info {
                    margin: 8px 0;
                    padding: 8px;
                    background: rgba(33, 150, 243, 0.05);
                    border-radius: 6px;
                    border-left: 3px solid #2196F3;
                }
                
                .resolved-status {
                    font-size: 12px;
                    font-weight: 600;
                    color: #2196F3;
                    margin-right: 8px;
                }
                
                .resolved-date {
                    font-size: 11px;
                    color: #666;
                    font-style: italic;
                }
                
                .resolved-reason {
                    font-size: 11px;
                    color: #555;
                    margin-top: 4px;
                    line-height: 1.3;
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

    async setScreenshotMode(mode) {
        this.screenshotMode = mode;
        console.log('Screenshot mode:', mode);
        
        // Store the preference in localStorage
        localStorage.setItem('screenshotMode', mode);
        
        // Notify the main process about the change
        if (window.electronAPI?.screenshots?.setScreenshotMode) {
            try {
                const result = await window.electronAPI.screenshots.setScreenshotMode(mode);
                console.log('Screenshot mode successfully set in main process:', mode, result);
                return result;
            } catch (error) {
                console.error('Failed to set screenshot mode:', error);
                throw error;
            }
        }
    }

    onEnterKeyPressed() {
        console.log('onEnterKeyPressed called, current mode:', this.screenshotMode);
        
        if (this.screenshotMode !== 'enter') {
            console.log('Screenshot mode is not "enter", skipping');
            return; // Only process enter key in enter mode
        }

        const now = Date.now();
        if (now - this.lastEnterScreenshot < this.enterScreenshotCooldown) {
            const remainingTime = Math.ceil((this.enterScreenshotCooldown - (now - this.lastEnterScreenshot)) / 1000);
            console.log(`Enter screenshot skipped: cooldown active (${remainingTime}s remaining)`);
            window.PromiseKeeperUI.showUploadMessage(`📸 Screenshot cooldown: ${remainingTime}s remaining`, 'info');
            return;
        }

        this.lastEnterScreenshot = now;
        console.log('Enter key pressed, taking screenshot...');
        window.PromiseKeeperUI.showUploadMessage('📸 Enter triggered screenshot...', 'info');
        this.takeScreenshotNow();
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