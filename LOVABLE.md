# Using Kolada MCP with Lovable

This guide explains how to use the Kolada MCP Server with [Lovable](https://lovable.dev) using HTTP/SSE transport with token authentication.

## Quick Start

### 1. Generate an Authentication Token

```bash
# Generate a secure random token
openssl rand -base64 32
```

Save this token - you'll need it for both server configuration and Lovable setup.

### 2. Configure Environment Variables

Create a `.env` file in the project root:

```bash
MCP_MODE=http
PORT=3000
MCP_AUTH_TOKEN=your-generated-token-here
```

Or export them directly:

```bash
export MCP_MODE=http
export PORT=3000
export MCP_AUTH_TOKEN=your-generated-token-here
```

### 3. Start the HTTP Server

**Development mode:**
```bash
npm run dev:http
```

**Production mode:**
```bash
npm run build
npm run start:http
```

You should see:
```
╔══════════════════════════════════════════════════════════╗
║  🚀 Kolada MCP HTTP Server                               ║
╟──────────────────────────────────────────────────────────╢
║  Port:           3000                                      ║
║  SSE Endpoint:   /sse                                          ║
║  Health Check:   /health                                      ║
║  Auth:           ✅ Enabled                                 ║
╚══════════════════════════════════════════════════════════╝
```

### 4. Configure in Lovable

In your Lovable project, add the MCP server:

```json
{
  "mcpServers": {
    "kolada": {
      "url": "http://localhost:3000/sse",
      "transport": "sse",
      "headers": {
        "Authorization": "Bearer your-generated-token-here"
      }
    }
  }
}
```

For deployed servers, replace `localhost:3000` with your server's URL.

## Deployment

### Using Render

1. **Create a new Web Service** on [Render](https://render.com)

2. **Connect your repository**

3. **Configure build settings:**
   - Build Command: `npm install && npm run build`
   - Start Command: `npm run start:http`

4. **Set environment variables:**
   - `MCP_MODE` = `http`
   - `PORT` = `3000` (or leave empty for Render's default)
   - `MCP_AUTH_TOKEN` = `your-secure-token`

5. **Deploy** and copy your service URL (e.g., `https://kolada-mcp.onrender.com`)

6. **Update Lovable configuration** with your deployed URL:

```json
{
  "mcpServers": {
    "kolada": {
      "url": "https://kolada-mcp.onrender.com/sse",
      "transport": "sse",
      "headers": {
        "Authorization": "Bearer your-secure-token"
      }
    }
  }
}
```

### Using Railway

1. **Create a new project** on [Railway](https://railway.app)

2. **Deploy from GitHub repository**

3. **Add environment variables:**
   ```
   MCP_MODE=http
   MCP_AUTH_TOKEN=your-secure-token
   ```

4. **Railway will auto-assign a PORT** - no need to set it

5. **Generate a domain** and update Lovable config

### Using Docker

```dockerfile
FROM node:18-alpine

WORKDIR /app

COPY package*.json ./
RUN npm ci --only=production

COPY . .
RUN npm run build

ENV MCP_MODE=http
ENV PORT=3000

EXPOSE 3000

CMD ["npm", "run", "start:http"]
```

Build and run:

```bash
docker build -t kolada-mcp .
docker run -p 3000:3000 \
  -e MCP_AUTH_TOKEN=your-secure-token \
  kolada-mcp
```

## Security Best Practices

### Token Management

1. **Never commit tokens to version control**
   - Use `.env` files (already in `.gitignore`)
   - Use environment variables in production

2. **Generate strong tokens**
   ```bash
   # 32-byte random token (recommended)
   openssl rand -base64 32

   # Or use UUID
   uuidgen
   ```

3. **Rotate tokens regularly**
   - Update `MCP_AUTH_TOKEN` on server
   - Update `Authorization` header in Lovable
   - Restart server

### HTTPS in Production

**Always use HTTPS in production:**

- ✅ `https://your-domain.com/sse`
- ❌ `http://your-domain.com/sse`

Most deployment platforms (Render, Railway, Vercel) provide HTTPS automatically.

### CORS Configuration (if needed)

If deploying publicly, you may need to add CORS middleware. Edit `src/http-server.ts`:

```typescript
import cors from 'cors';

const app = express();
app.use(cors({
  origin: 'https://lovable.dev', // Or your Lovable instance URL
  credentials: true
}));
```

Then install cors:
```bash
npm install cors
npm install --save-dev @types/cors
```

## Testing

### Health Check

```bash
curl http://localhost:3000/health
```

Expected response:
```json
{
  "status": "ok",
  "service": "kolada-mcp-server",
  "version": "1.0.0",
  "authenticated": true
}
```

### Test Authentication

**Without token (should fail):**
```bash
curl -I http://localhost:3000/sse
# HTTP/1.1 401 Unauthorized
```

**With wrong token (should fail):**
```bash
curl -H "Authorization: Bearer wrong-token" http://localhost:3000/sse
# {"error":"Invalid token"}
```

**With correct token (should succeed):**
```bash
curl -N -H "Authorization: Bearer your-token" http://localhost:3000/sse
# SSE connection established
```

## Troubleshooting

### Server won't start

**Check environment variables:**
```bash
echo $MCP_MODE
echo $MCP_AUTH_TOKEN
echo $PORT
```

**Check port availability:**
```bash
lsof -i :3000
```

### Lovable can't connect

1. **Verify server is running:**
   ```bash
   curl http://localhost:3000/health
   ```

2. **Check token matches:**
   - Server: `MCP_AUTH_TOKEN` environment variable
   - Lovable: `Authorization: Bearer <token>` header

3. **Check firewall/network:**
   - Ensure port is accessible
   - Check if localhost vs 0.0.0.0 binding

4. **Check CORS (if remote):**
   - Add CORS middleware if server is remote
   - Verify origin is allowed

### 401 Unauthorized errors

- Token is missing or incorrect in Lovable config
- Verify `Authorization` header format: `Bearer <token>`
- Check server logs for auth attempts

### 403 Forbidden errors

- Token is provided but incorrect
- Regenerate token and update both server and Lovable

## Available Tools

Once connected, Lovable can use all 16 Kolada MCP tools:

### KPI Tools (5)
- `search_kpis` - Search for KPIs
- `get_kpi` - Get single KPI details
- `get_kpis` - Get multiple KPIs
- `get_kpi_groups` - List KPI groups
- `get_kpi_group` - Get KPI group details

### Municipality Tools (4)
- `search_municipalities` - Search municipalities
- `get_municipality` - Get municipality details
- `get_municipality_groups` - List municipality groups
- `get_municipality_group` - Get group details

### Organizational Unit Tools (3)
- `search_organizational_units` - Search schools, care facilities
- `get_organizational_unit` - Get OU details
- `get_ou_types` - List OU types

### Data Retrieval Tools (4)
- `get_kpi_data` - Get KPI data for locations
- `get_municipality_kpis` - Get all KPIs for a municipality
- `compare_municipalities` - Compare municipalities
- `get_kpi_trend` - Get historical trends

## Resources

The server also provides 3 resources:

- `kolada://municipalities` - Complete municipalities list
- `kolada://kpi-catalog` - Full KPI catalog
- `kolada://api-info` - API documentation

## Support

For issues or questions:

- GitHub Issues: https://github.com/KSAklfszf921/kolada-mcp-server/issues
- MCP Documentation: https://modelcontextprotocol.io/
- Kolada API Docs: https://api.kolada.se/v3/docs

## License

MIT License - see LICENSE file for details.
