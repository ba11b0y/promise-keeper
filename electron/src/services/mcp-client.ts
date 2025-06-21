import { Client } from "@modelcontextprotocol/sdk/client/index.js";
import { StdioClientTransport } from "@modelcontextprotocol/sdk/client/stdio.js";
import { spawn } from 'child_process';
import * as path from 'path';

export class MCPClient {
    private client: Client | null = null;
    private mcpProcess: ReturnType<typeof spawn> | null = null;

    async initialize() {
        try {
            // Create transport with command to start the MCP server
            const transport = new StdioClientTransport({
                command: "bun",
                args: ["index.ts"],
                cwd: path.join(process.cwd(), '../apple-mcp')
            });

            // Create and connect client
            this.client = new Client({
                name: "promise-keeper",
                version: "1.0.0"
            });

            await this.client.connect(transport);
            console.log('MCP Client initialized successfully');
        } catch (error) {
            console.error('Failed to initialize MCP client:', error);
            throw error;
        }
    }

    async callTool(name: string, args: any) {
        if (!this.client) {
            throw new Error('MCP client not initialized');
        }

        try {
            const response = await this.client.callTool({
                name,
                arguments: args
            });
            return response;
        } catch (error) {
            console.error(`Error calling MCP tool ${name}:`, error);
            throw error;
        }
    }

    async cleanup() {
        try {
            // Just clear the client reference since there's no disconnect method
            this.client = null;
        } catch (error) {
            console.error('Error cleaning up MCP client:', error);
        }
    }

    // Helper methods for common operations
    async searchContacts(name?: string) {
        return this.callTool('contacts', { name });
    }

    async createNote(title: string, body: string, folderName?: string) {
        return this.callTool('notes', {
            operation: 'create',
            title,
            body,
            folderName
        });
    }

    async sendMessage(phoneNumber: string, message: string) {
        return this.callTool('messages', {
            operation: 'send',
            phoneNumber,
            message
        });
    }

    async searchCalendar(searchText: string) {
        return this.callTool('calendar', {
            operation: 'search',
            searchText
        });
    }

    async createReminder(name: string, listName?: string, notes?: string, dueDate?: string) {
        return this.callTool('reminders', {
            operation: 'create',
            name,
            listName,
            notes,
            dueDate
        });
    }
}

// Export singleton instance
export const mcpClient = new MCPClient(); 