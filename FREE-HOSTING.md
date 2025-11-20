# 🆓 Gratis Hosting för Kolada MCP Server

## 1. 🥇 Render (REKOMMENDERAT)

### Gratis Tier:
- ✅ Helt gratis
- ✅ 750 timmar/månad (ca 31 dagar)
- ✅ Automatisk HTTPS
- ✅ Auto-deploy från GitHub
- ⚠️  Sover efter 15 min inaktivitet (startar på 30-50 sek)
- ⚠️  512 MB RAM

### Setup:
1. Gå till https://render.com
2. Skapa konto (gratis med GitHub)
3. New → Web Service
4. Anslut GitHub repo: KSAklfszf921/kolada-mcp-server
5. Konfigurera:
   - Name: kolada-mcp
   - Build Command: `npm install && npm run build`
   - Start Command: `npm run start:http`
   - Instance Type: **Free**
6. Environment Variables:
   - `MCP_MODE` = `http`
   - `MCP_AUTH_TOKEN` = `Yry0+YTH3Y6XzmY89S7WOVayw2ksIte1hgedTYC1L9U=`
7. Deploy!

Du får URL: `https://kolada-mcp.onrender.com/sse`

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 2. 🚂 Railway

### Gratis Tier:
- ✅ $5 gratis credit/månad
- ✅ Räcker för ~500 timmar
- ✅ Ingen auto-sleep
- ✅ Snabbare än Render
- ⚠️  Kräver betalkort (inte debiteras om inom $5)

### Setup:
1. https://railway.app
2. New Project → Deploy from GitHub
3. Välj repo: kolada-mcp-server
4. Railway auto-detekterar Node.js
5. Environment Variables:
   - `MCP_MODE` = `http`
   - `MCP_AUTH_TOKEN` = `Yry0+YTH3Y6XzmY89S7WOVayw2ksIte1hgedTYC1L9U=`
6. Generate Domain
7. Deploy!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 3. 🪰 Fly.io

### Gratis Tier:
- ✅ Helt gratis
- ✅ 3 shared-cpu VMs
- ✅ 160GB bandwidth/månad
- ✅ Ingen auto-sleep
- ⚠️  Kräver betalkort (inte debiteras)

### Setup:
1. https://fly.io
2. Installera CLI: `brew install flyctl`
3. Login: `flyctl auth login`
4. I repo-mappen: `flyctl launch`
5. Sätt secrets:
   ```bash
   flyctl secrets set MCP_MODE=http
   flyctl secrets set MCP_AUTH_TOKEN=Yry0+YTH3Y6XzmY89S7WOVayw2ksIte1hgedTYC1L9U=
   ```
6. Deploy: `flyctl deploy`

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 4. 🎨 Cyclic

### Gratis Tier:
- ✅ Helt gratis
- ✅ 10,000 requests/månad
- ✅ Automatisk HTTPS
- ⚠️  Begränsad till 1 app

### Setup:
1. https://cyclic.sh
2. Connect GitHub
3. Deploy repo
4. Sätt environment variables
5. Auto-deploy

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 5. 🦖 Deno Deploy

### Gratis Tier:
- ✅ Helt gratis
- ✅ 100,000 requests/dag
- ✅ Global CDN
- ⚠️  Kräver Deno (inte Node.js direkt)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📊 JÄMFÖRELSE

| Service    | Gratis? | Auto-Sleep? | Kräver kort? | Best för        |
|------------|---------|-------------|--------------|-----------------|
| Render     | ✅      | ⚠️ Ja       | ❌           | Enklast         |
| Railway    | 💰 $5   | ❌          | ⚠️ Ja        | Snabbast        |
| Fly.io     | ✅      | ❌          | ⚠️ Ja        | Production      |
| Cyclic     | ✅      | ⚠️ Ja       | ❌           | Hobbyprojekt    |

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 💡 REKOMMENDATION

### För dig (Lovable-användning):

**Render (Gratis)** - Bäst att börja med!
- ✅ Inget betalkort krävs
- ✅ Extremt enkelt setup
- ✅ Gratis för alltid
- ⚠️  Acceptera 30-50 sek uppstartstid första anropet

**Workaround för auto-sleep:**
Använd en gratis cron-service för att pinga servern var 10:e minut:
- https://cron-job.org (gratis)
- https://uptimerobot.com (gratis)

Då sover servern aldrig och är alltid snabb!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🚀 SNABBSTART MED RENDER (5 MIN)

Se: /tmp/kolada-render-deploy.sh

