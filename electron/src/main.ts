import { app, BrowserWindow, Tray, Menu, nativeImage, ipcMain, Notification, desktopCapturer, dialog, globalShortcut } from 'electron';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';
const Store = require('electron-store');
import { createTrayIcon } from './create-tray-icon';
import * as dotenv from 'dotenv';
import { mcpClient } from './services/mcp-client';
import { NotificationManager } from './services/notification-manager';

// Import uiohook-napi for global key listening
const { uIOhook, UiohookKey } = require('uiohook-napi');

// Load environment variables from .env.local file
dotenv.config({ path: path.join(__dirname, '../.env.local') });

const store = new Store();

class PromiseKeeperApp {
  private mainWindow: BrowserWindow | null = null;
  private tray: Tray | null = null;
  private isQuitting = false;
  private screenshotDir = path.join(os.homedir(), 'Documents', 'Screenshots');
  private promiseScreenshotsDir = path.join(os.homedir(), 'Documents', 'PromiseKeeper', 'PromiseScreenshots');
  private screenshotInterval: NodeJS.Timeout | null = null;
  private screenshotMode: 'off' | 'interval' | 'enter' = 'enter';
  private lastGlobalEnterTime: number = 0;
  private globalEnterCooldown: number = 60000; // 1 minute cooldown for global enter
  private globalKeyListener: boolean = false;
  private apiBaseUrl = process.env.API_BASE_URL_OVERRIDE || "https://promise-keeper-api-red-sunset-2072.fly.dev";
  private notificationManager: NotificationManager;

  constructor() {
    this.notificationManager = NotificationManager.getInstance();
    this.setupApp();
  }

  private setupApp() {
    // Handle app ready
    app.whenReady().then(async () => {
      try {
        await mcpClient.initialize();
        
        // CRITICAL: Set up IPC handlers FIRST before any window creation
        this.setupIPC();
        console.log('IPC handlers registered');
        
        // Now create window and other components
        this.createWindow();
        this.createTray();
        this.startScreenshots();
        this.setupGlobalShortcuts();
      } catch (error) {
        console.error('Failed to initialize app:', error);
      }
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

    app.on('before-quit', async () => {
      this.isQuitting = true;
      if (this.screenshotInterval) clearInterval(this.screenshotInterval);
      // Unregister all shortcuts
      globalShortcut.unregisterAll();
      // Stop global key listener
      this.stopGlobalKeyListener();
      await mcpClient.cleanup();
    });
  }

  private setupGlobalShortcuts() {
    // First unregister any existing shortcuts to avoid conflicts
    globalShortcut.unregisterAll();

    // Use Command+Shift+T on macOS, Control+Shift+T on Windows/Linux
    const shortcutKey = process.platform === 'darwin' ? 'Command+Shift+T' : 'Control+Shift+T';

    // Register the notification shortcut
    const success = globalShortcut.register(shortcutKey, () => {
      console.log('Notification shortcut pressed');
      this.notificationManager.handleTabPress();
    });

    if (!success) {
      console.error(`Failed to register ${shortcutKey} shortcut`);
    } else {
      console.log(`${shortcutKey} shortcut registered successfully`);
    }

         // Setup global key listener for Enter key monitoring
     this.setupGlobalKeyListener();
  }

  private createWindow() {
    this.mainWindow = new BrowserWindow({
      width: 500,
      height: 800,
      webPreferences: {
        nodeIntegration: false,
        contextIsolation: true,
        preload: path.join(__dirname, 'preload.js'),
        // Enable media access permissions
        webSecurity: true,
        allowRunningInsecureContent: false,
        experimentalFeatures: true
      },
      show: false,
      frame: false,
      transparent: true,
      vibrancy: 'fullscreen-ui',
      resizable: true,
      skipTaskbar: false,
      title: 'Promise Keeper',
      titleBarStyle: 'hidden',
      backgroundColor: '#00000000'
    });

    // Load the React app HTML file
    this.mainWindow.loadFile(path.join(__dirname, '../renderer/index.html'));

    // Handle media permissions
    this.mainWindow.webContents.session.setPermissionRequestHandler(
      (webContents, permission, callback) => {
        const allowedPermissions = ['camera', 'microphone', 'display-capture'];
        
        if (allowedPermissions.includes(permission)) {
          callback(true); // Allow the permission
        } else {
          callback(false); // Deny the permission
        }
      }
    );

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

    // After window creation
    if (this.mainWindow) {
      this.notificationManager.setMainWindow(this.mainWindow);
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
    ipcMain.handle('show-notification', (_, { title, body, metadata }) => {
      console.log('IPC: Showing notification:', { title, body, metadata });
      this.notificationManager.showNotification(title, body, metadata ?? {}, () => {
        this.showWindow();
      });
    });

    // Handle file picker
    ipcMain.handle('show-file-picker', async () => {
      if (!this.mainWindow) return null;
      
      const result = await dialog.showOpenDialog(this.mainWindow, {
        properties: ['openFile'],
        filters: [
          { name: 'Images', extensions: ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'] },
          { name: 'All Files', extensions: ['*'] }
        ]
      });

      if (result.canceled || result.filePaths.length === 0) {
        return null;
      }

      return result.filePaths[0];
    });

    // Handle saving promise screenshots
    ipcMain.handle('save-promise-screenshot', (_, { screenshotId, promises }) => {
      return this.savePromiseScreenshot(screenshotId, promises);
    });

    // Handle getting screenshot paths for viewing
    ipcMain.handle('get-screenshot-path', (_, screenshotId) => {
      return this.getScreenshotPath(screenshotId);
    });

    // Add MCP IPC handlers
    ipcMain.handle('mcp-messages-list-chats', async (_, { includeParticipantDetails }: { includeParticipantDetails?: boolean }) => {
      return mcpClient.listChats(includeParticipantDetails);
    });

    ipcMain.handle('mcp-messages-get', async (_, { limit }: { limit?: number }) => {
      return mcpClient.getMessages(limit);
    });

    ipcMain.handle('mcp-messages-search', async (_, { searchText, sender, chatId, limit, daysBack }: { searchText: string; sender?: string; chatId?: string; limit?: number; daysBack?: number }) => {
      return mcpClient.searchMessages(searchText, sender, chatId, limit, daysBack);
    });

    ipcMain.handle('mcp-messages-send', async (_, { recipient, body, auto }: { recipient: string; body?: string; auto?: boolean }) => {
      return mcpClient.sendMessage(recipient, body, auto);
    });

    ipcMain.handle('mcp-system-launch-app', async (_, { appName }: { appName: string }) => {
      return mcpClient.launchApp(appName);
    });

    // Handle manual screenshot requests
    ipcMain.handle('take-screenshot-now', () => {
      this.takeScreenshotAndProcess();
    });

    // Handle screenshot mode changes
    ipcMain.handle('set-screenshot-mode', (_, mode: 'off' | 'interval' | 'enter') => {
      try {
        this.setScreenshotMode(mode);
        return { success: true };
      } catch (error) {
        console.error('Error setting screenshot mode:', error);
        return { success: false, error: error instanceof Error ? error.message : String(error) };
      }
    });
  }

  private startScreenshots() {
    if (!fs.existsSync(this.screenshotDir)) fs.mkdirSync(this.screenshotDir, { recursive: true });
    if (!fs.existsSync(this.promiseScreenshotsDir)) fs.mkdirSync(this.promiseScreenshotsDir, { recursive: true });
    // Don't start interval by default - wait for mode to be set
  }

  private setScreenshotMode(mode: 'off' | 'interval' | 'enter') {
    this.screenshotMode = mode;
    console.log('Screenshot mode set to:', mode);
    
    // Clear existing interval
    if (this.screenshotInterval) {
      clearInterval(this.screenshotInterval);
      this.screenshotInterval = null;
    }
    
    // Start interval if mode is 'interval'
    if (mode === 'interval') {
      this.screenshotInterval = setInterval(() => this.takeScreenshotAndProcess(), 30000);
      console.log('Started 30-second screenshot interval');
    }
    
    // Global key listener is always running, mode just determines if we act on Enter presses
  }

  private setupGlobalKeyListener() {
    if (this.globalKeyListener) return;
    
    try {
             // Register keydown event listener
       uIOhook.on('keydown', (e: any) => {
         // Check if it's the Enter key (Return key)
         if (e.keycode === UiohookKey.Enter) {
           this.handleGlobalEnterPress();
         }
       });

      // Start the global key listener
      uIOhook.start();
      this.globalKeyListener = true;
      console.log('Global key listener started successfully');
    } catch (error) {
      console.error('Failed to start global key listener:', error);
    }
  }

  private stopGlobalKeyListener() {
    if (!this.globalKeyListener) return;
    
    try {
      uIOhook.stop();
      this.globalKeyListener = false;
      console.log('Global key listener stopped');
    } catch (error) {
      console.error('Failed to stop global key listener:', error);
    }
  }

  private handleGlobalEnterPress() {
    // Only process if we're in 'enter' mode
    if (this.screenshotMode !== 'enter') {
      return;
    }

    const now = Date.now();
    
    // Rate limiting to prevent spam
    if (now - this.lastGlobalEnterTime < this.globalEnterCooldown) {
      console.log('Global Enter screenshot skipped: cooldown active');
      return;
    }
    
    this.lastGlobalEnterTime = now;
    console.log('Global Enter key detected - taking screenshot');
    this.takeScreenshotAndProcess();
  }

  private async takeScreenshotAndProcess() {
    try {
      const sources = await desktopCapturer.getSources({ 
        types: ['screen'], 
        thumbnailSize: { width: 1920, height: 1080 } 
      });
      
      if (sources[0]) {
        const screenshot = sources[0].thumbnail.toPNG();
        const timestamp = Date.now();
        const screenshotId = `screenshot_${timestamp}`;
        const filename = `${screenshotId}.png`;
        const screenshotPath = path.join(this.screenshotDir, filename);
        
        // Save screenshot locally (for backup/debugging)
        fs.writeFileSync(screenshotPath, screenshot);
        
        // Send screenshot to renderer process for API processing
        // Include the screenshotId so we can track it if promises are found
        if (this.mainWindow) {
          this.mainWindow.webContents.send('process-screenshot-for-promises', {
            buffer: screenshot,
            filename: filename,
            screenshotId: screenshotId,
            timestamp: timestamp
          });
        }
        
        // Clean up old screenshots (but not promise screenshots)
        this.cleanupScreenshots();
      }
    } catch (err) { 
      console.error('Screenshot failed:', err); 
    }
  }

  private savePromiseScreenshot(screenshotId: string, promises: any[]): string {
    try {
      const sourceFilename = `${screenshotId}.png`;
      const sourcePath = path.join(this.screenshotDir, sourceFilename);
      
      if (!fs.existsSync(sourcePath)) {
        console.error('Source screenshot not found:', sourcePath);
        return '';
      }

      // Create a unique filename for the promise screenshot
      const promiseFilename = `${screenshotId}_promises.png`;
      const promisePath = path.join(this.promiseScreenshotsDir, promiseFilename);
      
      // Copy the screenshot to the promise screenshots directory
      fs.copyFileSync(sourcePath, promisePath);
      
      // Create metadata file
      const metadataPath = path.join(this.promiseScreenshotsDir, `${screenshotId}_metadata.json`);
      const metadata = {
        screenshotId,
        timestamp: new Date().toISOString(),
        originalFilename: sourceFilename,
        promiseFilename: promiseFilename,
        promises: promises.map(p => ({
          content: p.content,
          to_whom: p.to_whom,
          deadline: p.deadline
        })),
        promiseCount: promises.length
      };
      
      fs.writeFileSync(metadataPath, JSON.stringify(metadata, null, 2));
      
      console.log(`Saved promise screenshot: ${promisePath}`);
      console.log(`Saved metadata: ${metadataPath}`);
      
      return promisePath;
    } catch (error) {
      console.error('Failed to save promise screenshot:', error);
      return '';
    }
  }

  private showPromiseFoundNotification(count: number) {
    console.log('Showing promise found notification for', count, 'promises');

    this.notificationManager.showNotification(
      'Promise Keeper',
      `Found ${count} promise${count > 1 ? 's' : ''} in your screen!`,
      {},
      () => {
        console.log('Notification clicked, showing window');
        this.showWindow();
      }
    );
  }

  private cleanupScreenshots() {
    try {
      const files = fs.readdirSync(this.screenshotDir).filter(f => f.endsWith('.png')).map(f => ({ name: f, time: fs.statSync(path.join(this.screenshotDir, f)).mtime })).sort((a, b) => b.time.getTime() - a.time.getTime());
      files.slice(100).forEach(f => fs.unlinkSync(path.join(this.screenshotDir, f.name)));
    } catch (err) { console.error('Cleanup failed:', err); }
  }

  private getScreenshotPath(screenshotId: string): string {
    try {
      const promiseFilename = `${screenshotId}_promises.png`;
      const promisePath = path.join(this.promiseScreenshotsDir, promiseFilename);
      
      if (fs.existsSync(promisePath)) {
        return promisePath;
      }
      
      // Fallback to regular screenshot if promise screenshot doesn't exist
      const regularFilename = `${screenshotId}.png`;
      const regularPath = path.join(this.screenshotDir, regularFilename);
      
      if (fs.existsSync(regularPath)) {
        return regularPath;
      }
      
      return '';
    } catch (error) {
      console.error('Failed to get screenshot path:', error);
      return '';
    }
  }
}

// Create the app instance
new PromiseKeeperApp(); 