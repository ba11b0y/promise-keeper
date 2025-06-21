import { app, BrowserWindow, Tray, Menu, nativeImage, ipcMain, Notification, desktopCapturer, dialog } from 'electron';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';
import Store from 'electron-store';
import { createTrayIcon } from './create-tray-icon';
import * as dotenv from 'dotenv';

// Load environment variables from .env.local file
dotenv.config({ path: path.join(__dirname, '../.env.local') });

const store = new Store();

class PromiseKeeperApp {
  private mainWindow: BrowserWindow | null = null;
  private tray: Tray | null = null;
  private isQuitting = false;
  private screenshotDir = path.join(os.homedir(), 'Documents', 'Screenshots');
  private screenshotInterval: NodeJS.Timeout | null = null;

  constructor() {
    this.setupApp();
  }

  private setupApp() {
    // Handle app ready
    app.whenReady().then(() => {
      this.createWindow();
      this.createTray();
      this.setupIPC();
      this.startScreenshots();
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
      if (this.screenshotInterval) clearInterval(this.screenshotInterval);
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
  }

  private startScreenshots() {
    if (!fs.existsSync(this.screenshotDir)) fs.mkdirSync(this.screenshotDir, { recursive: true });
    this.screenshotInterval = setInterval(() => this.takeScreenshot(), 5000);
  }

  private async takeScreenshot() {
    try {
      const sources = await desktopCapturer.getSources({ types: ['screen'], thumbnailSize: { width: 1920, height: 1080 } });
      if (sources[0]) {
        const screenshot = sources[0].thumbnail.toPNG();
        const filename = `screenshot_${Date.now()}.png`;
        fs.writeFileSync(path.join(this.screenshotDir, filename), screenshot);
        this.cleanupScreenshots();
      }
    } catch (err) { console.error('Screenshot failed:', err); }
  }

  private cleanupScreenshots() {
    try {
      const files = fs.readdirSync(this.screenshotDir).filter(f => f.endsWith('.png')).map(f => ({ name: f, time: fs.statSync(path.join(this.screenshotDir, f)).mtime })).sort((a, b) => b.time.getTime() - a.time.getTime());
      files.slice(100).forEach(f => fs.unlinkSync(path.join(this.screenshotDir, f.name)));
    } catch (err) { console.error('Cleanup failed:', err); }
  }
}

// Create the app instance
new PromiseKeeperApp(); 