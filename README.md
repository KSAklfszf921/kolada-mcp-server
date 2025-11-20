# Kolada MCP Server

> **MCP server providing access to Swedish municipality and regional data through the Kolada API v3**

[![npm version](https://img.shields.io/npm/v/kolada-mcp-server.svg)](https://www.npmjs.com/package/kolada-mcp-server)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/KSAklfszf921/kolada-mcp-server)

## 🌟 Features

- **16 Tools** for comprehensive data access
  - 5 KPI tools (search, retrieve, groups)
  - 4 Municipality tools (search, groups, metadata)
  - 3 Organizational Unit tools (schools, care facilities)
  - 4 Data Retrieval tools (KPI data, comparisons, trends)

- **3 Resources** for metadata catalogs
  - Complete municipalities list
  - Full KPI catalog
  - API information and documentation

- **Dual Transport Support**
  - **stdio** - For Claude Desktop and CLI tools
  - **HTTP/SSE** - For Lovable and web-based clients
  - Token authentication for HTTP mode

- **Rate Limiting & Retry Logic**
  - Automatic rate limiting (5 req/s)
  - Exponential backoff on failures
  - Resilient error handling

- **TypeScript** with full type safety and IntelliSense support

## 📦 Installation

### As an npm package

```bash
npm install -g kolada-mcp-server
```

### From source

```bash
git clone https://github.com/KSAklfszf921/kolada-mcp-server.git
cd kolada-mcp-server
npm install
npm run build
```

## 🚀 Usage with Claude Desktop

Add to your Claude Desktop configuration file:

**MacOS**: `~/Library/Application Support/Claude/claude_desktop_config.json`
**Windows**: `%APPDATA%\Claude\claude_desktop_config.json`

```json
{
  "mcpServers": {
    "kolada": {
      "command": "node",
      "args": ["/path/to/kolada-mcp-server/dist/index.js"]
    }
  }
}
```

Or if installed via npm:

```json
{
  "mcpServers": {
    "kolada": {
      "command": "kolada-mcp-server"
    }
  }
}
```

Restart Claude Desktop to load the server.

## 🌐 Usage with Lovable (HTTP Mode)

The server supports HTTP/SSE transport with token authentication for use with [Lovable](https://lovable.dev) and other HTTP-based MCP clients.

### Quick Start

1. **Set up environment variables:**
   ```bash
   cp .env.example .env
   # Edit .env and set MCP_AUTH_TOKEN to a secure token
   ```

2. **Generate a secure token:**
   ```bash
   openssl rand -base64 32
   ```

3. **Start the HTTP server:**
   ```bash
   npm run dev:http  # Development
   npm run start:http # Production (after npm run build)
   ```

4. **Configure in Lovable:**
   ```json
   {
     "mcpServers": {
       "kolada": {
         "url": "http://localhost:3000/sse",
         "transport": "sse",
         "headers": {
           "Authorization": "Bearer your-token-here"
         }
       }
     }
   }
   ```

See [LOVABLE.md](./LOVABLE.md) for complete deployment guide including Render, Railway, and Docker.

## 🚀 Free Deployment Options

### One-Click Deploy to Render (Recommended)

Click the button to deploy to Render's free tier:

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/KSAklfszf921/kolada-mcp-server)

After deployment:
1. Set `MCP_AUTH_TOKEN` in Render Dashboard
2. Get your service URL: `https://your-service.onrender.com/sse`
3. Update Lovable config with your URL and token

**Free tier includes:**
- ✅ 750 hours/month (always-on)
- ✅ Automatic HTTPS
- ✅ Auto-deploy from GitHub
- ⚠️  Sleeps after 15 min inactivity (use UptimeRobot to keep awake)

### Other Free Options

- **Railway** - $5/month free credit (no sleep) - [Guide](./LOVABLE.md#railway)
- **Fly.io** - 3 free VMs (no sleep) - [Guide](./LOVABLE.md#flyio)
- **Cyclic** - 10k requests/month - [Guide](./LOVABLE.md#cyclic)

See [FREE-HOSTING.md](./FREE-HOSTING.md) for detailed comparison and [DEPLOY-RENDER.md](./DEPLOY-RENDER.md) for step-by-step Render deployment.

## 🛠️ Available Tools

### KPI Tools

#### `search_kpis`
Search for KPIs by query string, publication date, or operating area.

```typescript
{
  query?: string,              // Search term
  publication_date?: string,   // Filter by date (YYYY-MM-DD)
  operating_area?: string,     // Operating area filter
  limit?: number               // Max results (default: 20, max: 100)
}
```

#### `get_kpi`
Get detailed information about a specific KPI by ID.

```typescript
{
  kpi_id: string  // e.g., "N15033"
}
```

#### `get_kpis`
Get multiple KPIs by their IDs (max 25 per call).

```typescript
{
  kpi_ids: string[]  // Array of KPI IDs
}
```

#### `get_kpi_groups`
List KPI groups with optional search query.

```typescript
{
  query?: string  // Search term
}
```

#### `get_kpi_group`
Get detailed information about a specific KPI group.

```typescript
{
  group_id: string
}
```

### Municipality Tools

#### `search_municipalities`
Search for Swedish municipalities or county councils.

```typescript
{
  query?: string,                      // Search term
  municipality_type?: 'K' | 'L' | 'all'  // K=Kommun, L=Landsting, all=both
}
```

#### `get_municipality`
Get detailed information about a specific municipality.

```typescript
{
  municipality_id: string  // 4-digit code (e.g., "0180" for Stockholm)
}
```

#### `get_municipality_groups`
List municipality groups (metropolitan regions, etc.).

```typescript
{
  query?: string  // Search term
}
```

#### `get_municipality_group`
Get detailed information about a municipality group.

```typescript
{
  group_id: string
}
```

### Organizational Unit Tools

#### `search_organizational_units`
Search for organizational units (schools, care facilities, etc.).

```typescript
{
  query?: string,         // Search term
  municipality?: string,  // Filter by municipality ID
  ou_type?: string,       // Filter by OU type (e.g., "V11", "V15")
  limit?: number          // Max results (default: 20)
}
```

#### `get_organizational_unit`
Get detailed information about a specific organizational unit.

```typescript
{
  ou_id: string
}
```

#### `get_ou_types`
Get a list of common organizational unit types.

### Data Retrieval Tools

#### `get_kpi_data`
Retrieve actual KPI data for municipalities or organizational units.

```typescript
{
  kpi_id: string,
  municipality_id?: string,  // Use this OR ou_id
  ou_id?: string,            // Use this OR municipality_id
  years?: number[]           // Filter by years [2020, 2021, 2022]
}
```

#### `get_municipality_kpis`
Get all KPIs available for a specific municipality.

```typescript
{
  municipality_id: string,
  year?: number  // Optional year filter
}
```

#### `compare_municipalities`
Compare a KPI across multiple municipalities.

```typescript
{
  kpi_id: string,
  municipality_ids: string[],  // 2-10 municipalities
  years?: number[]             // Optional years filter
}
```

#### `get_kpi_trend`
Get historical trend data for a KPI.

```typescript
{
  kpi_id: string,
  municipality_id: string,
  start_year: number,
  end_year?: number  // Defaults to current year
}
```

## 📚 Resources

### `kolada://municipalities`
Complete list of Swedish municipalities and county councils.

### `kolada://kpi-catalog`
Complete catalog of available KPIs with metadata.

### `kolada://api-info`
API information, endpoints, rate limits, and usage guidelines.

## 💡 Usage Examples

### Example 1: Search for education-related KPIs

```
User: Find KPIs related to education
Assistant uses: search_kpis with query="skola"
```

### Example 2: Compare municipalities

```
User: Compare Stockholm and Gothenburg on teacher-student ratio
Assistant uses:
1. search_municipalities to find Stockholm (0180) and Gothenburg (1480)
2. search_kpis to find the relevant KPI
3. compare_municipalities with those IDs and the KPI
```

### Example 3: Analyze trends

```
User: Show me how Stockholm's healthcare spending has changed over the last 5 years
Assistant uses:
1. search_municipalities to find Stockholm (0180)
2. search_kpis with query="hälso- och sjukvård"
3. get_kpi_trend with the selected KPI and Stockholm's ID
```

## 🏗️ Architecture

```
kolada-mcp-server/
├── src/
│   ├── index.ts                 # Main MCP server entry point
│   ├── config/
│   │   ├── constants.ts         # API configuration
│   │   └── types.ts             # TypeScript type definitions
│   ├── api/
│   │   └── client.ts            # HTTP client with rate limiting
│   └── tools/
│       ├── kpi-tools.ts         # KPI search & retrieval tools
│       ├── municipality-tools.ts # Municipality tools
│       ├── ou-tools.ts          # Organizational unit tools
│       └── data-tools.ts        # Data retrieval tools
├── dist/                        # Compiled JavaScript
└── package.json
```

## 🔧 Configuration

Environment variables (optional):

```bash
KOLADA_API_BASE_URL=https://api.kolada.se/v3  # API base URL
KOLADA_RATE_LIMIT=5                            # Requests per second
KOLADA_CACHE_TTL=86400                         # Cache TTL in seconds
KOLADA_TIMEOUT=30000                           # Request timeout in ms
```

## 📖 About Kolada

Kolada is a database containing key performance indicators (KPIs) for Swedish municipalities and regions. The database is maintained by SKR (Sveriges Kommuner och Regioner / Swedish Association of Local Authorities and Regions).

### Data Attribution

When using Kolada data, please cite as: **"Källa: Kolada"**

### Official Resources

- [Kolada Website](https://www.kolada.se/)
- [API Documentation](https://api.kolada.se/v3/docs)
- [SKR Website](https://skr.se/)

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 Development

```bash
# Install dependencies
npm install

# Build
npm run build

# Run in development mode
npm run dev

# Lint
npm run lint

# Format
npm run format
```

## 📜 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgements

- [Kolada API](https://www.kolada.se/) for providing access to Swedish municipality data
- [Model Context Protocol](https://modelcontextprotocol.io/) by Anthropic
- [koladapy](https://github.com/xemarap/koladapy) - Python wrapper that inspired this implementation

## ⚠️ Disclaimer

This is an independent project and is not officially associated with Kolada or SKR.

---

**Made with ❤️ for the Swedish open data community**
