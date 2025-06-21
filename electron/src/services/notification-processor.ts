import { mcpClient } from './mcp-client';

interface NotificationContent {
    title: string;
    body: string;
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

        if (this.containsMessagePromise(notification.body)) {
            console.log('[NotificationProcessor] 📱 Message promise detected, processing...');
            await this.handleMessagePromise(notification);
        } else {
            console.log('[NotificationProcessor] No message promise detected in this notification');
        }
    }

    private containsMessagePromise(text: string): boolean {
        const hasMessage = text.toLowerCase().includes('message');
        console.log('[NotificationProcessor] Message keyword found:', hasMessage);
        return hasMessage;
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
                `Promise Keeper: ${notification.body}`
            );

            console.log('[NotificationProcessor] ✅ Message sent successfully');
        } catch (error) {
            console.error('[NotificationProcessor] ❌ Failed to send message:', error);
        }
    }
} 