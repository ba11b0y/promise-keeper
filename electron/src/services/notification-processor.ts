import { mcpClient } from './mcp-client';

interface NotificationContent {
    title: string;
    body: string;
    metadata: {
        action: {
            actionType: string;
            start_time: string;
            end_time: string;
            to_whom: string;
        };
        start_date: string;
        to_whom: string;
    }
}

export class NotificationProcessor {
    private static instance: NotificationProcessor;

    private constructor() {
        console.log('[NotificationProcessor] Initialized');
    }

    public static getInstance(): NotificationProcessor {
        if (!NotificationProcessor.instance) {
            NotificationProcessor.instance = new NotificationProcessor();
        }
        return NotificationProcessor.instance;
    }

    public async processNotification(notification: NotificationContent): Promise<void> {
        console.log('[NotificationProcessor] Processing notification:', notification);

        if (notification.metadata.action) {
            // if (this.containsMessagePromise(notification.metadata.action)) {
            //     console.log('[NotificationProcessor] 📱 Message promise detected, processing...');
            //     await this.handleMessagePromise(notification);
            if (this.containsCalendarPromise(notification.metadata.action.actionType)) {
                console.log('[NotificationProcessor] 📅 Calendar promise detected, processing...');
                await this.handleCalendarPromise(notification);
            } else {
                console.log('[NotificationProcessor] No promise detected in this notification');
            }
        }
    }

    private containsMessagePromise(text: string): boolean {
        const hasMessage = text.toLowerCase().includes('message');
        console.log('[NotificationProcessor] Message keyword found:', hasMessage);
        return hasMessage;
    }

    private containsCalendarPromise(text: string): boolean {
        const hasCalendar = text.toLowerCase().includes('calendar') ||
            text.toLowerCase().includes('meet') ||
            text.toLowerCase().includes('meeting') ||
            text.toLowerCase().includes('catch up');
        console.log('[NotificationProcessor] Calendar keyword found:', hasCalendar);
        return hasCalendar;
    }

    private async handleMessagePromise(notification: NotificationContent): Promise<void> {
        try {
            // Extract phone number - for now we'll use a default test number
            // In a real implementation, we'd want to extract this from the promise
            const defaultPhoneNumber = '+14694862271';

            console.log('[NotificationProcessor] 📤 Sending message to:', defaultPhoneNumber);
            console.log('[NotificationProcessor] Message content:', notification.body);

            // Send the message using MCP client
            await mcpClient.sendMessage(
                defaultPhoneNumber,
                `${notification.body}`
            );

            console.log('[NotificationProcessor] ✅ Message sent successfully');
        } catch (error) {
            console.error('[NotificationProcessor] ❌ Failed to send message:', error);
        }
    }

    private async handleCalendarPromise(notification: NotificationContent): Promise<void> {
        try {
            // First, launch the Calendar app
            console.log('[NotificationProcessor] 🚀 Launching Calendar app');
            await mcpClient.launchApp('Calendar');

            // Wait a moment for the app to launch
            await new Promise(resolve => setTimeout(resolve, 1000));

            // For now, we'll create an event for tomorrow at a reasonable time
            const tomorrow = new Date();
            tomorrow.setDate(tomorrow.getDate() + 1);
            tomorrow.setHours(10, 0, 0); // Set to 10:00 AM

            const endTime = new Date(tomorrow);
            endTime.setHours(11, 0, 0); // Set to 11:00 AM (1-hour duration)

            // Format dates for calendar
            const startDate = tomorrow.toISOString().replace('T', ' ').slice(0, 19);
            const endDate = endTime.toISOString().replace('T', ' ').slice(0, 19);

            console.log('[NotificationProcessor] 📅 Creating calendar event');
            console.log('[NotificationProcessor] Event details:', {
                title: notification.body,
                startDate,
                endDate
            });

            // Create the calendar event using MCP client
            await mcpClient.addCalendarEvent(
                notification.body,
                startDate,
                endDate
            );

            console.log('[NotificationProcessor] ✅ Calendar event created successfully');
        } catch (error) {
            console.error('[NotificationProcessor] ❌ Failed to create calendar event:', error);
        }
    }
} 