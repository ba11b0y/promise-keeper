/**
 * Utility functions for parsing Promise Keeper API responses
 * This file provides runtime parsing utilities based on TypeScript types
 */

console.log('Promise Keeper types-utils.js loading...');

/**
 * Parse potential actions from JSON string
 * @param {string} actionsJson - JSON string of potential actions
 * @returns {Array} Array of potential action objects
 */
function parsePotentialActions(actionsJson) {
    if (!actionsJson) return [];
    
    try {
        const actions = JSON.parse(actionsJson);
        return Array.isArray(actions) ? actions : [];
    } catch (error) {
        console.error('Failed to parse potential_actions:', error);
        return [];
    }
}

/**
 * Parse extraction data from JSON string
 * @param {string} extractionDataJson - JSON string of extraction data
 * @returns {Object} Extraction data object
 */
function parseExtractionData(extractionDataJson) {
    if (!extractionDataJson) return {};
    
    try {
        return JSON.parse(extractionDataJson);
    } catch (error) {
        console.error('Failed to parse extraction_data:', error);
        return {};
    }
}

/**
 * Parse a database promise to include parsed JSON fields
 * @param {Object} promise - Database promise object
 * @returns {Object} Promise with parsed potential_actions and extraction_data
 */
function parsePromiseWithActions(promise) {
    if (!promise) return null;
    
    const parsed = { ...promise };
    
    // Parse potential actions
    parsed.potential_actions_parsed = parsePotentialActions(promise.potential_actions);
    
    // Parse extraction data
    parsed.extraction_data_parsed = parseExtractionData(promise.extraction_data);
    
    return parsed;
}

/**
 * Parse an array of database promises
 * @param {Array} promises - Array of database promise objects
 * @returns {Array} Array of promises with parsed JSON fields
 */
function parsePromisesWithActions(promises) {
    if (!Array.isArray(promises)) return [];
    
    return promises.map(parsePromiseWithActions);
}

/**
 * Validate that an API response matches expected Promise List Response format
 * @param {Object} response - API response object
 * @returns {boolean} True if response has expected structure
 */
function isValidPromiseListResponse(response) {
    return response && 
           typeof response === 'object' && 
           Array.isArray(response.promises);
}

/**
 * Extract potential actions from an extracted promise object
 * @param {Object} extractedPromise - Promise from API extraction response
 * @returns {Array} Array of potential actions
 */
function extractPotentialActions(extractedPromise) {
    if (!extractedPromise) return [];
    
    if (Array.isArray(extractedPromise.potential_actions)) {
        return extractedPromise.potential_actions;
    }
    
    return [];
}

/**
 * Check if an action is an MCP action with a tool_name
 * @param {Object} action - Action object to check
 * @returns {boolean} True if action has a recognized tool_name
 */
function isMCPAction(action) {
    console.log('isMCPAction called with:', action);
    console.log('Action type:', typeof action);
    
    if (!action || typeof action !== 'object') {
        console.log('Action is not an object');
        return false;
    }
    
    // Check if tool_name is at the top level
    let toolName = action.tool_name;
    console.log('Top-level tool_name:', toolName);
    
    // If not found at top level, check if it's nested in action.action
    if (!toolName && action.action && typeof action.action === 'object') {
        toolName = action.action.tool_name;
        console.log('Nested tool_name:', toolName);
    }
    
    const mcpToolNames = [
        'messages_compose_message',
        'system_launch_app',
        'calendar_add'
    ];
    
    const result = mcpToolNames.includes(toolName);
    console.log('Final tool_name used:', toolName);
    console.log('isMCPAction result:', result);
    return result;
}

/**
 * Categorize actions by type (MCP vs generic)
 * @param {Array} actions - Array of action objects
 * @returns {Object} Categorized actions object
 */
function categorizeActions(actions) {
    console.log('categorizeActions called with:', actions);
    
    if (!Array.isArray(actions)) {
        console.log('Actions is not an array:', actions);
        return { mcp: [], generic: [] };
    }
    
    const mcp = [];
    const generic = [];
    
    actions.forEach((action, index) => {
        console.log(`Checking action ${index}:`, action);
        const isMCP = isMCPAction(action);
        console.log(`Action ${index} is MCP:`, isMCP);
        
        if (isMCP) {
            mcp.push(action);
        } else {
            generic.push(action);
        }
    });
    
    console.log('Categorized actions - MCP:', mcp, 'Generic:', generic);
    return { mcp, generic };
}

/**
 * Get a user-friendly description for an MCP action
 * @param {Object} action - MCP action object
 * @returns {string} Human-readable description
 */
function getMCPActionDescription(action) {
    if (!isMCPAction(action)) {
        return action.description || action.action || 'Unknown action';
    }

    switch (action.tool_name) {
        case 'messages_compose_message':
            return `Send message to ${action.recipient}`;
        case 'system_launch_app':
            return `Launch ${action.name}`;
        case 'calendar_add':
            return `Add "${action.title}" to calendar`;
        default:
            return action.description || action.action || 'MCP Action';
    }
}

/**
 * Get icon for action type
 * @param {Object} action - Action object
 * @returns {string} Emoji icon
 */
function getActionIcon(action) {
    if (!isMCPAction(action)) {
        return '⚡'; // Generic action icon
    }

    switch (action.tool_name) {
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
 * Create a display-friendly promise object with actions
 * @param {Object} extractedPromise - Promise from API extraction response
 * @returns {Object} Display-ready promise object
 */
function createDisplayPromise(extractedPromise) {
    if (!extractedPromise) return null;
    
    let content = extractedPromise.content || '';
    
    // Enhance content with additional details
    if (extractedPromise.to_whom) {
        content += ` (to ${extractedPromise.to_whom})`;
    }
    if (extractedPromise.deadline) {
        content += ` (by ${extractedPromise.deadline})`;
    }
    
    const potentialActions = extractPotentialActions(extractedPromise);
    const categorizedActions = categorizeActions(potentialActions);
    
    return {
        content: content.trim(),
        original_content: extractedPromise.content,
        to_whom: extractedPromise.to_whom,
        deadline: extractedPromise.deadline,
        potential_actions: potentialActions,
        mcp_actions: categorizedActions.mcp,
        generic_actions: categorizedActions.generic,
        has_actions: potentialActions.length > 0,
        has_mcp_actions: categorizedActions.mcp.length > 0,
        has_generic_actions: categorizedActions.generic.length > 0
    };
}

/**
 * Process API response and create display-ready promises
 * @param {Object} apiResponse - Response from promise extraction API
 * @returns {Object} Processed response with display-ready promises
 */
function processApiResponse(apiResponse) {
    if (!isValidPromiseListResponse(apiResponse)) {
        console.error('Invalid API response format:', apiResponse);
        return {
            promises: [],
            resolved_promises: [],
            resolved_count: 0,
            has_new_promises: false,
            has_resolved_promises: false
        };
    }
    
    const processedPromises = apiResponse.promises.map(createDisplayPromise).filter(Boolean);
    const resolvedPromises = apiResponse.resolved_promises || [];
    const resolvedCount = apiResponse.resolved_count || 0;
    
    return {
        promises: processedPromises,
        resolved_promises: resolvedPromises,
        resolved_count: resolvedCount,
        has_new_promises: processedPromises.length > 0,
        has_resolved_promises: resolvedCount > 0,
        raw_response: apiResponse
    };
}

// Export functions for use in other modules
window.PromiseKeeperTypes = {
    parsePotentialActions,
    parseExtractionData,
    parsePromiseWithActions,
    parsePromisesWithActions,
    isValidPromiseListResponse,
    extractPotentialActions,
    createDisplayPromise,
    processApiResponse,
    // MCP Action utilities
    isMCPAction,
    categorizeActions,
    getMCPActionDescription,
    getActionIcon
}; 