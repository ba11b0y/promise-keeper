console.log('Promise Keeper promise-listing.js loading...');

class PromiseListingPage {
    constructor(app) {
        this.app = app;
        this.promises = [];
        this.filteredPromises = [];
        this.searchQuery = '';
        this.isAddingPromise = false;
        this.newPromise = '';
        this.liquidBg = null;
        this.settingsModal = null;
        this.isSettingsOpen = false;
        this.animationTimeouts = [];
        this.container = null;
        
        // Bind methods
        this.handleSearch = this.handleSearch.bind(this);
        this.addPromise = this.addPromise.bind(this);
        this.showAddPromiseForm = this.showAddPromiseForm.bind(this);
        this.hideAddPromiseForm = this.hideAddPromiseForm.bind(this);
        this.openSettings = this.openSettings.bind(this);
        this.closeSettings = this.closeSettings.bind(this);
        this.handleSignOut = this.handleSignOut.bind(this);
        this.handleScreenshotModeChange = this.handleScreenshotModeChange.bind(this);
        this.takeScreenshot = this.takeScreenshot.bind(this);
        
        this.init();
    }

    init() {
        this.createHTML();
        this.setupEventListeners();
        this.initLiquidBackground();
    }

    createHTML() {
        if (!this.container) {
            console.error('createHTML: container is null, cannot create HTML');
            return;
        }

        console.log('createHTML: Creating HTML for promise listing');
        
        // Ensure the container takes up all available space
        this.container.style.height = '100%';
        this.container.style.display = 'flex';
        this.container.style.flexDirection = 'column';
        
        this.container.innerHTML = `
            <div class="listing-page-container">
                <!-- Liquid Background Container -->
                <div id="listingLiquidBg" class="listing-liquid-bg"></div>
                
                <!-- Main Content -->
                <div class="listing-content">
                    <!-- Header -->
                    <div class="listing-header">
                        <div class="listing-header-content">
                            <div class="listing-header-left">
                                <h1 class="listing-title">Good morning, <span id="userName">User</span></h1>
                                <p class="listing-subtitle">
                                    <span id="completionPercentage">0</span>% of promises completed • 
                                    <span id="totalCount">0</span> total
                                </p>
                            </div>
                            <div class="listing-header-right">
                                <button class="listing-btn listing-btn-ghost" id="settingsBtn">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <circle cx="12" cy="12" r="3"/>
                                        <path d="M12 1v6m0 12v6m11-7h-6m-12 0h6m9.5-8.5l-4.5 4.5m-9-9l4.5 4.5m4.5 0l-4.5-4.5m9 9l-4.5-4.5"/>
                                    </svg>
                                    Settings
                                </button>
                                <button class="listing-btn listing-btn-ghost" id="signOutBtn">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M9 21H5a2 2 0 01-2-2V5a2 2 0 012-2h4m7 14l5-5-5-5m5 5H9"/>
                                    </svg>
                                    Sign Out
                                </button>
                            </div>
                        </div>
                    </div>

                    <!-- Stats Cards -->
                    <div class="stats-grid">
                        <div class="stat-card stat-card-blue">
                            <div class="stat-gradient stat-gradient-blue"></div>
                            <div class="stat-content">
                                <div class="stat-value" id="statTotal">0</div>
                                <div class="stat-label">Total Promises</div>
                            </div>
                        </div>
                        <div class="stat-card stat-card-green">
                            <div class="stat-gradient stat-gradient-green"></div>
                            <div class="stat-content">
                                <div class="stat-value" id="statCompleted">0</div>
                                <div class="stat-label">Completed</div>
                            </div>
                        </div>
                        <div class="stat-card stat-card-orange">
                            <div class="stat-gradient stat-gradient-orange"></div>
                            <div class="stat-content">
                                <div class="stat-value" id="statPending">0</div>
                                <div class="stat-label">Pending</div>
                            </div>
                        </div>
                    </div>

                    <!-- Controls -->
                    <div class="listing-controls">
                        <div class="listing-controls-content">
                            <div class="search-container">
                                <svg class="search-icon" width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <circle cx="11" cy="11" r="8"/>
                                    <path d="m21 21-4.35-4.35"/>
                                </svg>
                                <input type="text" class="search-input" id="searchInput" placeholder="Search promises..." />
                            </div>
                            <button class="listing-btn listing-btn-primary" id="newPromiseBtn">
                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                    <line x1="12" y1="5" x2="12" y2="19"/>
                                    <line x1="5" y1="12" x2="19" y2="12"/>
                                </svg>
                                New Promise
                            </button>
                        </div>
                    </div>

                    <!-- Add Promise Form -->
                    <div class="add-promise-form" id="addPromiseForm" style="display: none;">
                        <div class="add-promise-content">
                            <input type="text" class="promise-input" id="promiseInput" placeholder="I promise to..." />
                            <div class="add-promise-actions">
                                <button class="listing-btn listing-btn-primary" id="addPromiseBtn">Add Promise</button>
                                <button class="listing-btn listing-btn-ghost" id="cancelPromiseBtn">Cancel</button>
                            </div>
                        </div>
                    </div>

                    <!-- Promises List -->
                    <div class="promises-container">
                        <div class="promises-list" id="promisesList">
                            <!-- Promises will be rendered here -->
                        </div>
                    </div>
                </div>
            </div>

            <!-- Settings Modal -->
            <div class="settings-modal" id="settingsModal" style="display: none;">
                <div class="settings-backdrop"></div>
                <div class="settings-content">
                    <div class="settings-header">
                        <h2 class="settings-title">Settings</h2>
                        <button class="settings-close" id="settingsCloseBtn">
                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <line x1="18" y1="6" x2="6" y2="18"/>
                                <line x1="6" y1="6" x2="18" y2="18"/>
                            </svg>
                        </button>
                    </div>
                    <div class="settings-body">
                        <div class="settings-section">
                            <h3 class="settings-section-title">Screenshot Configuration</h3>
                            <div class="settings-option">
                                <label class="settings-label">Screenshot Mode</label>
                                <select class="settings-select" id="screenshotModeSelect">
                                    <option value="off">Off (Manual only)</option>
                                    <option value="interval">Every 30 seconds</option>
                                    <option value="enter" selected>On Enter key press</option>
                                </select>
                                <p class="settings-description">Choose when to automatically capture screenshots for promise tracking. Enter mode captures at most once per minute when Enter is pressed globally.</p>
                            </div>
                            <div class="settings-option">
                                <button class="listing-btn listing-btn-secondary" id="takeScreenshotBtn">
                                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                        <path d="M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z"/>
                                        <circle cx="12" cy="13" r="4"/>
                                    </svg>
                                    Take Screenshot Now
                                </button>
                            </div>
                            <div class="settings-option">
                                <label class="settings-label">Resolution Detection</label>
                                <div class="settings-checkbox-group">
                                    <label class="settings-checkbox">
                                        <input type="checkbox" id="autoResolveEnabled" checked>
                                        <span class="settings-checkbox-label">Enable automatic promise resolution detection</span>
                                    </label>
                                </div>
                                <p class="settings-description">Automatically detect when promises are completed based on screenshot analysis.</p>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
        `;
    }

    setupEventListeners() {
        // Clear any existing listeners by removing and re-adding elements
        this.removeEventListeners();
        
        // Header buttons
        const settingsBtn = document.getElementById('settingsBtn');
        const signOutBtn = document.getElementById('signOutBtn');
        const searchInput = document.getElementById('searchInput');
        const newPromiseBtn = document.getElementById('newPromiseBtn');
        const addPromiseBtn = document.getElementById('addPromiseBtn');
        const cancelPromiseBtn = document.getElementById('cancelPromiseBtn');
        const promiseInput = document.getElementById('promiseInput');
        const settingsCloseBtn = document.getElementById('settingsCloseBtn');
        const settingsModal = document.getElementById('settingsModal');
        const screenshotModeSelect = document.getElementById('screenshotModeSelect');
        const takeScreenshotBtn = document.getElementById('takeScreenshotBtn');
        
        if (settingsBtn) settingsBtn.addEventListener('click', this.openSettings);
        if (signOutBtn) signOutBtn.addEventListener('click', this.handleSignOut);
        if (searchInput) searchInput.addEventListener('input', (e) => this.handleSearch(e.target.value));
        if (newPromiseBtn) newPromiseBtn.addEventListener('click', this.showAddPromiseForm);
        if (addPromiseBtn) addPromiseBtn.addEventListener('click', this.addPromise);
        if (cancelPromiseBtn) cancelPromiseBtn.addEventListener('click', this.hideAddPromiseForm);
        
        if (promiseInput) {
            promiseInput.addEventListener('keydown', (e) => {
                if (e.key === 'Enter' && !e.shiftKey) {
                    e.preventDefault();
                    this.addPromise();
                } else if (e.key === 'Escape') {
                    this.hideAddPromiseForm();
                }
            });
        }
        
        if (settingsCloseBtn) settingsCloseBtn.addEventListener('click', this.closeSettings);
        if (settingsModal) {
            settingsModal.addEventListener('click', (e) => {
                if (e.target.classList.contains('settings-backdrop')) {
                    this.closeSettings();
                }
            });
        }
        
        if (screenshotModeSelect) screenshotModeSelect.addEventListener('change', async (e) => await this.handleScreenshotModeChange(e.target.value));
        if (takeScreenshotBtn) takeScreenshotBtn.addEventListener('click', this.takeScreenshot);
        
        // Auto-resolve setting
        const autoResolveCheckbox = document.getElementById('autoResolveEnabled');
        if (autoResolveCheckbox) {
            autoResolveCheckbox.addEventListener('change', (e) => this.handleAutoResolveChange(e.target.checked));
        }
    }
    
    removeEventListeners() {
        // Clear any existing timeouts
        this.animationTimeouts.forEach(timeout => clearTimeout(timeout));
        this.animationTimeouts = [];
    }

    initLiquidBackground() {
        // Clean up existing background
        if (this.liquidBg) {
            this.liquidBg.destroy();
            this.liquidBg = null;
        }
        
        setTimeout(() => {
            const bgContainer = document.getElementById('listingLiquidBg');
            if (bgContainer && window.LiquidBackground) {
                this.liquidBg = new window.LiquidBackground('listingLiquidBg');
            }
        }, 100);
    }

    show(user) {
        this.container = document.getElementById('promiseSection');
        if (!this.container) {
            console.error('promiseSection container not found - cannot show promise listing');
            return;
        }
        
        // Clear any existing content
        this.container.innerHTML = '';
        
        // Create the listing page HTML
        this.createHTML();
        this.setupEventListeners();
        
        if (user) {
            const firstName = user.email?.split('@')[0] || user.name?.split(' ')[0] || 'User';
            const userNameEl = document.getElementById('userName');
            if (userNameEl) {
                userNameEl.textContent = firstName;
            }
        }
        
        this.container.style.display = 'block';
        this.initLiquidBackground();
        this.loadPromises();
        this.loadSettings();
    }

    hide() {
        if (this.container) {
            this.container.style.display = 'none';
        }
        
        this.removeEventListeners();
        
        if (this.liquidBg) {
            this.liquidBg.destroy();
            this.liquidBg = null;
        }
        
        this.closeSettings();
    }

    async loadPromises() {
        if (!this.app.currentUser) {
            console.log('loadPromises: No current user, skipping');
            return;
        }

        try {
            console.log('loadPromises: Loading promises for user', this.app.currentUser.id);
            const { data, error } = await window.PromiseKeeperConfig.supabaseClient
                .from('promises')
                .select('*')
                .eq('owner_id', this.app.currentUser.id)
                .order('created_at', { ascending: false });

            if (error) {
                console.error('Failed to load promises:', error);
                return;
            }

            this.promises = data || [];
            console.log('loadPromises: Loaded', this.promises.length, 'promises:', this.promises);
            this.updateStats();
            this.filterAndRenderPromises();
        } catch (err) {
            console.error('Error loading promises:', err);
        }
    }

    updateStats() {
        const total = this.promises.length;
        const completed = this.promises.filter(p => p.resolved).length;
        const pending = total - completed;
        const percentage = total > 0 ? Math.round((completed / total) * 100) : 0;

        console.log('updateStats: total=', total, 'completed=', completed, 'pending=', pending);

        document.getElementById('completionPercentage').textContent = percentage;
        document.getElementById('totalCount').textContent = total;
        document.getElementById('statTotal').textContent = total;
        document.getElementById('statCompleted').textContent = completed;
        document.getElementById('statPending').textContent = pending;
    }

    handleSearch(query) {
        this.searchQuery = query.toLowerCase();
        this.filterAndRenderPromises();
    }

    filterAndRenderPromises() {
        this.filteredPromises = this.promises.filter(promise =>
            promise.content.toLowerCase().includes(this.searchQuery)
        );
        console.log('filterAndRenderPromises: Filtered', this.filteredPromises.length, 'promises from', this.promises.length, 'total');
        this.renderPromises();
    }

    renderPromises() {
        const container = document.getElementById('promisesList');
        if (!container) {
            console.error('promisesList container not found - cannot render promises');
            return;
        }

        if (this.filteredPromises.length === 0) {
            container.innerHTML = this.renderEmptyState();
            return;
        }

        // Clear container first
        container.innerHTML = '';
        
        // Add promises with staggered animation
        this.filteredPromises.forEach((promise, promiseIndex) => {
            const promiseElement = document.createElement('div');
            promiseElement.innerHTML = this.renderPromiseItem(promise);
            const promiseItem = promiseElement.firstElementChild;
            
            // Set initial state for animation
            promiseItem.style.opacity = '0';
            promiseItem.style.transform = 'translateY(20px)';
            promiseItem.style.transition = 'all 0.4s ease';
            
            container.appendChild(promiseItem);
            
            // Add event listeners for this promise item
            this.addPromiseItemListeners(promiseItem, promise);
            
            // Animate in with delay
            const timeout = setTimeout(() => {
                promiseItem.style.opacity = '1';
                promiseItem.style.transform = 'translateY(0)';
            }, promiseIndex * 30);
            
            this.animationTimeouts.push(timeout);
        });
    }

    renderPromiseItem(promise) {
        const isResolved = promise.resolved;
        const screenshotIndicators = this.renderScreenshotIndicators(promise);
        const resolutionInfo = this.renderResolutionInfo(promise);

        return `
            <div class="promise-item ${isResolved ? 'promise-resolved' : ''}" data-promise-id="${promise.id}">
                <div class="promise-item-content">
                    <button class="promise-checkbox ${isResolved ? 'promise-checkbox-checked' : ''}" 
                            data-action="toggle" data-promise-id="${promise.id}">
                        <svg class="promise-check-icon" width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="3">
                            <polyline points="20,6 9,17 4,12"/>
                        </svg>
                    </button>
                    <div class="promise-text-container">
                        <p class="promise-text ${isResolved ? 'promise-text-completed' : ''}">${this.escapeHtml(promise.content)}</p>
                        ${resolutionInfo}
                    </div>
                    <div class="promise-actions">
                        ${screenshotIndicators}
                        <button class="promise-delete-btn" data-action="delete" data-promise-id="${promise.id}">
                            <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                                <line x1="18" y1="6" x2="6" y2="18"/>
                                <line x1="6" y1="6" x2="18" y2="18"/>
                            </svg>
                        </button>
                    </div>
                </div>
            </div>
        `;
    }
    
    addPromiseItemListeners(promiseItem, promise) {
        // Toggle checkbox
        const checkbox = promiseItem.querySelector('[data-action="toggle"]');
        if (checkbox) {
            checkbox.addEventListener('click', (e) => {
                e.preventDefault();
                this.togglePromise(promise.id);
            });
        }
        
        // Delete button
        const deleteBtn = promiseItem.querySelector('[data-action="delete"]');
        if (deleteBtn) {
            deleteBtn.addEventListener('click', (e) => {
                e.preventDefault();
                this.deletePromise(promise.id);
            });
        }
        
        // Screenshot indicators
        const screenshotBtns = promiseItem.querySelectorAll('.screenshot-indicator');
        screenshotBtns.forEach(btn => {
            btn.addEventListener('click', (e) => {
                e.preventDefault();
                const screenshotId = btn.getAttribute('data-screenshot-id');
                if (screenshotId) {
                    if (this.app.screenshots) {
                        this.app.screenshots.viewScreenshot(screenshotId);
                    } else {
                        console.warn('Screenshot manager not available, screenshotId:', screenshotId);
                    }
                }
            });
        });
    }

    renderScreenshotIndicators(promise) {
        let indicators = '';
        
        if (promise.extracted_from_screenshot && promise.screenshot_id) {
            indicators += `
                <button class="screenshot-indicator initial" data-screenshot-id="${promise.screenshot_id}" title="View source screenshot">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z"/>
                        <circle cx="12" cy="13" r="4"/>
                    </svg>
                </button>
            `;
        }
        
        if (promise.resolved && promise.resolved_screenshot_id) {
            indicators += `
                <button class="screenshot-indicator resolved" data-screenshot-id="${promise.resolved_screenshot_id}" title="View resolution screenshot">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M9 11l3 3L22 4"/>
                        <path d="M21 12v7a2 2 0 01-2 2H5a2 2 0 01-2-2V5a2 2 0 012-2h11"/>
                    </svg>
                </button>
            `;
        }
        
        return indicators;
    }

    renderResolutionInfo(promise) {
        // Don't render any resolution info - just return empty string
        return '';
    }

    renderEmptyState() {
        const message = this.searchQuery 
            ? 'No promises match your search'
            : 'No promises yet';
        const subMessage = this.searchQuery 
            ? 'Try adjusting your search terms'
            : 'Create your first promise to get started';

        return `
            <div class="empty-state">
                <div class="empty-state-icon">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.5">
                        <circle cx="11" cy="11" r="8"/>
                        <path d="m21 21-4.35-4.35"/>
                    </svg>
                </div>
                <p class="empty-state-title">${message}</p>
                <p class="empty-state-subtitle">${subMessage}</p>
            </div>
        `;
    }

    showAddPromiseForm() {
        this.isAddingPromise = true;
        const form = document.getElementById('addPromiseForm');
        const input = document.getElementById('promiseInput');
        
        if (!form || !input) return;
        
        form.style.display = 'block';
        form.style.opacity = '0';
        form.style.transform = 'translateY(-20px)';
        
        // Animate in
        setTimeout(() => {
            form.style.opacity = '1';
            form.style.transform = 'translateY(0)';
        }, 10);
        
        setTimeout(() => input.focus(), 100);
    }

    hideAddPromiseForm() {
        this.isAddingPromise = false;
        const form = document.getElementById('addPromiseForm');
        const input = document.getElementById('promiseInput');
        
        if (!form || !input) return;
        
        form.style.opacity = '0';
        form.style.transform = 'translateY(-20px)';
        
        setTimeout(() => {
            form.style.display = 'none';
            input.value = '';
            form.style.transform = 'translateY(0)';
        }, 200);
    }

    async addPromise() {
        const input = document.getElementById('promiseInput');
        const content = input.value.trim();

        if (!content) return;
        if (!this.app.currentUser) {
            alert('Please log in first');
            return;
        }

        try {
            const { data, error } = await window.PromiseKeeperConfig.supabaseClient
                .from('promises')
                .insert([{
                    content: content,
                    owner_id: this.app.currentUser.id
                }])
                .select()
                .single();

            if (error) {
                console.error('Failed to add promise:', error);
                alert('Failed to add promise: ' + error.message);
                return;
            }

            this.promises.unshift(data);
            this.updateStats();
            this.filterAndRenderPromises();
            this.hideAddPromiseForm();

            // Show notification
            if (window.electronAPI?.notifications) {
                window.electronAPI.notifications.show(
                    'Promise Added',
                    `${content}`,
                    { action: 'promise_added', to_whom: '', start_date: '' }
                );
            }
        } catch (err) {
            console.error('Error adding promise:', err);
            alert('Failed to add promise: ' + err.message);
        }
    }

    async togglePromise(id) {
        const promise = this.promises.find(p => p.id === id);
        if (!promise) return;

        try {
            let updateData = { resolved: !promise.resolved };
            
            if (!promise.resolved) {
                // Resolving the promise - add resolution data
                const resolvedData = await this.mockResolvePromise(promise);
                updateData.resolved_screenshot_time = resolvedData.timestamp;
                updateData.resolved_reason = resolvedData.reason;
                updateData.resolved_screenshot_id = resolvedData.screenshotId;
            } else {
                // Unresolving the promise - clear resolution data
                updateData.resolved_screenshot_time = null;
                updateData.resolved_reason = null;
                updateData.resolved_screenshot_id = null;
            }
            
            const { error } = await window.PromiseKeeperConfig.supabaseClient
                .from('promises')
                .update(updateData)
                .eq('id', id);

            if (error) {
                console.error('Failed to update promise:', error);
                alert('Failed to update promise: ' + error.message);
                return;
            }

            // Update local data
            promise.resolved = !promise.resolved;
            if (promise.resolved) {
                promise.resolved_screenshot_time = updateData.resolved_screenshot_time;
                promise.resolved_reason = updateData.resolved_reason;
                promise.resolved_screenshot_id = updateData.resolved_screenshot_id;
            } else {
                promise.resolved_screenshot_time = null;
                promise.resolved_reason = null;
                promise.resolved_screenshot_id = null;
            }

            this.updateStats();
            this.filterAndRenderPromises();
        } catch (err) {
            console.error('Error toggling promise:', err);
            alert('Error updating promise: ' + err.message);
        }
    }

    async mockResolvePromise(promise) {
        // Mock the backend API call for promise resolution
        // In production, this would call the actual resolution API
        try {
            // Simulate API delay
            await new Promise(resolve => setTimeout(resolve, 500));
            
            // Mock successful resolution
            return {
                timestamp: new Date().toISOString(),
                reason: `Promise "${promise.content.substring(0, 50)}..." was resolved successfully`,
                screenshotId: `mock_screenshot_${Date.now()}`
            };
        } catch (error) {
            console.error('Mock resolution error:', error);
            throw error;
        }
    }
    
    async createPromiseFromExtraction(promise, screenshotId, timestamp) {
        try {
            // Extract promise content (same as existing promises.js logic)
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
                this.updateStats();
                this.filterAndRenderPromises();

                return data;
            }
        } catch (error) {
            console.error('Error creating promise from extraction:', error);
            return null;
        }
    }

    async deletePromise(id) {
        if (!confirm('Are you sure you want to delete this promise?')) return;

        try {
            const { error } = await window.PromiseKeeperConfig.supabaseClient
                .from('promises')
                .delete()
                .eq('id', id);

            if (error) {
                console.error('Failed to delete promise:', error);
                return;
            }

            this.promises = this.promises.filter(p => p.id !== id);
            this.updateStats();
            this.filterAndRenderPromises();
        } catch (err) {
            console.error('Error deleting promise:', err);
        }
    }

    openSettings() {
        this.isSettingsOpen = true;
        const modal = document.getElementById('settingsModal');
        if (!modal) return;
        
        modal.style.display = 'flex';
        modal.style.opacity = '0';
        
        setTimeout(() => {
            modal.style.opacity = '1';
            modal.classList.add('settings-modal-open');
        }, 10);
    }

    closeSettings() {
        this.isSettingsOpen = false;
        const modal = document.getElementById('settingsModal');
        if (!modal) return;
        
        modal.style.opacity = '0';
        modal.classList.remove('settings-modal-open');
        
        setTimeout(() => {
            modal.style.display = 'none';
        }, 200);
    }

    loadSettings() {
        // Load screenshot mode
        const savedMode = localStorage.getItem('screenshotMode');
        const select = document.getElementById('screenshotModeSelect');
        if (savedMode && select) {
            select.value = savedMode;
        } else if (select) {
            select.value = 'enter'; // Default
        }
        
        // Load auto-resolve setting
        const savedAutoResolve = localStorage.getItem('autoResolveEnabled');
        const autoResolveCheckbox = document.getElementById('autoResolveEnabled');
        if (autoResolveCheckbox) {
            autoResolveCheckbox.checked = savedAutoResolve !== 'false'; // Default to true
        }
        
        // Apply settings to screenshot manager
        if (this.app && this.app.screenshots) {
            this.app.screenshots.screenshotMode = savedMode || 'enter';
            this.app.screenshots.autoResolveEnabled = savedAutoResolve !== 'false';
            
            // Set the mode via the screenshot manager's method
            // Since IPC handlers are now set up before window creation, they should be ready
            this.app.screenshots.setScreenshotMode(savedMode || 'enter')
                .then(() => {
                    console.log('Successfully set screenshot mode in promise listing');
                })
                .catch(error => {
                    console.warn('Failed to set initial screenshot mode in loadSettings:', error);
                    // Don't throw - this is not critical for app startup
                });
        } else {
            console.warn('Screenshot manager not available during loadSettings');
        }
    }

    async handleScreenshotModeChange(mode) {
        localStorage.setItem('screenshotMode', mode);
        
        // Update the shared screenshot manager
        if (this.app.screenshots) {
            await this.app.screenshots.setScreenshotMode(mode);
        } else {
            // Fallback to direct IPC call if screenshot manager isn't available
            try {
                if (window.electronAPI?.screenshots?.setScreenshotMode) {
                    const result = await window.electronAPI.screenshots.setScreenshotMode(mode);
                    if (result && !result.success) {
                        console.error('Failed to set screenshot mode:', result.error);
                    }
                }
            } catch (error) {
                console.error('Error setting screenshot mode via IPC:', error);
            }
        }
    }
    
    handleAutoResolveChange(enabled) {
        localStorage.setItem('autoResolveEnabled', enabled.toString());
        if (this.app.screenshots) {
            this.app.screenshots.autoResolveEnabled = enabled;
        }
    }

    takeScreenshot() {
        // Use the shared screenshot manager
        if (this.app.screenshots) {
            this.app.screenshots.takeScreenshotNow();
        } else {
            // Fallback to direct IPC call
            if (window.electronAPI?.screenshots?.takeScreenshotNow) {
                window.electronAPI.screenshots.takeScreenshotNow();
            }
        }
    }

    handleSignOut() {
        if (this.app.auth) {
            this.app.auth.handleLogout();
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

    destroy() {
        this.removeEventListeners();
        
        if (this.liquidBg) {
            this.liquidBg.destroy();
            this.liquidBg = null;
        }
        
        this.closeSettings();
        this.promises = [];
        this.filteredPromises = [];
        this.container = null;
    }
    
    // Method to be called from other components when promises are auto-created
    onPromisesAutoCreated(promises, screenshotId) {
        if (!promises || promises.length === 0) return;
        
        console.log('onPromisesAutoCreated called with', promises.length, 'promises');
        
        // Add promises to local list
        promises.forEach(promise => {
            this.promises.unshift(promise);
        });
        
        this.updateStats();
        this.filterAndRenderPromises();
        
        // Show notification indicator (similar to existing showAutoPromiseCreatedIndicator)
        this.showAutoPromiseCreatedIndicator(promises, screenshotId);
    }
    
    showAutoPromiseCreatedIndicator(promises, screenshotId) {
        if (!promises || promises.length === 0) return;

        // Create a temporary indicator showing the auto-created promises
        const indicator = document.createElement('div');
        indicator.className = 'auto-promise-indicator';
        
        const promisesList = promises.map(p => {
            const content = p.content || p.text || (typeof p === 'string' ? p : JSON.stringify(p));
            return content.length > 50 ? content.substring(0, 50) + '...' : content;
        }).join('<br>• ');

        indicator.innerHTML = `
            <div class="auto-promise-notification">
                <div class="auto-promise-header">
                    <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5">
                        <polyline points="20,6 9,17 4,12"/>
                    </svg>
                    <strong>${promises.length} Promise${promises.length > 1 ? 's' : ''} Auto-Created</strong>
                </div>
                <span class="promise-list">${promisesList}</span>
                <span class="screenshot-info">
                    <svg width="12" height="12" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
                        <path d="M23 19a2 2 0 01-2 2H3a2 2 0 01-2-2V8a2 2 0 012-2h4l2-3h6l2 3h4a2 2 0 012 2z"/>
                        <circle cx="12" cy="13" r="4"/>
                    </svg>
                    Screenshot: ${screenshotId}
                </span>
            </div>
        `;
        
        document.body.appendChild(indicator);
        
        // Animate in
        setTimeout(() => {
            const indicatorEl = indicator.querySelector('.auto-promise-notification');
            if (indicatorEl) {
                indicatorEl.style.opacity = '1';
                indicatorEl.style.transform = 'translateY(0)';
            }
        }, 100);
        
        // Remove after 6 seconds
        setTimeout(() => {
            const indicatorEl = indicator.querySelector('.auto-promise-notification');
            if (indicatorEl) {
                indicatorEl.style.opacity = '0';
                indicatorEl.style.transform = 'translateY(-20px)';
                setTimeout(() => {
                    if (indicator.parentNode) {
                        indicator.parentNode.removeChild(indicator);
                    }
                }, 300);
            }
        }, 6000);
    }
}

// Make available globally
window.PromiseKeeperListing = {
    PromiseListingPage
};