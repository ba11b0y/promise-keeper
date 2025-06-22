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
                command: "npm",
                args: ["run", "start"],
                cwd: path.join(process.cwd(), '../applescript-mcp')
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

    async callTool(category: string, args: { name: string; arguments: any }) {
        if (!this.client) {
            throw new Error('MCP client not initialized');
        }

        try {
            const response = await this.client.callTool({
                name: `${category}_${args.name}`,
                arguments: args.arguments
            });
            return response;
        } catch (error) {
            console.error(`Error calling MCP tool ${category}:`, error);
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

    // Messages operations
    async listChats(includeParticipantDetails?: boolean) {
        return this.callTool('messages', {
            name: 'list_chats',
            arguments: {
                includeParticipantDetails: includeParticipantDetails ?? false
            }
        });
    }

    async getMessages(limit?: number) {
        return this.callTool('messages', {
            name: 'get_messages',
            arguments: {
                limit: limit ?? 100
            }
        });
    }

    async searchMessages(searchText: string, sender?: string, chatId?: string, limit?: number, daysBack?: number) {
        return this.callTool('messages', {
            name: 'search_messages',
            arguments: {
                searchText,
                ...(sender && { sender }),
                ...(chatId && { chatId }),
                limit: limit ?? 50,
                daysBack: daysBack ?? 30
            }
        });
    }

    async sendMessage(recipient: string, body?: string, auto?: boolean) {
        return this.callTool('messages', {
            name: 'compose_message',
            arguments: {
                recipient,
                ...(body && { body }),
                auto: auto ?? false
            }
        });
    }

    // System operations
    async launchApp(appName: string) {
        return this.callTool('system', {
            name: 'launch_app',
            arguments: {
                name: appName
            }
        });
    }
}

// Export singleton instance
export const mcpClient = new MCPClient(); 