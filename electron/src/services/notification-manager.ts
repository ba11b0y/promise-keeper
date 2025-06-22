import { Notification, BrowserWindow } from 'electron';
import { createTrayIcon } from '../create-tray-icon';
import { NotificationProcessor } from './notification-processor';

interface NotificationData {
    title: string;
    body: string;
    timestamp: number;
    action?: {
        actionType: string;
        start_time: string;
        end_time: string;
        to_whom: string;
    };
    start_date?: string;
    to_whom?: string;
}

export class NotificationManager {
    private static instance: NotificationManager;
    private lastNotification: NotificationData | null = null;
    private activeNotification: Notification | null = null;
    private mainWindow: BrowserWindow | null = null;
    private notificationCount: number = 0;
    private notificationProcessor: NotificationProcessor;

    private constructor() {
        console.log('NotificationManager initialized');
        this.notificationProcessor = NotificationProcessor.getInstance();
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

    public async showNotification(title: string, body: string, metadata: Partial<Omit<NotificationData, 'title' | 'body' | 'timestamp'>> = {}, onClickCallback?: () => void): Promise<void> {
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
            timestamp: Date.now(),
            ...metadata
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

    public async handleTabPress(): Promise<void> {
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
                age: `${Math.round((Date.now() - this.lastNotification.timestamp) / 1000)} seconds ago`,
                action: this.lastNotification.action ?? '',
                start_date: this.lastNotification.start_date ?? '',
                to_whom: this.lastNotification.to_whom ?? ''
            };

            console.log('✅ Last Notification:');
            console.table(formattedData);

            // Process the notification when shortcut is pressed
            await this.notificationProcessor.processNotification({
                title: this.lastNotification.title,
                body: this.lastNotification.body,
                metadata: {
                    action: {
                        actionType: this.lastNotification.action?.actionType ?? '',
                        start_time: this.lastNotification.action?.start_time ?? '',
                        end_time: this.lastNotification.action?.end_time ?? '',
                        to_whom: this.lastNotification.action?.to_whom ?? ''
                    },
                    start_date: this.lastNotification.start_date ?? '',
                    to_whom: this.lastNotification.to_whom ?? ''
                }
            });

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