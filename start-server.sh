#!/bin/bash

# Kolada MCP Server Start Script

echo "🚀 Starting Kolada MCP Server..."
echo ""

export MCP_MODE=http
export MCP_AUTH_TOKEN="Yry0+YTH3Y6XzmY89S7WOVayw2ksIte1hgedTYC1L9U="
export PORT=3000

npm run dev:http
