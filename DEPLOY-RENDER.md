# 🚀 Deploy Kolada MCP till Render (Gratis)

## Metod 1: One-Click Deploy (ENKLAST - 2 MIN)

### Steg 1: Klicka på Deploy-knappen
När denna är pushad till GitHub, använd denna URL:

[![Deploy to Render](https://render.com/images/deploy-to-render-button.svg)](https://render.com/deploy?repo=https://github.com/KSAklfszf921/kolada-mcp-server)

### Steg 2: Konfigurera
1. **Service Name**: `kolada-mcp` (eller välj eget)
2. **Region**: Frankfurt (närmast Sverige)
3. **Instance Type**: Free

### Steg 3: Sätt Environment Variables
I Render Dashboard:
1. Gå till Environment
2. Lägg till `MCP_AUTH_TOKEN` = `Yry0+YTH3Y6XzmY89S7WOVayw2ksIte1hgedTYC1L9U=`
3. Save Changes (auto-deploy)

### Steg 4: Hämta URL
Efter deploy (tar 2-3 min):
- URL: `https://kolada-mcp.onrender.com`
- SSE Endpoint: `https://kolada-mcp.onrender.com/sse`

### Steg 5: Uppdatera Lovable Config
```json
{
  "mcpServers": {
    "kolada": {
      "url": "https://kolada-mcp.onrender.com/sse",
      "transport": "sse",
      "headers": {
        "Authorization": "Bearer Yry0+YTH3Y6XzmY89S7WOVayw2ksIte1hgedTYC1L9U="
      }
    }
  }
}
```

✅ **KLART! Nu funkar det från vilken dator som helst!**

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## Metod 2: Manuell Deploy (5 MIN)

### Steg 1: Skapa Render Account
1. Gå till https://render.com
2. Sign up med GitHub

### Steg 2: New Web Service
1. Dashboard → **New +** → **Web Service**
2. Connect repository: `KSAklfszf921/kolada-mcp-server`
3. Om inte listad: Configure Account → Install Render

### Steg 3: Konfigurera Service
```
Name:              kolada-mcp
Region:            Frankfurt
Branch:            main
Root Directory:    (lämna tom)
Runtime:           Node
Build Command:     npm install && npm run build
Start Command:     npm run start:http
Instance Type:     Free
```

### Steg 4: Environment Variables
Klicka **Advanced** → Add Environment Variable:

```
MCP_MODE = http
MCP_AUTH_TOKEN = Yry0+YTH3Y6XzmY89S7WOVayw2ksIte1hgedTYC1L9U=
```

### Steg 5: Create Web Service
Klicka **Create Web Service** → Vänta 2-3 min på deploy

### Steg 6: Testa
```bash
# Hämta din URL från Render Dashboard
curl https://your-service.onrender.com/health

# Ska returnera:
# {"status":"ok","service":"kolada-mcp-server","version":"1.0.0","authenticated":true}
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔄 Auto-Deploy

Varje gång du pushar till GitHub main branch → Render deployas automatiskt!

```bash
cd /tmp/kolada-mcp-server
git add .
git commit -m "Update server"
git push origin main
# → Render startar auto-deploy
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ⏰ Håll Servern Vaken (Stoppa Auto-Sleep)

Gratis Render sover efter 15 min inaktivitet. Lösning:

### Alternativ 1: UptimeRobot (Rekommenderat)
1. Gå till https://uptimerobot.com (gratis)
2. Add New Monitor
3. Monitor Type: **HTTP(s)**
4. Friendly Name: `Kolada MCP`
5. URL: `https://your-service.onrender.com/health`
6. Monitoring Interval: **5 minutes**
7. Create Monitor

✅ Servern pingas var 5:e minut → Aldrig auto-sleep!

### Alternativ 2: Cron-job.org
1. https://cron-job.org/en/ (gratis)
2. Create cronjob
3. URL: `https://your-service.onrender.com/health`
4. Schedule: `*/5 * * * *` (var 5:e minut)
5. Create

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 📊 Monitoring

### Logs
Render Dashboard → Logs → Se all server-aktivitet i realtid

### Metrics
Render Dashboard → Metrics → CPU, Memory, Bandwidth

### Health Check
```bash
curl https://your-service.onrender.com/health
```

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🔒 Säkerhet

### Rotera Token
1. Generera ny token:
   ```bash
   openssl rand -base64 32
   ```

2. Uppdatera i Render:
   - Dashboard → Environment → Edit `MCP_AUTH_TOKEN`
   - Save Changes (auto-restart)

3. Uppdatera i Lovable:
   - Ändra `Authorization` header till nya token

### HTTPS
✅ Render ger automatisk HTTPS - ingen config behövs!

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 🐛 Troubleshooting

### "Build failed"
- Kolla Logs i Render Dashboard
- Verifiera att package.json finns
- Testa lokalt: `npm run build`

### "Deploy live but 503 error"
- Vänta 1 min (container startar)
- Kolla Logs för error messages
- Verifiera `MCP_MODE=http` är satt

### "401 Unauthorized"
- Token saknas eller fel i Lovable config
- Verifiera token matchar mellan Render och Lovable

### "Service sleeping"
- Normal behavior för Free tier
- Setup UptimeRobot (se ovan)
- Första anropet tar 30-50 sek

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## 💰 Kostnad

### Free Tier Limits:
- ✅ 750 timmar/månad (31 dagar)
- ✅ 512 MB RAM
- ✅ Unlimited requests
- ✅ 100 GB bandwidth/månad
- ✅ Automatisk HTTPS
- ⚠️  Auto-sleep efter 15 min

**Total kostnad: $0/månad** 🎉

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

## ✅ Checklist

- [ ] Skapat Render account
- [ ] Deployed Web Service
- [ ] Satt environment variables
- [ ] Testat /health endpoint
- [ ] Uppdaterat Lovable config
- [ ] Testat från Lovable
- [ ] (Valfritt) Setup UptimeRobot
- [ ] 🎉 Kolada MCP funkar globalt!
