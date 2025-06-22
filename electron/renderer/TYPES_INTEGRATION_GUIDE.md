# TypeScript Types Integration Guide

This guide explains how to use the new TypeScript types and utilities to properly parse API responses that include potential actions.

## Files Structure

```
electron/
├── src/types/api.ts          # TypeScript type definitions
├── renderer/types-utils.js   # JavaScript utilities for runtime parsing
├── renderer/screenshots-example.js  # Example of how to integrate the utilities
└── renderer/index.html       # Updated to include types-utils.js
```

## What's New

The API now returns `potential_actions` for each extracted promise. Here's the response structure:

```json
{
  "promises": [
    {
      "content": "I will complete the project by Friday",
      "to_whom": "John",
      "deadline": "2024-01-19",
      "potential_actions": [
        {
          "action": "Create calendar reminder",
          "description": "Set up a reminder 2 days before the deadline"
        },
        {
          "action": "Send progress update",
          "description": "Email John with current progress"
        }
      ]
    }
  ],
  "resolved_promises": [],
  "resolved_count": 0
}
```

## How to Use the Types Utilities

### 1. Basic Response Processing

Replace your existing API response handling with:

```javascript
// OLD WAY
const result = await apiResponse.json();
console.log('API Response:', result);

// NEW WAY
const rawResult = await apiResponse.json();
const processedResult = window.PromiseKeeperTypes.processApiResponse(rawResult);

console.log('Processed result:', processedResult);
console.log('Raw API response:', processedResult.raw_response);
```

### 2. Access Potential Actions

```javascript
// Check if promises have actions
if (processedResult.has_new_promises) {
    processedResult.promises.forEach((promise, index) => {
        console.log(`Promise ${index + 1}: ${promise.content}`);
        
        if (promise.has_actions) {
            console.log(`  Actions available: ${promise.potential_actions.length}`);
            promise.potential_actions.forEach((action, actionIndex) => {
                console.log(`    ${actionIndex + 1}. ${action.action}: ${action.description}`);
            });
        }
    });
}
```

### 3. Parse Database Promises

When loading promises from the database, use the parsing utilities:

```javascript
// In promises.js loadPromises method
const { data, error } = await window.PromiseKeeperConfig.supabaseClient
    .from('promises')
    .select('*')
    .eq('owner_id', this.app.currentUser.id)
    .order('created_at', { ascending: false });

if (!error && data) {
    // Parse potential actions from JSON strings
    this.promises = window.PromiseKeeperTypes.parsePromisesWithActions(data);
    this.renderPromises();
}
```

### 4. Display Potential Actions in UI

Update your `renderPromises` method to show potential actions:

```javascript
renderPromises() {
    const container = document.getElementById('promisesList');
    
    if (this.promises.length === 0) {
        container.innerHTML = '<div class="no-promises">No promises yet. Add your first promise above!</div>';
        return;
    }

    container.innerHTML = this.promises.map(promise => {
        const isFromScreenshot = promise.extracted_from_screenshot && promise.screenshot_id;
        const isResolved = promise.resolved;
        
        // Parse potential actions
        const parsedPromise = window.PromiseKeeperTypes.parsePromiseWithActions(promise);
        const hasActions = parsedPromise.potential_actions_parsed && parsedPromise.potential_actions_parsed.length > 0;
        
        // Create actions HTML
        const actionsHtml = hasActions ? `
            <div class="promise-actions">
                <div class="actions-header">Suggested Actions:</div>
                <ul class="actions-list">
                    ${parsedPromise.potential_actions_parsed.map(action => `
                        <li class="action-item">
                            <strong>${this.escapeHtml(action.action)}</strong>
                            <span class="action-description">${this.escapeHtml(action.description)}</span>
                        </li>
                    `).join('')}
                </ul>
            </div>
        ` : '';
        
        // ... rest of your existing rendering code ...
        
        return `
            <div class="${promiseItemClasses}">
                <div class="promise-content">${this.escapeHtml(promise.content)}</div>
                ${actionsHtml}
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
```

## Available Utility Functions

### `window.PromiseKeeperTypes` Functions

- **`processApiResponse(apiResponse)`**: Main function to process API responses
- **`parsePromiseWithActions(promise)`**: Parse a single database promise
- **`parsePromisesWithActions(promises)`**: Parse an array of database promises
- **`extractPotentialActions(extractedPromise)`**: Get actions from an extracted promise
- **`createDisplayPromise(extractedPromise)`**: Create a display-ready promise object
- **`isValidPromiseListResponse(response)`**: Validate API response format

### Response Object Structure

When you use `processApiResponse()`, you get:

```javascript
{
    promises: [/* Array of display-ready promises with potential_actions */],
    resolved_promises: [/* Array of resolved promises */],
    resolved_count: 0,
    has_new_promises: false,
    has_resolved_promises: false,
    raw_response: {/* Original API response */}
}
```

Each promise in the `promises` array has:

```javascript
{
    content: "Enhanced content with to_whom and deadline",
    original_content: "Original promise content",
    to_whom: "Person or entity",
    deadline: "Deadline if specified",
    potential_actions: [/* Array of action objects */],
    has_actions: true  // Boolean indicator
}
```

## Integration Steps

1. **Include the utilities**: The `types-utils.js` is already added to `index.html`

2. **Update API response handling**: Replace direct API response usage with `processApiResponse()`

3. **Update database promise handling**: Use `parsePromisesWithActions()` when loading from database

4. **Update UI rendering**: Add potential actions display to your UI

5. **Update notifications**: Include actions count in notifications

## CSS for Actions Display

Add this CSS to your `index.html` for styling the actions:

```css
.promise-actions {
    margin-top: 8px;
    padding: 8px 12px;
    background: rgba(102, 126, 234, 0.05);
    border-radius: 6px;
    border-left: 3px solid #667eea;
}

.actions-header {
    font-size: 12px;
    font-weight: 600;
    color: #667eea;
    margin-bottom: 6px;
}

.actions-list {
    margin: 0;
    padding: 0;
    list-style: none;
}

.action-item {
    margin-bottom: 4px;
    font-size: 12px;
}

.action-item strong {
    color: #333;
    display: block;
}

.action-description {
    color: #666;
    font-style: italic;
    margin-left: 8px;
}
```

## Example Implementation

Check `screenshots-example.js` for complete examples of how to integrate these utilities into your existing code.

## TypeScript Development

If you want to add more TypeScript files to your project:

1. Create `.ts` files in the `src/` directory
2. Import types from `src/types/api.ts`
3. Compile with `tsc` (TypeScript is already configured in `tsconfig.json`)
4. Reference compiled `.js` files in your HTML

The types are designed to be forward-compatible, so adding new fields to the API response won't break existing code. 