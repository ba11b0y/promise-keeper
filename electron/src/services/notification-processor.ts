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

            // Use start date from metadata or fallback to tomorrow if not provided
            let startDateTime = new Date();
            if (notification.metadata?.action?.start_time) {
                // Parse the actual datetime from the BAML response
                startDateTime = new Date(notification.metadata.action.start_time);

                console.log('[NotificationProcessor] Using start time from metadata:', {
                    originalUTC: notification.metadata.action.start_time,
                    parsedDate: startDateTime.toISOString(),
                    localTime: startDateTime.toString(),
                    pacificTime: startDateTime.toLocaleString('en-US', { timeZone: 'America/Los_Angeles' })
                });
            } else if (notification.metadata?.start_date) {
                // Parse the start_date text (e.g., "Tomorrow at 8")
                const startDateText = notification.metadata.start_date.toLowerCase();
                const now = new Date();
                
                // Default to tomorrow
                startDateTime = new Date(now.getTime() + (24 * 60 * 60 * 1000));
                
                // Extract hour from text
                let hour = 10; // default fallback
                const timeMatch = startDateText.match(/at (\d+)/);
                if (timeMatch) {
                    hour = parseInt(timeMatch[1]);
                    // Handle AM/PM if specified
                    if (startDateText.includes('pm') && hour < 12) {
                        hour += 12;
                    } else if (startDateText.includes('am') && hour === 12) {
                        hour = 0;
                    }
                }
                
                startDateTime.setHours(hour, 0, 0, 0);
                
                console.log('[NotificationProcessor] Parsed time from start_date:', {
                    originalText: notification.metadata.start_date,
                    extractedHour: hour,
                    resultingDateTime: startDateTime.toISOString(),
                    pacificTime: startDateTime.toLocaleString('en-US', { timeZone: 'America/Los_Angeles' })
                });
            } else {
                // Final fallback to tomorrow at 10 AM Pacific Time
                const now = new Date();
                startDateTime = new Date(now.getTime() + (24 * 60 * 60 * 1000)); // add 24 hours
                startDateTime.setHours(10, 0, 0);
            }

            // Set end time to 1 hour after start time
            const endDateTime = new Date(startDateTime);
            endDateTime.setHours(endDateTime.getHours() + 1);

            // Format dates for calendar in Pacific Time
            const formatToPacificTime = (date: Date) => {
                // Get the UTC timestamp
                const utcTime = date.getTime();

                // Create a formatter for Pacific Time
                const formatter = new Intl.DateTimeFormat('en-US', {
                    timeZone: 'America/Los_Angeles',
                    year: 'numeric',
                    month: '2-digit',
                    day: '2-digit',
                    hour: '2-digit',
                    minute: '2-digit',
                    second: '2-digit',
                    hour12: false
                });

                // Format the date and clean it up
                return formatter.format(utcTime).replace(',', '');
            };

            const startDate = formatToPacificTime(startDateTime);
            const endDate = formatToPacificTime(endDateTime);

            console.log('[NotificationProcessor] 📅 Creating calendar event (Pacific Time)');
            console.log('[NotificationProcessor] Event details:', {
                title: notification.body,
                startDate,
                endDate,
                originalMetadata: notification.metadata,
                originalStartDateTime: startDateTime.toISOString(),
                utcHours: startDateTime.getUTCHours(),
                localHours: startDateTime.getHours()
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