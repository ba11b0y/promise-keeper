/**
 * Example: Updated screenshots processing with proper type handling
 * 
 * This file shows how to integrate the types-utils.js into your existing screenshots.js
 * Replace the corresponding sections in your actual screenshots.js with these patterns
 */

// Example: Updated processScreenshotForPromises method
async function processScreenshotForPromises(data) {
    if (!this.app.currentUser) {
        console.log('Screenshot promise processing skipped: user not logged in');
        return;
    }

    try {
        console.log('Processing screenshot for promises...', data.screenshotId);

        // ... existing FormData setup code ...

        const apiResponse = await fetch(window.PromiseKeeperConfig.API_CONFIG.getUrl(window.PromiseKeeperConfig.API_CONFIG.endpoints.extractPromisesFileAuth), {
            method: 'POST',
            body: formData,
            headers: {
                'Authorization': `Bearer ${session.access_token}`
            }
        });

        const rawResult = await apiResponse.json();

        if (apiResponse.ok) {
            // ✨ NEW: Use the types utility to process the response
            const processedResult = window.PromiseKeeperTypes.processApiResponse(rawResult);
            
            console.log('Screenshot processing result:', processedResult);
            console.log('Raw API response:', processedResult.raw_response);
            
            if (processedResult.has_new_promises) {
                console.log('Found new promises in screenshot:');
                
                // ✨ NEW: Access parsed promises with potential actions
                processedResult.promises.forEach((promise, index) => {
                    console.log(`${index + 1}. ${promise.content}`);
                    
                    if (promise.has_actions) {
                        console.log(`   Potential actions (${promise.potential_actions.length}):`);
                        promise.potential_actions.forEach((action, actionIndex) => {
                            console.log(`   ${actionIndex + 1}. ${action.action}: ${action.description}`);
                        });
                    }
                });
                
                // Save screenshot with enhanced promise data
                const savedScreenshotPath = await window.electronAPI.screenshots.savePromiseScreenshot(
                    data.screenshotId, 
                    processedResult.promises // Now includes potential_actions
                );
                
                console.log('Promise screenshot saved to:', savedScreenshotPath);
            }
            
            if (processedResult.has_resolved_promises) {
                console.log('Found resolved promises in screenshot:', processedResult.resolved_promises);
            }
            
            if (processedResult.has_new_promises || processedResult.has_resolved_promises) {
                // Reload promises list
                await this.app.promises.loadPromises();

                // ✨ NEW: Create more detailed notification with actions info
                let notificationMessage = this.createNotificationMessage(processedResult);
                
                // Show notification
                if (window.electronAPI?.notifications) {
                    window.electronAPI.notifications.show(
                        'Promises Updated',
                        notificationMessage
                    );
                }
            }
        }
    } catch (error) {
        console.error('Screenshot processing error:', error);
    }
}

// ✨ NEW: Helper method to create detailed notification messages
function createNotificationMessage(processedResult) {
    let message = '';
    
    if (processedResult.has_new_promises && processedResult.has_resolved_promises) {
        message = `Found ${processedResult.promises.length} new promise${processedResult.promises.length > 1 ? 's' : ''} and resolved ${processedResult.resolved_count} promise${processedResult.resolved_count > 1 ? 's' : ''}!`;
    } else if (processedResult.has_new_promises) {
        const actionsCount = processedResult.promises.reduce((total, p) => total + p.potential_actions.length, 0);
        message = `Found ${processedResult.promises.length} promise${processedResult.promises.length > 1 ? 's' : ''} in your screen`;
        if (actionsCount > 0) {
            message += ` with ${actionsCount} suggested action${actionsCount > 1 ? 's' : ''}`;
        }
        message += '!';
    } else if (processedResult.has_resolved_promises) {
        message = `Resolved ${processedResult.resolved_count} promise${processedResult.resolved_count > 1 ? 's' : ''} from your screen!`;
    }
    
    return message;
}

// Example: Updated uploadScreenshot method
async function uploadScreenshot() {
    if (!this.app.currentUser) {
        window.PromiseKeeperUI.showUploadMessage('Please log in first', 'error');
        return;
    }

    const filePath = await window.electronAPI.files.showFilePicker();
    if (!filePath) return;

    window.PromiseKeeperUI.showUploadMessage('Uploading screenshot...', 'loading');

    try {
        // ... existing upload code ...
        
        const result = await apiResponse.json();

        if (apiResponse.ok) {
            // ✨ NEW: Use types utility to process response
            const processedResult = window.PromiseKeeperTypes.processApiResponse(result);
            
            console.log('Upload API Response:', processedResult);
            
            if (processedResult.has_new_promises || processedResult.has_resolved_promises) {
                // ✨ NEW: Create detailed message with actions info
                let message = this.createDetailedUploadMessage(processedResult);
                
                window.PromiseKeeperUI.showUploadMessage(message, 'success');
                await this.app.promises.loadPromises();
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

// ✨ NEW: Helper method for detailed upload messages
function createDetailedUploadMessage(processedResult) {
    let message = '';
    
    if (processedResult.has_new_promises) {
        message += `✅ Found and saved ${processedResult.promises.length} new promise${processedResult.promises.length > 1 ? 's' : ''}:\n`;
        
        processedResult.promises.forEach((promise, index) => {
            const shortPromise = promise.content.length > 60 ? promise.content.substring(0, 60) + '...' : promise.content;
            message += `${index + 1}. ${shortPromise}`;
            
            if (promise.has_actions) {
                message += ` (${promise.potential_actions.length} action${promise.potential_actions.length > 1 ? 's' : ''})`;
            }
            message += '\n';
        });
    }
    
    if (processedResult.has_resolved_promises) {
        if (processedResult.has_new_promises) message += '\n';
        message += `🎉 Resolved ${processedResult.resolved_count} promise${processedResult.resolved_count > 1 ? 's' : ''}:\n`;
        processedResult.resolved_promises.forEach((resolvedPromise, index) => {
            const shortPromise = resolvedPromise.content.length > 60 ? resolvedPromise.content.substring(0, 60) + '...' : resolvedPromise.content;
            message += `${index + 1}. ${shortPromise}\n`;
        });
    }
    
    return message;
} 