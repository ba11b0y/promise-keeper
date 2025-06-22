/**
 * Action Handlers for Promise Keeper MCP Actions
 * 
 * This file contains handlers for executing specific action types
 * that can be returned in the potential_actions JSON from the API.
 */

console.log('Promise Keeper action-handlers.js loading...');

class ActionHandlers {
    constructor(app) {
        this.app = app;
    }

    /**
     * Check if an action is a recognized MCP action type
     * @param {Object} action - Action object to check
     * @returns {boolean} True if action has a recognized tool_name
     */
    isMCPAction(action) {
        if (!action || typeof action !== 'object') return false;
        
        // Check if tool_name is at the top level
        let toolName = action.tool_name;
        
        // If not found at top level, check if it's nested in action.action
        if (!toolName && action.action && typeof action.action === 'object') {
            toolName = action.action.tool_name;
        }
        
        const mcpToolNames = [
            'messages_compose_message',
            'system_launch_app',
            'calendar_add'
        ];
        
        return mcpToolNames.includes(toolName);
    }

    /**
     * Extract the nested action data from the action object
     * @param {Object} action - The action object
     * @returns {Object} The nested action data with tool_name
     */
    extractActionData(action) {
        // If tool_name is at the top level, return as-is
        if (action.tool_name) {
            return action;
        }
        
        // If tool_name is nested in action.action, return the nested object
        if (action.action && typeof action.action === 'object' && action.action.tool_name) {
            return action.action;
        }
        
        return action; // fallback
    }

    /**
     * Execute an MCP action based on its type
     * @param {Object} action - The action object to execute
     * @returns {Promise<boolean>} True if action was handled successfully
     */
    async executeAction(action) {
        if (!this.isMCPAction(action)) {
            console.log('Action is not a recognized MCP action:', action);
            return false;
        }

        // Extract the actual action data (handling nested structure)
        const actionData = this.extractActionData(action);
        console.log('Extracted action data:', actionData);

        try {
            switch (actionData.tool_name) {
                case 'messages_compose_message':
                    return await this.handleMessagesComposeMessage(actionData);
                case 'system_launch_app':
                    return await this.handleSystemLaunchApp(actionData);
                case 'calendar_add':
                    return await this.handleCalendarAdd(actionData);
                default:
                    console.error('Unknown MCP action tool_name:', actionData.tool_name);
                    return false;
            }
        } catch (error) {
            console.error('Error executing action:', error);
            window.PromiseKeeperUI?.showUploadMessage(`Failed to execute action: ${error.message}`, 'error');
            return false;
        }
    }

    /**
     * Handle Messages MCP Call action
     * @param {Object} action - Messages_MCP_Call action object
     * @returns {Promise<boolean>} Success status
     */
    async handleMessagesComposeMessage(action) {
        console.log('Handling Messages Compose Message:', action);
        
        // Validate required fields
        if (!action.recipient || !action.body) {
            throw new Error('Messages action missing required fields: recipient, body');
        }

        try {
            // Final MCP call location
            console.log(`This is the place where you would call messages_compose_message with recipient: ${action.recipient} | and body: ${action.body}`);

            // Simulate the action for now
            await this.simulateDelay(1000);

            // Show success notification
            if (window.electronAPI?.notifications) {
                window.electronAPI.notifications.show(
                    'Message Composed',
                    `Message prepared for ${action.recipient}`,
                    { action: 'messages_compose_message', to_whom: action.recipient }
                );
            }

            window.PromiseKeeperUI?.showUploadMessage(
                `✅ Message composed for ${action.recipient}`, 
                'success'
            );

            return true;
        } catch (error) {
            console.error('Failed to compose message:', error);
            throw new Error(`Message composition failed: ${error.message}`);
        }
    }

    /**
     * Handle System Launch App action
     * @param {Object} action - System_Launch_App action object  
     * @returns {Promise<boolean>} Success status
     */
    async handleSystemLaunchApp(action) {
        console.log('Handling System Launch App:', action);
        
        // Validate required fields
        if (!action.name) {
            throw new Error('System launch action missing required field: name');
        }

        try {
            // Final MCP call location
            console.log(`This is the place where you would call system_launch_app with name: ${action.name}`);

            // Simulate the action for now
            await this.simulateDelay(500);

            // Show success notification
            if (window.electronAPI?.notifications) {
                window.electronAPI.notifications.show(
                    'App Launched',
                    `${action.name} has been launched`,
                    { action: 'system_launch_app', to_whom: '', start_date: '' }
                );
            }

            window.PromiseKeeperUI?.showUploadMessage(
                `✅ Launched ${action.name}`, 
                'success'
            );

            return true;
        } catch (error) {
            console.error('Failed to launch app:', error);
            throw new Error(`App launch failed: ${error.message}`);
        }
    }

    /**
     * Handle Calendar Add action
     * @param {Object} action - Calendar_Add action object
     * @returns {Promise<boolean>} Success status
     */
    async handleCalendarAdd(action) {
        console.log('Handling Calendar Add:', action);
        
        // Validate required fields
        if (!action.title || !action.startDate || !action.endDate) {
            throw new Error('Calendar action missing required fields: title, startDate, endDate');
        }

        try {
            // Validate date formats
            const startDate = new Date(action.startDate);
            const endDate = new Date(action.endDate);
            
            if (isNaN(startDate.getTime()) || isNaN(endDate.getTime())) {
                throw new Error('Invalid date format in calendar action');
            }

            if (endDate <= startDate) {
                throw new Error('End date must be after start date');
            }

            // Final MCP call location
            console.log(`This is the place where you would call calendar_add with title: ${action.title} | startDate: ${action.startDate} | and endDate: ${action.endDate}`);

            // Simulate the action for now
            await this.simulateDelay(800);

            // Show success notification
            if (window.electronAPI?.notifications) {
                window.electronAPI.notifications.show(
                    'Calendar Event Added',
                    `"${action.title}" added to calendar`,
                    { action: 'calendar_add', start_date: action.startDate, to_whom: '' }
                );
            }

            window.PromiseKeeperUI?.showUploadMessage(
                `✅ Calendar event "${action.title}" added`, 
                'success'
            );

            return true;
        } catch (error) {
            console.error('Failed to add calendar event:', error);
            throw new Error(`Calendar event creation failed: ${error.message}`);
        }
    }

    /**
     * Get a user-friendly description for an action
     * @param {Object} action - Action object
     * @returns {string} Human-readable description
     */
    getActionDescription(action) {
        if (!this.isMCPAction(action)) {
            return action.description || action.action || 'Unknown action';
        }

        const actionData = this.extractActionData(action);

        switch (actionData.tool_name) {
            case 'messages_compose_message':
                return `Send message to ${actionData.recipient}`;
            case 'system_launch_app':
                return `Launch ${actionData.name}`;
            case 'calendar_add':
                return `Add "${actionData.title}" to calendar`;
            default:
                return action.description || action.action || 'MCP Action';
        }
    }

    /**
     * Get an appropriate icon for an action
     * @param {Object} action - Action object
     * @returns {string} Emoji icon for the action
     */
    getActionIcon(action) {
        if (!this.isMCPAction(action)) {
            return '⚡'; // Generic action icon
        }

        const actionData = this.extractActionData(action);

        switch (actionData.tool_name) {
            case 'messages_compose_message':
                return '📱';
            case 'system_launch_app':
                return '🚀';
            case 'calendar_add':
                return '📅';
            default:
                return '🔧';
        }
    }

    /**
     * Check if action execution requires user confirmation
     * @param {Object} action - Action object
     * @returns {boolean} True if confirmation is needed
     */
    requiresConfirmation(action) {
        if (!this.isMCPAction(action)) {
            return true; // Default to requiring confirmation for unknown actions
        }

        // For now, all MCP actions require confirmation
        // This could be made configurable per action type
        return true;
    }

    /**
     * Show confirmation dialog for action execution
     * @param {Object} action - Action object
     * @returns {Promise<boolean>} True if user confirmed
     */
    async confirmAction(action) {
        const description = this.getActionDescription(action);
        const icon = this.getActionIcon(action);
        
        return confirm(`${icon} Execute action: ${description}?`);
    }

    /**
     * Execute an action with optional confirmation
     * @param {Object} action - Action object
     * @param {boolean} skipConfirmation - Whether to skip confirmation dialog
     * @returns {Promise<boolean>} Success status
     */
    async executeActionWithConfirmation(action, skipConfirmation = false) {
        if (!skipConfirmation && this.requiresConfirmation(action)) {
            const confirmed = await this.confirmAction(action);
            if (!confirmed) {
                console.log('Action execution cancelled by user');
                return false;
            }
        }

        return await this.executeAction(action);
    }

    /**
     * Simulate a delay (for testing purposes)
     * @param {number} ms - Milliseconds to delay
     * @returns {Promise<void>}
     */
    async simulateDelay(ms) {
        return new Promise(resolve => setTimeout(resolve, ms));
    }
}

// Export the ActionHandlers class to the global scope
window.PromiseKeeperActionHandlers = ActionHandlers; 