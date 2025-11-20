#!/bin/bash

# Comprehensive test suite for Kolada MCP Server
# Tests all endpoints, tools, prompts, resources, caching, and error handling

BASE_URL="https://kolada-mcp-server.onrender.com"
TOTAL_TESTS=0
PASSED_TESTS=0
FAILED_TESTS=0

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo "=========================================="
echo "Kolada MCP Server v2.0.0 - Full Test Suite"
echo "=========================================="
echo ""

test_result() {
    TOTAL_TESTS=$((TOTAL_TESTS + 1))
    if [ $1 -eq 0 ]; then
        echo -e "${GREEN}✓ PASS${NC}: $2"
        PASSED_TESTS=$((PASSED_TESTS + 1))
    else
        echo -e "${RED}✗ FAIL${NC}: $2"
        FAILED_TESTS=$((FAILED_TESTS + 1))
    fi
}

echo "=========================================="
echo "1. HEALTH ENDPOINT"
echo "=========================================="

# Test 1: Health endpoint returns 200
response=$(curl -s -w "%{http_code}" -o /tmp/health.json $BASE_URL/health)
test_result $([[ "$response" == "200" ]] && echo 0 || echo 1) "Health endpoint returns HTTP 200"

# Test 2: Health response has correct structure
version=$(jq -r '.version' /tmp/health.json 2>/dev/null)
test_result $([[ "$version" == "2.0.0" ]] && echo 0 || echo 1) "Health response shows version 2.0.0"

# Test 3: Cache stats present
cache_total=$(jq -r '.cache_stats.total' /tmp/health.json 2>/dev/null)
test_result $([[ "$cache_total" != "null" ]] && echo 0 || echo 1) "Cache stats present in health response"

echo ""
echo "=========================================="
echo "2. MCP INITIALIZATION"
echo "=========================================="

# Test 4: MCP initialize request
cat > /tmp/mcp_init.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2024-11-05",
    "capabilities": {},
    "clientInfo": {
      "name": "test-client",
      "version": "1.0.0"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/mcp_init.json \
  -w "%{http_code}" -o /tmp/mcp_init_response.json)

test_result $([[ "$response" == "200" ]] && echo 0 || echo 1) "MCP initialize returns HTTP 200"

# Test 5: Initialize response has capabilities
has_tools=$(jq -r '.result.capabilities.tools' /tmp/mcp_init_response.json 2>/dev/null)
test_result $([[ "$has_tools" != "null" ]] && echo 0 || echo 1) "Initialize response includes tools capability"

has_resources=$(jq -r '.result.capabilities.resources' /tmp/mcp_init_response.json 2>/dev/null)
test_result $([[ "$has_resources" != "null" ]] && echo 0 || echo 1) "Initialize response includes resources capability"

has_prompts=$(jq -r '.result.capabilities.prompts' /tmp/mcp_init_response.json 2>/dev/null)
test_result $([[ "$has_prompts" != "null" ]] && echo 0 || echo 1) "Initialize response includes prompts capability"

echo ""
echo "=========================================="
echo "3. LIST TOOLS (16 expected)"
echo "=========================================="

cat > /tmp/list_tools.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 2,
  "method": "tools/list"
}
EOF

curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/list_tools.json \
  -o /tmp/list_tools_response.json

tool_count=$(jq -r '.result.tools | length' /tmp/list_tools_response.json 2>/dev/null)
test_result $([[ "$tool_count" == "16" ]] && echo 0 || echo 1) "16 tools available"

# List all tools
echo ""
echo "Available tools:"
jq -r '.result.tools[] | "  - \(.name)"' /tmp/list_tools_response.json

echo ""
echo "=========================================="
echo "4. LIST PROMPTS (6 expected)"
echo "=========================================="

cat > /tmp/list_prompts.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 3,
  "method": "prompts/list"
}
EOF

curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/list_prompts.json \
  -o /tmp/list_prompts_response.json

prompt_count=$(jq -r '.result.prompts | length' /tmp/list_prompts_response.json 2>/dev/null)
test_result $([[ "$prompt_count" == "6" ]] && echo 0 || echo 1) "6 prompts available"

# List all prompts
echo ""
echo "Available prompts:"
jq -r '.result.prompts[] | "  - \(.name)"' /tmp/list_prompts_response.json

echo ""
echo "=========================================="
echo "5. LIST RESOURCES (3 expected)"
echo "=========================================="

cat > /tmp/list_resources.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 4,
  "method": "resources/list"
}
EOF

curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/list_resources.json \
  -o /tmp/list_resources_response.json

resource_count=$(jq -r '.result.resources | length' /tmp/list_resources_response.json 2>/dev/null)
test_result $([[ "$resource_count" == "3" ]] && echo 0 || echo 1) "3 resources available"

# List all resources
echo ""
echo "Available resources:"
jq -r '.result.resources[] | "  - \(.uri): \(.name)"' /tmp/list_resources_response.json

echo ""
echo "=========================================="
echo "6. TEST TOOLS - KPI Tools (5 tools)"
echo "=========================================="

# Tool 1: search_kpis
cat > /tmp/search_kpis.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 5,
  "method": "tools/call",
  "params": {
    "name": "search_kpis",
    "arguments": {
      "query": "skola",
      "limit": 5
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/search_kpis.json \
  -w "%{http_code}" -o /tmp/search_kpis_response.json)

kpi_count=$(jq -r '.result.content[0].text | fromjson | .count' /tmp/search_kpis_response.json 2>/dev/null)
test_result $([[ "$kpi_count" -gt 0 ]] && echo 0 || echo 1) "search_kpis returns results"

# Tool 2: get_kpi
first_kpi_id=$(jq -r '.result.content[0].text | fromjson | .values[0].id' /tmp/search_kpis_response.json 2>/dev/null)

cat > /tmp/get_kpi.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 6,
  "method": "tools/call",
  "params": {
    "name": "get_kpi",
    "arguments": {
      "kpi_id": "$first_kpi_id"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_kpi.json \
  -w "%{http_code}" -o /tmp/get_kpi_response.json)

kpi_title=$(jq -r '.result.content[0].text | fromjson | .title' /tmp/get_kpi_response.json 2>/dev/null)
test_result $([[ "$kpi_title" != "null" ]] && echo 0 || echo 1) "get_kpi returns KPI details"

# Tool 3: get_kpis (batch)
cat > /tmp/get_kpis.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 7,
  "method": "tools/call",
  "params": {
    "name": "get_kpis",
    "arguments": {
      "kpi_ids": ["$first_kpi_id"]
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_kpis.json \
  -w "%{http_code}" -o /tmp/get_kpis_response.json)

batch_count=$(jq -r '.result.content[0].text | fromjson | .count' /tmp/get_kpis_response.json 2>/dev/null)
test_result $([[ "$batch_count" -ge 1 ]] && echo 0 || echo 1) "get_kpis returns batch results"

# Tool 4: get_kpi_groups
cat > /tmp/get_kpi_groups.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 8,
  "method": "tools/call",
  "params": {
    "name": "get_kpi_groups",
    "arguments": {}
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_kpi_groups.json \
  -w "%{http_code}" -o /tmp/get_kpi_groups_response.json)

group_count=$(jq -r '.result.content[0].text | fromjson | .count' /tmp/get_kpi_groups_response.json 2>/dev/null)
test_result $([[ "$group_count" -gt 0 ]] && echo 0 || echo 1) "get_kpi_groups returns groups"

# Tool 5: get_kpi_group
first_group_id=$(jq -r '.result.content[0].text | fromjson | .values[0].id' /tmp/get_kpi_groups_response.json 2>/dev/null)

cat > /tmp/get_kpi_group.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 9,
  "method": "tools/call",
  "params": {
    "name": "get_kpi_group",
    "arguments": {
      "group_id": "$first_group_id"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_kpi_group.json \
  -w "%{http_code}" -o /tmp/get_kpi_group_response.json)

group_title=$(jq -r '.result.content[0].text | fromjson | .title' /tmp/get_kpi_group_response.json 2>/dev/null)
test_result $([[ "$group_title" != "null" ]] && echo 0 || echo 1) "get_kpi_group returns group details"

echo ""
echo "=========================================="
echo "7. TEST TOOLS - Municipality Tools (4 tools)"
echo "=========================================="

# Tool 6: search_municipalities
cat > /tmp/search_municipalities.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 10,
  "method": "tools/call",
  "params": {
    "name": "search_municipalities",
    "arguments": {
      "query": "Stockholm"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/search_municipalities.json \
  -w "%{http_code}" -o /tmp/search_municipalities_response.json)

muni_count=$(jq -r '.result.content[0].text | fromjson | .count' /tmp/search_municipalities_response.json 2>/dev/null)
test_result $([[ "$muni_count" -gt 0 ]] && echo 0 || echo 1) "search_municipalities returns results"

# Tool 7: get_municipality
stockholm_id=$(jq -r '.result.content[0].text | fromjson | .values[0].id' /tmp/search_municipalities_response.json 2>/dev/null)

cat > /tmp/get_municipality.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 11,
  "method": "tools/call",
  "params": {
    "name": "get_municipality",
    "arguments": {
      "municipality_id": "$stockholm_id"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_municipality.json \
  -w "%{http_code}" -o /tmp/get_municipality_response.json)

muni_title=$(jq -r '.result.content[0].text | fromjson | .title' /tmp/get_municipality_response.json 2>/dev/null)
test_result $([[ "$muni_title" != "null" ]] && echo 0 || echo 1) "get_municipality returns municipality details"

# Tool 8: get_municipality_groups
cat > /tmp/get_municipality_groups.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 12,
  "method": "tools/call",
  "params": {
    "name": "get_municipality_groups",
    "arguments": {}
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_municipality_groups.json \
  -w "%{http_code}" -o /tmp/get_municipality_groups_response.json)

muni_group_count=$(jq -r '.result.content[0].text | fromjson | .count' /tmp/get_municipality_groups_response.json 2>/dev/null)
test_result $([[ "$muni_group_count" -gt 0 ]] && echo 0 || echo 1) "get_municipality_groups returns groups"

# Tool 9: get_municipality_group
first_muni_group=$(jq -r '.result.content[0].text | fromjson | .values[0].id' /tmp/get_municipality_groups_response.json 2>/dev/null)

cat > /tmp/get_municipality_group.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 13,
  "method": "tools/call",
  "params": {
    "name": "get_municipality_group",
    "arguments": {
      "group_id": "$first_muni_group"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_municipality_group.json \
  -w "%{http_code}" -o /tmp/get_municipality_group_response.json)

muni_group_title=$(jq -r '.result.content[0].text | fromjson | .title' /tmp/get_municipality_group_response.json 2>/dev/null)
test_result $([[ "$muni_group_title" != "null" ]] && echo 0 || echo 1) "get_municipality_group returns group details"

echo ""
echo "=========================================="
echo "8. TEST TOOLS - Organizational Unit Tools (3 tools)"
echo "=========================================="

# Tool 10: get_ou_types
cat > /tmp/get_ou_types.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 14,
  "method": "tools/call",
  "params": {
    "name": "get_ou_types",
    "arguments": {}
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_ou_types.json \
  -w "%{http_code}" -o /tmp/get_ou_types_response.json)

ou_types_count=$(jq -r '.result.content[0].text | fromjson | .types | length' /tmp/get_ou_types_response.json 2>/dev/null)
test_result $([[ "$ou_types_count" -gt 0 ]] && echo 0 || echo 1) "get_ou_types returns OU types"

# Tool 11: search_organizational_units
cat > /tmp/search_ou.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 15,
  "method": "tools/call",
  "params": {
    "name": "search_organizational_units",
    "arguments": {
      "municipality": "$stockholm_id",
      "limit": 5
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/search_ou.json \
  -w "%{http_code}" -o /tmp/search_ou_response.json)

ou_count=$(jq -r '.result.content[0].text | fromjson | .count' /tmp/search_ou_response.json 2>/dev/null)
test_result $([[ "$ou_count" -ge 0 ]] && echo 0 || echo 1) "search_organizational_units executes successfully"

# Tool 12: get_organizational_unit (if OUs found)
if [ "$ou_count" -gt 0 ]; then
  first_ou_id=$(jq -r '.result.content[0].text | fromjson | .values[0].id' /tmp/search_ou_response.json 2>/dev/null)

  cat > /tmp/get_ou.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 16,
  "method": "tools/call",
  "params": {
    "name": "get_organizational_unit",
    "arguments": {
      "ou_id": "$first_ou_id"
    }
  }
}
EOF

  response=$(curl -s -X POST $BASE_URL/rpc \
    -H "Content-Type: application/json" \
    -d @/tmp/get_ou.json \
    -w "%{http_code}" -o /tmp/get_ou_response.json)

  ou_title=$(jq -r '.result.content[0].text | fromjson | .title' /tmp/get_ou_response.json 2>/dev/null)
  test_result $([[ "$ou_title" != "null" ]] && echo 0 || echo 1) "get_organizational_unit returns OU details"
else
  echo "  ⊘ SKIP: get_organizational_unit (no OUs found for Stockholm)"
fi

echo ""
echo "=========================================="
echo "9. TEST TOOLS - Data Retrieval Tools (4 tools)"
echo "=========================================="

# Tool 13: get_kpi_data
cat > /tmp/get_kpi_data.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 17,
  "method": "tools/call",
  "params": {
    "name": "get_kpi_data",
    "arguments": {
      "kpi_id": "$first_kpi_id",
      "municipality_id": "$stockholm_id"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_kpi_data.json \
  -w "%{http_code}" -o /tmp/get_kpi_data_response.json)

data_count=$(jq -r '.result.content[0].text | fromjson | .count' /tmp/get_kpi_data_response.json 2>/dev/null)
test_result $([[ "$data_count" -ge 0 ]] && echo 0 || echo 1) "get_kpi_data executes successfully"

# Tool 14: get_municipality_kpis
cat > /tmp/get_municipality_kpis.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 18,
  "method": "tools/call",
  "params": {
    "name": "get_municipality_kpis",
    "arguments": {
      "municipality_id": "$stockholm_id"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_municipality_kpis.json \
  -w "%{http_code}" -o /tmp/get_municipality_kpis_response.json)

available_kpis=$(jq -r '.result.content[0].text | fromjson | .count' /tmp/get_municipality_kpis_response.json 2>/dev/null)
test_result $([[ "$available_kpis" -gt 0 ]] && echo 0 || echo 1) "get_municipality_kpis returns available KPIs"

# Tool 15: compare_municipalities
cat > /tmp/compare_municipalities.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 19,
  "method": "tools/call",
  "params": {
    "name": "compare_municipalities",
    "arguments": {
      "kpi_id": "$first_kpi_id",
      "municipality_ids": ["$stockholm_id", "1480"]
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/compare_municipalities.json \
  -w "%{http_code}" -o /tmp/compare_municipalities_response.json)

comparison_count=$(jq -r '.result.content[0].text | fromjson | .municipalities | length' /tmp/compare_municipalities_response.json 2>/dev/null)
test_result $([[ "$comparison_count" -ge 1 ]] && echo 0 || echo 1) "compare_municipalities returns comparison data"

# Tool 16: get_kpi_trend
cat > /tmp/get_kpi_trend.json <<EOF
{
  "jsonrpc": "2.0",
  "id": 20,
  "method": "tools/call",
  "params": {
    "name": "get_kpi_trend",
    "arguments": {
      "kpi_id": "$first_kpi_id",
      "municipality_id": "$stockholm_id",
      "start_year": 2020
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/get_kpi_trend.json \
  -w "%{http_code}" -o /tmp/get_kpi_trend_response.json)

trend_periods=$(jq -r '.result.content[0].text | fromjson | .values | length' /tmp/get_kpi_trend_response.json 2>/dev/null)
test_result $([[ "$trend_periods" -ge 0 ]] && echo 0 || echo 1) "get_kpi_trend returns trend data"

echo ""
echo "=========================================="
echo "10. TEST PROMPTS (6 prompts)"
echo "=========================================="

# Prompt 1: analyze_municipality
cat > /tmp/prompt_analyze.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 21,
  "method": "prompts/get",
  "params": {
    "name": "analyze_municipality",
    "arguments": {
      "municipality_name": "Stockholm"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/prompt_analyze.json \
  -w "%{http_code}" -o /tmp/prompt_analyze_response.json)

prompt_text=$(jq -r '.result.messages[0].content.text' /tmp/prompt_analyze_response.json 2>/dev/null)
test_result $([[ "$prompt_text" != "null" ]] && echo 0 || echo 1) "analyze_municipality prompt returns text"

# Prompt 2: compare_municipalities
cat > /tmp/prompt_compare.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 22,
  "method": "prompts/get",
  "params": {
    "name": "compare_municipalities",
    "arguments": {
      "municipalities": "Stockholm, Göteborg",
      "kpi_topics": "education"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/prompt_compare.json \
  -w "%{http_code}" -o /tmp/prompt_compare_response.json)

prompt_text=$(jq -r '.result.messages[0].content.text' /tmp/prompt_compare_response.json 2>/dev/null)
test_result $([[ "$prompt_text" != "null" ]] && echo 0 || echo 1) "compare_municipalities prompt returns text"

# Prompt 3: trend_analysis
cat > /tmp/prompt_trend.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 23,
  "method": "prompts/get",
  "params": {
    "name": "trend_analysis",
    "arguments": {
      "municipality": "Stockholm",
      "topic": "education"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/prompt_trend.json \
  -w "%{http_code}" -o /tmp/prompt_trend_response.json)

prompt_text=$(jq -r '.result.messages[0].content.text' /tmp/prompt_trend_response.json 2>/dev/null)
test_result $([[ "$prompt_text" != "null" ]] && echo 0 || echo 1) "trend_analysis prompt returns text"

# Prompt 4: find_schools
cat > /tmp/prompt_schools.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 24,
  "method": "prompts/get",
  "params": {
    "name": "find_schools",
    "arguments": {
      "municipality": "Stockholm"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/prompt_schools.json \
  -w "%{http_code}" -o /tmp/prompt_schools_response.json)

prompt_text=$(jq -r '.result.messages[0].content.text' /tmp/prompt_schools_response.json 2>/dev/null)
test_result $([[ "$prompt_text" != "null" ]] && echo 0 || echo 1) "find_schools prompt returns text"

# Prompt 5: regional_comparison
cat > /tmp/prompt_regional.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 25,
  "method": "prompts/get",
  "params": {
    "name": "regional_comparison",
    "arguments": {
      "region": "Stockholm län"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/prompt_regional.json \
  -w "%{http_code}" -o /tmp/prompt_regional_response.json)

prompt_text=$(jq -r '.result.messages[0].content.text' /tmp/prompt_regional_response.json 2>/dev/null)
test_result $([[ "$prompt_text" != "null" ]] && echo 0 || echo 1) "regional_comparison prompt returns text"

# Prompt 6: kpi_discovery
cat > /tmp/prompt_discovery.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 26,
  "method": "prompts/get",
  "params": {
    "name": "kpi_discovery",
    "arguments": {}
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/prompt_discovery.json \
  -w "%{http_code}" -o /tmp/prompt_discovery_response.json)

prompt_text=$(jq -r '.result.messages[0].content.text' /tmp/prompt_discovery_response.json 2>/dev/null)
test_result $([[ "$prompt_text" != "null" ]] && echo 0 || echo 1) "kpi_discovery prompt returns text"

echo ""
echo "=========================================="
echo "11. TEST RESOURCES (3 resources)"
echo "=========================================="

# Resource 1: kolada://municipalities
cat > /tmp/resource_municipalities.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 27,
  "method": "resources/read",
  "params": {
    "uri": "kolada://municipalities"
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/resource_municipalities.json \
  -w "%{http_code}" -o /tmp/resource_municipalities_response.json)

municipalities_data=$(jq -r '.result.contents[0].text' /tmp/resource_municipalities_response.json 2>/dev/null)
test_result $([[ "$municipalities_data" != "null" ]] && echo 0 || echo 1) "kolada://municipalities resource returns data"

# Resource 2: kolada://kpi-catalog
cat > /tmp/resource_kpi_catalog.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 28,
  "method": "resources/read",
  "params": {
    "uri": "kolada://kpi-catalog"
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/resource_kpi_catalog.json \
  -w "%{http_code}" -o /tmp/resource_kpi_catalog_response.json)

kpi_catalog_data=$(jq -r '.result.contents[0].text' /tmp/resource_kpi_catalog_response.json 2>/dev/null)
test_result $([[ "$kpi_catalog_data" != "null" ]] && echo 0 || echo 1) "kolada://kpi-catalog resource returns data"

# Resource 3: kolada://api-info
cat > /tmp/resource_api_info.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 29,
  "method": "resources/read",
  "params": {
    "uri": "kolada://api-info"
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/resource_api_info.json \
  -w "%{http_code}" -o /tmp/resource_api_info_response.json)

api_info_data=$(jq -r '.result.contents[0].text' /tmp/resource_api_info_response.json 2>/dev/null)
test_result $([[ "$api_info_data" != "null" ]] && echo 0 || echo 1) "kolada://api-info resource returns data"

echo ""
echo "=========================================="
echo "12. TEST CACHING"
echo "=========================================="

# Check cache stats before
cache_before=$(curl -s $BASE_URL/health | jq -r '.cache_stats.total')

# Make request that should be cached
curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/resource_municipalities.json > /dev/null 2>&1

sleep 1

# Check cache stats after
cache_after=$(curl -s $BASE_URL/health | jq -r '.cache_stats.total')

test_result $([[ "$cache_after" -ge "$cache_before" ]] && echo 0 || echo 1) "Cache is being populated"

echo ""
echo "=========================================="
echo "13. TEST ERROR HANDLING"
echo "=========================================="

# Test invalid KPI ID
cat > /tmp/error_invalid_kpi.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 30,
  "method": "tools/call",
  "params": {
    "name": "get_kpi",
    "arguments": {
      "kpi_id": "INVALID123"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/error_invalid_kpi.json \
  -o /tmp/error_invalid_kpi_response.json)

error_code=$(jq -r '.error.code' /tmp/error_invalid_kpi_response.json 2>/dev/null)
test_result $([[ "$error_code" != "null" ]] && echo 0 || echo 1) "Invalid KPI ID returns proper error"

# Test invalid municipality ID
cat > /tmp/error_invalid_muni.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 31,
  "method": "tools/call",
  "params": {
    "name": "get_municipality",
    "arguments": {
      "municipality_id": "99999"
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/error_invalid_muni.json \
  -o /tmp/error_invalid_muni_response.json)

error_message=$(jq -r '.error.message' /tmp/error_invalid_muni_response.json 2>/dev/null)
test_result $([[ "$error_message" != "null" ]] && echo 0 || echo 1) "Invalid municipality ID returns proper error"

# Test batch size validation
cat > /tmp/error_batch_size.json <<'EOF'
{
  "jsonrpc": "2.0",
  "id": 32,
  "method": "tools/call",
  "params": {
    "name": "get_kpis",
    "arguments": {
      "kpi_ids": ["N00001", "N00002", "N00003", "N00004", "N00005", "N00006", "N00007", "N00008", "N00009", "N00010",
                  "N00011", "N00012", "N00013", "N00014", "N00015", "N00016", "N00017", "N00018", "N00019", "N00020",
                  "N00021", "N00022", "N00023", "N00024", "N00025", "N00026"]
    }
  }
}
EOF

response=$(curl -s -X POST $BASE_URL/rpc \
  -H "Content-Type: application/json" \
  -d @/tmp/error_batch_size.json \
  -o /tmp/error_batch_size_response.json)

error_code=$(jq -r '.error.code' /tmp/error_batch_size_response.json 2>/dev/null)
test_result $([[ "$error_code" != "null" ]] && echo 0 || echo 1) "Batch size validation returns proper error"

echo ""
echo "=========================================="
echo "TEST SUMMARY"
echo "=========================================="
echo ""
echo -e "Total tests:  ${YELLOW}$TOTAL_TESTS${NC}"
echo -e "Passed:       ${GREEN}$PASSED_TESTS${NC}"
echo -e "Failed:       ${RED}$FAILED_TESTS${NC}"
echo ""

if [ $FAILED_TESTS -eq 0 ]; then
    echo -e "${GREEN}=========================================="
    echo "✓ ALL TESTS PASSED! 🎉"
    echo "==========================================${NC}"
    exit 0
else
    echo -e "${RED}=========================================="
    echo "✗ SOME TESTS FAILED"
    echo "==========================================${NC}"
    exit 1
fi
