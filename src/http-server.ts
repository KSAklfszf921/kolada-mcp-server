#!/usr/bin/env node
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';
import { SSEServerTransport } from '@modelcontextprotocol/sdk/server/sse.js';
import express, { Request, Response, NextFunction } from 'express';
import {
  CallToolRequestSchema,
  ListToolsRequestSchema,
  ListResourcesRequestSchema,
  ReadResourceRequestSchema,
} from '@modelcontextprotocol/sdk/types.js';
import { kpiTools } from './tools/kpi-tools.js';
import { municipalityTools } from './tools/municipality-tools.js';
import { ouTools } from './tools/ou-tools.js';
import { dataTools } from './tools/data-tools.js';
import { koladaClient } from './api/client.js';
import type { Municipality, KPI } from './config/types.js';

const PORT = parseInt(process.env.PORT || '3000');
const AUTH_TOKEN = process.env.MCP_AUTH_TOKEN;

/**
 * Authentication middleware
 */
function authenticate(req: Request, res: Response, next: NextFunction) {
  // Skip auth if no token is configured (development mode)
  if (!AUTH_TOKEN) {
    console.warn('⚠️  Warning: Running without authentication. Set MCP_AUTH_TOKEN for production.');
    return next();
  }

  const authHeader = req.headers.authorization;

  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Missing or invalid Authorization header' });
  }

  const token = authHeader.substring(7); // Remove 'Bearer ' prefix

  if (token !== AUTH_TOKEN) {
    return res.status(403).json({ error: 'Invalid token' });
  }

  next();
}

// Combine all tools
const allTools = {
  ...kpiTools,
  ...municipalityTools,
  ...ouTools,
  ...dataTools,
};

/**
 * Create and configure MCP server
 */
function createMCPServer(): Server {
  const server = new Server(
    {
      name: 'kolada-mcp-server',
      version: '1.0.0',
    },
    {
      capabilities: {
        tools: {},
        resources: {},
      },
    }
  );

  // List all available tools
  server.setRequestHandler(ListToolsRequestSchema, async () => {
    return {
      tools: Object.entries(allTools).map(([name, tool]) => ({
        name,
        description: tool.description,
        inputSchema: tool.inputSchema.shape,
      })),
    };
  });

  // Handle tool calls
  server.setRequestHandler(CallToolRequestSchema, async (request) => {
    const { name, arguments: args } = request.params;

    const tool = allTools[name as keyof typeof allTools];
    if (!tool) {
      throw new Error(`Unknown tool: ${name}`);
    }

    // Validate input
    const validatedArgs = tool.inputSchema.parse(args);

    // Execute tool handler
    return await tool.handler(validatedArgs);
  });

  // List available resources
  server.setRequestHandler(ListResourcesRequestSchema, async () => {
    return {
      resources: [
        {
          uri: 'kolada://municipalities',
          name: 'Swedish Municipalities List',
          description: 'Complete list of Swedish municipalities and county councils',
          mimeType: 'application/json',
        },
        {
          uri: 'kolada://kpi-catalog',
          name: 'KPI Catalog',
          description: 'Complete catalog of available KPIs with metadata',
          mimeType: 'application/json',
        },
        {
          uri: 'kolada://api-info',
          name: 'Kolada API Information',
          description: 'API information, endpoints, and usage guidelines',
          mimeType: 'text/markdown',
        },
      ],
    };
  });

  // Handle resource reads
  server.setRequestHandler(ReadResourceRequestSchema, async (request) => {
    const { uri } = request.params;

    switch (uri) {
      case 'kolada://municipalities': {
        const municipalities = await koladaClient.fetchAllData<Municipality>('/municipality');
        return {
          contents: [
            {
              uri,
              mimeType: 'application/json',
              text: JSON.stringify(
                {
                  count: municipalities.length,
                  municipalities: municipalities.map((m) => ({
                    id: m.id,
                    title: m.title,
                    type: m.type,
                    type_description:
                      m.type === 'K' ? 'Kommun (Municipality)' : 'Landsting/Region (County Council)',
                  })),
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case 'kolada://kpi-catalog': {
        const kpis = await koladaClient.fetchAllData<KPI>('/kpi');
        return {
          contents: [
            {
              uri,
              mimeType: 'application/json',
              text: JSON.stringify(
                {
                  count: kpis.length,
                  kpis: kpis.map((k) => ({
                    id: k.id,
                    title: k.title,
                    description: k.description,
                    operating_area: k.operating_area,
                    municipality_type: k.municipality_type,
                  })),
                },
                null,
                2
              ),
            },
          ],
        };
      }

      case 'kolada://api-info': {
        const apiInfo = `# Kolada API v3 Information

## About Kolada
Kolada is a database containing key performance indicators (KPIs) for Swedish municipalities and regions.

## API Base URL
\`https://api.kolada.se/v3\`

## Rate Limits
- Maximum 5 requests per second
- Automatic retry with exponential backoff
- Request timeout: 30 seconds

## Main Endpoints
- \`/kpi\` - List and search KPIs
- \`/municipality\` - List and search municipalities
- \`/ou\` - List and search organizational units
- \`/data\` - Get KPI data for municipalities
- \`/oudata\` - Get KPI data for organizational units

## Pagination
- Default page size: 5000 items
- Follow \`next_page\` URL for additional pages
- Maximum batch size: 25 IDs per request

## Data Attribution
When using Kolada data, please cite as: **"Källa: Kolada"**

## More Information
Official API documentation: https://api.kolada.se/v3/docs
`;

        return {
          contents: [
            {
              uri,
              mimeType: 'text/markdown',
              text: apiInfo,
            },
          ],
        };
      }

      default:
        throw new Error(`Unknown resource: ${uri}`);
    }
  });

  return server;
}

/**
 * Start HTTP server with SSE transport
 */
async function startHTTPServer() {
  const app = express();

  app.use(express.json());

  // Health check endpoint
  app.get('/health', (req, res) => {
    res.json({
      status: 'ok',
      service: 'kolada-mcp-server',
      version: '1.0.0',
      authenticated: !!AUTH_TOKEN
    });
  });

  // MCP SSE endpoint with authentication
  app.get('/sse', authenticate, async (req, res) => {
    console.log('📡 New SSE connection established');

    const server = createMCPServer();
    const transport = new SSEServerTransport('/message', res);

    await server.connect(transport);

    // Handle client disconnect
    req.on('close', () => {
      console.log('🔌 SSE connection closed');
    });
  });

  // MCP message endpoint (for sending messages via POST)
  app.post('/message', authenticate, async (req, res) => {
    console.log('📨 Received message:', req.body);
    res.json({ received: true });
  });

  app.listen(PORT, () => {
    console.log(`
╔══════════════════════════════════════════════════════════╗
║  🚀 Kolada MCP HTTP Server                               ║
╟──────────────────────────────────────────────────────────╢
║  Port:           ${PORT.toString().padEnd(42)}║
║  SSE Endpoint:   /sse${' '.repeat(42)}║
║  Health Check:   /health${' '.repeat(38)}║
║  Auth:           ${(AUTH_TOKEN ? '✅ Enabled' : '⚠️  Disabled (dev mode)').padEnd(42)}║
╚══════════════════════════════════════════════════════════╝

📖 Usage with Lovable:
   Endpoint: http://localhost:${PORT}/sse
   ${AUTH_TOKEN ? `Auth: Bearer ${AUTH_TOKEN.substring(0, 20)}...` : 'No authentication required'}

💡 Set MCP_AUTH_TOKEN environment variable for production
    `);
  });
}

/**
 * Main entry point - supports both stdio and HTTP modes
 */
async function main() {
  const mode = process.env.MCP_MODE || 'stdio';

  if (mode === 'http') {
    await startHTTPServer();
  } else {
    // Original stdio mode
    const server = createMCPServer();
    const transport = new StdioServerTransport();
    await server.connect(transport);
    console.error('Kolada MCP Server running in stdio mode');
  }
}

main().catch((error) => {
  console.error('Fatal error:', error);
  process.exit(1);
});
