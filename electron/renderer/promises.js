console.log('Promise Keeper promises.js loading...');

class PromiseManager {
    constructor(app) {
        this.app = app;
        this.promises = [];
    }

    async addPromise() {
        const input = document.getElementById('promiseInput');
        const content = input.value.trim();

        if (!content) {
            return;
        }

        if (!this.app.currentUser) {
            window.PromiseKeeperUI.showLoginMessage('Please log in first', 'error');
            return;
        }

        const { data, error } = await window.PromiseKeeperConfig.supabaseClient
            .from('promises')
            .insert([
                {
                    content: content,
                    owner_id: this.app.currentUser.id
                }
            ])
            .select()
            .single();

        if (error) {
            window.PromiseKeeperUI.showLoginMessage('Failed to add promise: ' + error.message, 'error');
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

    async deletePromise(id) {
        const { error } = await window.PromiseKeeperConfig.supabaseClient
            .from('promises')
            .delete()
            .eq('id', id);

        if (error) {
            window.PromiseKeeperUI.showLoginMessage('Failed to delete promise: ' + error.message, 'error');
        } else {
            this.promises = this.promises.filter(p => p.id !== id);
            this.renderPromises();
        }
    }

    async loadPromises() {
        if (!this.app.currentUser) return;

        const loadingElement = document.getElementById('promisesLoading');
        if (loadingElement) {
            loadingElement.style.display = 'block';
        }

        const { data, error } = await window.PromiseKeeperConfig.supabaseClient
            .from('promises')
            .select('*')
            .eq('owner_id', this.app.currentUser.id)
            .order('created_at', { ascending: false });

        if (loadingElement) {
            loadingElement.style.display = 'none';
        }

        if (error) {
            window.PromiseKeeperUI.showLoginMessage('Failed to load promises: ' + error.message, 'error');
        } else {
            this.promises = data || [];
            this.renderPromises();
        }
    }

    renderPromises() {
        const container = document.getElementById('promisesList');
        
        if (!container) {
            // Container doesn't exist yet (user might not be on promises page)
            return;
        }
        
        if (this.promises.length === 0) {
            container.innerHTML = '<div class="no-promises">No promises yet. Add your first promise above!</div>';
            return;
        }

        container.innerHTML = this.promises.map(promise => {
            const isFromScreenshot = promise.extracted_from_screenshot && promise.screenshot_id;
            const isResolved = promise.resolved;
            
            // Create screenshot indicators
            const initialScreenshotIndicator = isFromScreenshot ? 
                `<span class="screenshot-indicator initial" onclick="app.screenshots.viewScreenshot('${promise.screenshot_id}')" title="Click to view source screenshot">
                    📸 Initial
                </span>` : '';
            
            const resolvedScreenshotIndicator = isResolved && promise.resolved_screenshot_id ? 
                `<span class="screenshot-indicator resolved" onclick="app.screenshots.viewScreenshot('${promise.resolved_screenshot_id}')" title="Click to view resolution screenshot">
                    ✅ Resolved
                </span>` : '';
            
            // Create resolution info
            const resolutionInfo = isResolved ? 
                `<div class="resolution-info">
                    <span class="resolved-status">✅ Resolved</span>
                    <span class="resolved-date">${this.formatDate(promise.resolved_screenshot_time || promise.updated_at)}</span>
                    ${promise.resolved_reason ? 
                        `<div class="resolved-reason" title="${this.escapeHtml(promise.resolved_reason)}">
                            ${this.escapeHtml(promise.resolved_reason.length > 80 ? promise.resolved_reason.substring(0, 80) + '...' : promise.resolved_reason)}
                        </div>` : ''
                    }
                </div>` : '';
            
            const promiseItemClasses = [
                'promise-item',
                isFromScreenshot ? 'from-screenshot' : '',
                isResolved ? 'resolved' : ''
            ].filter(c => c).join(' ');
            
            return `
                <div class="${promiseItemClasses}">
                    <div class="promise-content">${this.escapeHtml(promise.content)}</div>
                    ${resolutionInfo}
                    <div class="promise-meta">
                        <span class="promise-date">${this.formatDate(promise.created_at)}</span>
                        <div class="screenshot-indicators">
                            ${initialScreenshotIndicator}
                            ${resolvedScreenshotIndicator}
                        </div>
                        <button class="delete-btn" onclick="app.promises.deletePromise(${promise.id})">×</button>
                    </div>
                </div>
            `;
        }).join('');
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

            const { data, error } = await window.PromiseKeeperConfig.supabaseClient
                .from('promises')
                .insert([
                    {
                        content: content.trim(),
                        owner_id: this.app.currentUser.id,
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

    escapeHtml(text) {
        const div = document.createElement('div');
        div.textContent = text;
        return div.innerHTML;
    }

    formatDate(dateString) {
        const date = new Date(dateString);
        return date.toLocaleDateString() + ' ' + date.toLocaleTimeString();
    }

    // Test method for resolved promises - can be removed in production
    addTestResolvedPromise() {
        if (!this.promises || this.promises.length === 0) return;
        
        // Mock a resolved promise for testing
        const testPromise = {
            ...this.promises[0],
            id: this.promises[0].id + 1000, // Avoid ID conflicts
            resolved: true,
            resolved_screenshot_id: 'test_resolved_screenshot_123',
            resolved_screenshot_time: new Date().toISOString(),
            resolved_reason: 'Test: Email was sent successfully as evidenced by the sent confirmation dialog.'
        };
        
        this.promises.unshift(testPromise);
        this.renderPromises();
        console.log('Added test resolved promise for UI testing');
    }
}

// Make available globally
window.PromiseKeeperPromises = {
    PromiseManager
}; 