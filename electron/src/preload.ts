import { contextBridge, ipcRenderer } from 'electron';

// Expose protected methods that allow the renderer process to use
// the ipcRenderer without exposing the entire object
contextBridge.exposeInMainWorld('electronAPI', {
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

  // Listen for events from main process
  onFocusInput: (callback: () => void) => {
    ipcRenderer.on('focus-input', callback);
  },

  // Remove listeners
  removeAllListeners: (channel: string) => {
    ipcRenderer.removeAllListeners(channel);
  }
});

// Type definitions for the exposed API
export interface ElectronAPI {
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
  onFocusInput: (callback: () => void) => void;
  removeAllListeners: (channel: string) => void;
}

declare global {
  interface Window {
    electronAPI: ElectronAPI;
  }
} 