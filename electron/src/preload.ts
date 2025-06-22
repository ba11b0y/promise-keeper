import { contextBridge, ipcRenderer } from 'electron';

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
  // Environment variables
  env: {
    API_BASE_URL_OVERRIDE: process.env.API_BASE_URL_OVERRIDE
  },
  // Store operations
  store: {
    get: (key: string) => ipcRenderer.invoke('store-get', key),
    set: (key: string, value: any) => ipcRenderer.invoke('store-set', key, value),
    delete: (key: string) => ipcRenderer.invoke('store-delete', key)
  },
  
  // Window operations
  window: {
    minimize: () => ipcRenderer.invoke('minimize-window'),
    hide: () => ipcRenderer.invoke('hide-window'),
    quit: () => ipcRenderer.invoke('quit-app')
  },

  // Notification operations
  notifications: {
    show: (title: string, body: string) => ipcRenderer.invoke('show-notification', { title, body })
  },

  // File operations
  files: {
    showFilePicker: () => ipcRenderer.invoke('show-file-picker'),
    openScreenshot: (screenshotId: string) => ipcRenderer.invoke('open-screenshot', screenshotId)
  },

  // Screenshot operations
  screenshots: {
    savePromiseScreenshot: (screenshotId: string, promises: any[]) => 
      ipcRenderer.invoke('save-promise-screenshot', { screenshotId, promises }),
    getScreenshotPath: (screenshotId: string) =>
      ipcRenderer.invoke('get-screenshot-path', screenshotId),
    takeScreenshotNow: () => ipcRenderer.invoke('take-screenshot-now'),
    setScreenshotMode: (mode: 'off' | 'interval' | 'enter') => 
      ipcRenderer.invoke('set-screenshot-mode', mode)
  },

  // MCP operations
  mcp: {
    contacts: {
      search: (name?: string) => ipcRenderer.invoke('mcp-contacts-search', name)
    },
    notes: {
      create: (title: string, body: string, folderName?: string) =>
        ipcRenderer.invoke('mcp-notes-create', { title, body, folderName })
    },
    messages: {
      send: (phoneNumber: string, message: string) =>
        ipcRenderer.invoke('mcp-messages-send', { phoneNumber, message })
    },
    calendar: {
      search: (searchText: string) => ipcRenderer.invoke('mcp-calendar-search', searchText)
    },
    reminders: {
      create: (name: string, listName?: string, notes?: string, dueDate?: string) =>
        ipcRenderer.invoke('mcp-reminders-create', { name, listName, notes, dueDate })
    }
  },

  // Listen for events from main process
  onFocusInput: (callback: () => void) => {
    ipcRenderer.on('focus-input', callback);
  },

  // Listen for screenshot processing requests from main process
  onProcessScreenshotForPromises: (callback: (data: any) => void) => {
    ipcRenderer.on('process-screenshot-for-promises', (_, data) => callback(data));
  },

  // Remove listeners
  removeAllListeners: (channel: string) => {
    ipcRenderer.removeAllListeners(channel);
  }
});

// Type definitions for the exposed API
export interface ElectronAPI {
  env: {
    API_BASE_URL_OVERRIDE?: string;
  };
  store: {
    get: (key: string) => Promise<any>;
    set: (key: string, value: any) => Promise<void>;
    delete: (key: string) => Promise<void>;
  };
  window: {
    minimize: () => Promise<void>;
    hide: () => Promise<void>;
    quit: () => Promise<void>;
  };
  notifications: {
    show: (title: string, body: string) => Promise<void>;
  };
  files: {
    showFilePicker: () => Promise<string | null>;
    openScreenshot: (screenshotId: string) => Promise<void>;
  };
  screenshots: {
    savePromiseScreenshot: (screenshotId: string, promises: any[]) => Promise<string>;
    getScreenshotPath: (screenshotId: string) => Promise<string>;
    takeScreenshotNow: () => Promise<void>;
    setScreenshotMode: (mode: 'off' | 'interval' | 'enter') => Promise<void>;
  };
  mcp: {
    contacts: {
      search: (name?: string) => Promise<any>;
    };
    notes: {
      create: (title: string, body: string, folderName?: string) => Promise<any>;
    };
    messages: {
      send: (phoneNumber: string, message: string) => Promise<any>;
    };
    calendar: {
      search: (searchText: string) => Promise<any>;
    };
    reminders: {
      create: (name: string, listName?: string, notes?: string, dueDate?: string) => Promise<any>;
    };
  };
  onFocusInput: (callback: () => void) => void;
  onProcessScreenshotForPromises: (callback: (data: any) => void) => void;
  removeAllListeners: (channel: string) => void;
}

declare global {
  interface Window {
    electronAPI: ElectronAPI;
  }
} 