import { app, BrowserWindow, Tray, Menu, nativeImage, ipcMain, Notification, globalShortcut } from 'electron';
import * as path from 'path';
import Store from 'electron-store';
import { createTrayIcon } from './create-tray-icon';

const store = new Store();

class PromiseKeeperApp {
  private mainWindow: BrowserWindow | null = null;
  private tray: Tray | null = null;
  private isQuitting = false;
  private hasActiveNotification = false;
  private activeNotification: Notification | null = null;

  constructor() {
    this.setupApp();
  }

  private setupApp() {
    // Handle app ready
    app.whenReady().then(() => {
      this.createWindow();
      this.createTray();
      this.setupIPC();
      this.setupGlobalShortcuts();
    });

    // Handle window close
    app.on('window-all-closed', () => {
      if (process.platform !== 'darwin') {
        app.quit();
      }
    });

    app.on('activate', () => {
      if (BrowserWindow.getAllWindows().length === 0) {
        this.createWindow();
      }
    });

    app.on('before-quit', () => {
      this.isQuitting = true;
      // Unregister all shortcuts
      globalShortcut.unregisterAll();
    });

    app.on('will-quit', () => {
      // Unregister all shortcuts
      globalShortcut.unregisterAll();
    });
  }

  private setupGlobalShortcuts() {
    // Register Tab shortcut
    globalShortcut.register('Tab', () => {
      if (this.hasActiveNotification) {
        // Close the notification if it exists
        if (this.activeNotification) {
          this.activeNotification.close();
          this.activeNotification = null;
        }
        this.showWindow();
        // Reset the active notification flag
        this.hasActiveNotification = false;
      }
    });
  }

  private createWindow() {
    this.mainWindow = new BrowserWindow({
      width: 400,
      height: 600,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: path.join(__dirname, 'preload.js')
      },
      show: false,
      frame: true,
      resizable: true,
      skipTaskbar: false,
      title: 'Promise Keeper'
    });

    // Load the HTML file
    this.mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));

    // Show window when ready
    this.mainWindow.once('ready-to-show', () => {
      this.mainWindow?.show();
    });

    // Handle window close - hide instead of quit
    this.mainWindow.on('close', (event) => {
      if (!this.isQuitting) {
        event.preventDefault();
        this.mainWindow?.hide();
      }
    });

    // Open DevTools in development
    if (process.argv.includes('--dev')) {
      this.mainWindow.webContents.openDevTools();
    }
  }

  private createTray() {
    try {
      // Create tray icon
      const trayIcon = createTrayIcon();
      
      this.tray = new Tray(trayIcon);
      console.log('System tray created successfully');
    
      // Create tray menu
      const contextMenu = Menu.buildFromTemplate([
        {
          label: 'Show Promise Keeper',
          click: () => {
            this.showWindow();
          }
        },
        {
          label: 'Add Promise',
          click: () => {
            this.showWindow();
            this.mainWindow?.webContents.send('focus-input');
          }
        },
        { type: 'separator' },
        {
          label: 'Quit',
          click: () => {
            this.isQuitting = true;
            app.quit();
          }
        }
      ]);

      this.tray.setContextMenu(contextMenu);
      this.tray.setToolTip('Promise Keeper');
    
      // Handle tray click
      this.tray.on('click', () => {
        this.toggleWindow();
      });
        
    } catch (error) {
      console.error('Failed to create system tray:', error);
    }
  }

  private showWindow() {
    if (this.mainWindow) {
      if (this.mainWindow.isMinimized()) {
        this.mainWindow.restore();
      }
      this.mainWindow.show();
      this.mainWindow.focus();
    }
  }

  private toggleWindow() {
    if (this.mainWindow) {
      if (this.mainWindow.isVisible()) {
        this.mainWindow.hide();
      } else {
        this.showWindow();
      }
    }
  }

  private setupIPC() {
    // Handle store operations
    ipcMain.handle('store-get', (_, key: string) => {
      return store.get(key);
    });

    ipcMain.handle('store-set', (_, key: string, value: any) => {
      store.set(key, value);
    });

    ipcMain.handle('store-delete', (_, key: string) => {
      store.delete(key);
    });

    // Handle window operations
    ipcMain.handle('minimize-window', () => {
      this.mainWindow?.minimize();
    });

    ipcMain.handle('hide-window', () => {
      this.mainWindow?.hide();
    });

    ipcMain.handle('quit-app', () => {
      this.isQuitting = true;
      app.quit();
    });

    // Handle notifications
    ipcMain.handle('show-notification', (_, { title, body }) => {
      if (Notification.isSupported()) {
        // Close any existing notification
        if (this.activeNotification) {
          this.activeNotification.close();
        }

        const notification = new Notification({
          title,
          body,
          silent: false
        });

        // Store reference to active notification
        this.activeNotification = notification;

        // Set active notification flag
        this.hasActiveNotification = true;

        // Handle notification close
        notification.on('close', () => {
          this.hasActiveNotification = false;
          this.activeNotification = null;
        });

        // Handle notification click
        notification.on('click', () => {
          this.showWindow();
          this.hasActiveNotification = false;
          this.activeNotification = null;
        });

        notification.show();
      }
    });
  }
}

// Create the app instance
new PromiseKeeperApp(); 