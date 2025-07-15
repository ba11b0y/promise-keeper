// Types for Promise Keeper API responses

// Base interface for all potential actions
export interface PotentialAction {
  action: string;
  description: string;
  [key: string]: any; // Allow for additional properties
}

// Specific MCP tool action types
export interface Messages_MCP_Call {
  tool_name: "messages_compose_message";
  recipient: string;
  body: string;
  action?: string;
  description?: string;
}

export interface System_Launch_App {
  tool_name: "system_launch_app";
  name: string;
  action?: string;
  description?: string;
}

export interface Calendar_Add {
  tool_name: "calendar_add";
  title: string;
  startDate: string;
  endDate: string;
  action?: string;
  description?: string;
}

// Union type for all known MCP actions
export type MCPAction = Messages_MCP_Call | System_Launch_App | Calendar_Add;

// Enhanced potential action that can be either a generic action or a specific MCP action
export type EnhancedPotentialAction = PotentialAction | MCPAction;

// Type guard functions
export const isMessages_MCP_Call = (action: any): action is Messages_MCP_Call => {
  return action && action.tool_name === "messages_compose_message";
};

export const isSystem_Launch_App = (action: any): action is System_Launch_App => {
  return action && action.tool_name === "system_launch_app";
};

export const isCalendar_Add = (action: any): action is Calendar_Add => {
  return action && action.tool_name === "calendar_add";
};

export const isMCPAction = (action: any): action is MCPAction => {
  return isMessages_MCP_Call(action) || isSystem_Launch_App(action) || isCalendar_Add(action);
};

export interface ExtractedPromise {
  content: string;
  to_whom?: string;
  deadline?: string;
  platform?: string;
  potential_actions: EnhancedPotentialAction[];
}

export interface ResolvedPromise {
  content: string;
  to_whom?: string;
  deadline?: string;
  platform?: string;
  resolution_reasoning?: string;
  resolution_evidence?: string;
}

export interface PromiseListResponse {
  promises: ExtractedPromise[];
  resolved_promises?: ResolvedPromise[];
  resolved_count?: number;
}

export interface BasicPromiseResponse {
  promise: string;
}

// Database Promise types (what gets stored in Supabase)
export interface DatabasePromise {
  id: number;
  content: string;
  owner_id: string;
  created_at: string;
  updated_at?: string;
  resolved: boolean;
  resolved_screenshot_id?: string;
  resolved_screenshot_time?: string;
  resolved_reason?: string;
  extracted_from_screenshot: boolean;
  screenshot_id?: string;
  screenshot_timestamp?: string;
  extraction_data?: string; // JSON string
  potential_actions?: string; // JSON string of EnhancedPotentialAction[]
  metadata?: string; // JSON string
  action?: string; // JSON string of Action
  due_date?: string; // ISO date string
  person?: string; // Who the promise was made to
  platform?: string; // Where the promise was made (Messages, Discord, Slack, etc.)
}

// Parsed versions of database fields
export interface ParsedExtractionData {
  original_promise?: any;
  to_whom?: string;
  deadline?: string;
  platform?: string;
  raw_promise?: string;
}

// Formatted promise for notifications
export interface FormattedPromise {
  title: string;
  body: string;
  details?: string;
}

export interface ParsedPromiseWithActions extends Omit<DatabasePromise, 'potential_actions' | 'extraction_data'> {
  potential_actions_parsed?: EnhancedPotentialAction[];
  extraction_data_parsed?: ParsedExtractionData;
}

// Utility functions for parsing JSON fields
export const parsePromiseActions = (promise: DatabasePromise): ParsedPromiseWithActions => {
  const parsed: ParsedPromiseWithActions = { ...promise };
  
  try {
    if (promise.potential_actions) {
      parsed.potential_actions_parsed = JSON.parse(promise.potential_actions);
    }
  } catch (error) {
    console.error('Failed to parse potential_actions:', error);
    parsed.potential_actions_parsed = [];
  }
  
  try {
    if (promise.extraction_data) {
      parsed.extraction_data_parsed = JSON.parse(promise.extraction_data);
    }
  } catch (error) {
    console.error('Failed to parse extraction_data:', error);
    parsed.extraction_data_parsed = {};
  }
  
  return parsed;
};

export const parsePromisesWithActions = (promises: DatabasePromise[]): ParsedPromiseWithActions[] => {
  return promises.map(parsePromiseActions);
}; 