import { app, BrowserWindow, Tray, Menu, nativeImage, ipcMain, Notification, desktopCapturer, dialog } from 'electron';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';
import Store from 'electron-store';
import { createTrayIcon } from './create-tray-icon';
import * as dotenv from 'dotenv';
import { mcpClient } from './services/mcp-client';

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
  private apiBaseUrl = process.env.API_BASE_URL_OVERRIDE || "https://promise-keeper-api-red-sunset-2072.fly.dev";

  constructor() {
    this.setupApp();
  }

  private setupApp() {
    // Handle app ready
    app.whenReady().then(async () => {
      try {
        await mcpClient.initialize();
        this.createWindow();
        this.createTray();
        this.setupIPC();
        this.startScreenshots();
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
      await mcpClient.cleanup();
    });
  }

  private createWindow() {
    this.mainWindow = new BrowserWindow({
      width: 400,
      height: 600,
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
      frame: true,
      resizable: true,
      skipTaskbar: false,
      title: 'Promise Keeper'
    });

    // Load the HTML file
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
        const notification = new Notification({
          title,
          body,
          silent: false
        });

        notification.on('click', () => {
          this.showWindow();
        });

        notification.show();
      }
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
    ipcMain.handle('mcp-contacts-search', async (_, name?: string) => {
      return mcpClient.searchContacts(name);
    });

    ipcMain.handle('mcp-notes-create', async (_, { title, body, folderName }: { title: string; body: string; folderName?: string }) => {
      return mcpClient.createNote(title, body, folderName);
    });

    ipcMain.handle('mcp-messages-send', async (_, { phoneNumber, message }: { phoneNumber: string; message: string }) => {
      return mcpClient.sendMessage(phoneNumber, message);
    });

    ipcMain.handle('mcp-calendar-search', async (_, searchText: string) => {
      return mcpClient.searchCalendar(searchText);
    });

    ipcMain.handle('mcp-reminders-create', async (_, { name, listName, notes, dueDate }: { name: string; listName?: string; notes?: string; dueDate?: string }) => {
      return mcpClient.createReminder(name, listName, notes, dueDate);
    });

    // Handle manual screenshot requests
    ipcMain.handle('take-screenshot-now', () => {
      this.takeScreenshotAndProcess();
    });
  }

  private startScreenshots() {
    if (!fs.existsSync(this.screenshotDir)) fs.mkdirSync(this.screenshotDir, { recursive: true });
    if (!fs.existsSync(this.promiseScreenshotsDir)) fs.mkdirSync(this.promiseScreenshotsDir, { recursive: true });
    this.screenshotInterval = setInterval(() => this.takeScreenshotAndProcess(), 30000);
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
    if (Notification.isSupported()) {
      const notification = new Notification({
        title: 'Promise Keeper',
        body: `Found ${count} promise${count > 1 ? 's' : ''} in your screen!`,
        silent: false,
        icon: createTrayIcon() // Use the same icon as tray
      });

      notification.on('click', () => {
        this.showWindow();
      });

      notification.show();
    }
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