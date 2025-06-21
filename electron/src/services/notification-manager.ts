import { Notification, BrowserWindow } from 'electron';
import { createTrayIcon } from '../create-tray-icon';

interface NotificationData {
    title: string;
    body: string;
    timestamp: number;
}

export class NotificationManager {
    private static instance: NotificationManager;
    private lastNotification: NotificationData | null = null;
    private activeNotification: Notification | null = null;
    private mainWindow: BrowserWindow | null = null;
    private notificationCount: number = 0;

    private constructor() {
        console.log('NotificationManager initialized');
    }

    public static getInstance(): NotificationManager {
        if (!NotificationManager.instance) {
            NotificationManager.instance = new NotificationManager();
        }
        return NotificationManager.instance;
    }

    public setMainWindow(window: BrowserWindow) {
        this.mainWindow = window;
    }

    public showNotification(title: string, body: string, onClickCallback?: () => void): void {
        if (!Notification.isSupported()) {
            console.log('Notifications not supported');
            return;
        }

        this.notificationCount++;
        console.log(`[NotificationManager] Showing notification #${this.notificationCount}`);

        // Close any existing notification
        if (this.activeNotification) {
            console.log('[NotificationManager] Closing previous notification');
            this.activeNotification.close();
        }

        this.lastNotification = {
            title,
            body,
            timestamp: Date.now()
        };

        console.log('[NotificationManager] Setting last notification:', this.lastNotification);

        this.activeNotification = new Notification({
            title,
            body,
            silent: false,
            icon: createTrayIcon()
        });

        if (onClickCallback) {
            this.activeNotification.on('click', onClickCallback);
        }

        // Add close handler to clear the reference
        this.activeNotification.on('close', () => {
            console.log('[NotificationManager] Notification closed');
            if (this.activeNotification) {
                this.activeNotification = null;
            }
        });

        this.activeNotification.show();
    }

    public handleTabPress(): void {
        console.log('\n----------------------------------------');
        console.log('🔔 NOTIFICATION STATUS:');
        console.log(`Total notifications shown: ${this.notificationCount}`);
        console.log('Active notification:', this.activeNotification ? 'Yes' : 'No');
        console.log('Last notification:', this.lastNotification ? 'Present' : 'None');

        if (this.lastNotification) {
            const formattedData = {
                title: this.lastNotification.title,
                body: this.lastNotification.body,
                timestamp: new Date(this.lastNotification.timestamp).toISOString(),
                age: `${Math.round((Date.now() - this.lastNotification.timestamp) / 1000)} seconds ago`
            };

            console.log('✅ Last Notification:');
            console.table(formattedData);

            // Close the active notification if it exists
            if (this.activeNotification) {
                console.log('📪 Closing active notification');
                this.activeNotification.close();
                this.activeNotification = null;
            }
        } else {
            console.log('❌ No notifications have been shown yet');
        }
        console.log('----------------------------------------\n');
    }
} 