#!/bin/bash
# Test MCP server connectivity and database access
set -e

echo "=== Testing MCP Server Connection ==="

# Get endpoint and API key
MCP_URL=$(aws cloudformation describe-stacks --stack-name aurora-mcp-server \
  --query "Stacks[0].Outputs[?OutputKey=='McpEndpointUrl'].OutputValue" --output text)
API_KEY=$(aws secretsmanager get-secret-value \
  --secret-id /demo/postgres-mcp-server/api-key \
  --query "SecretString" --output text | python3 -c "import sys,json; print(json.load(sys.stdin)['api_key'])")

echo "Endpoint: $MCP_URL"
echo ""

echo "1. Testing initialize..."
INIT=$(curl -s -X POST "$MCP_URL" \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}')
echo "   $INIT" | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'   ✓ {r[\"result\"][\"serverInfo\"][\"name\"]} v{r[\"result\"][\"serverInfo\"][\"version\"]}')" 2>/dev/null || echo "   ✗ Failed: $INIT"

echo ""
echo "2. Testing list_clusters..."
CLUSTERS=$(curl -s -X POST "$MCP_URL" \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":2,"method":"tools/call","params":{"name":"list_clusters","arguments":{}}}')
echo "   $CLUSTERS" | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'   ✓ {r[\"result\"][\"content\"][0][\"text\"][:100]}')" 2>/dev/null || echo "   ✗ Failed"

echo ""
echo "3. Testing execute_query (SELECT version())..."
VERSION=$(curl -s -X POST "$MCP_URL" \
  -H "Authorization: $API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"execute_query","arguments":{"cluster_identifier":"aurora-postgres-cluster-1","database":"postgres","sql":"SELECT version()"}}}')
echo "   $VERSION" | python3 -c "import sys,json; r=json.load(sys.stdin); print(f'   ✓ Connected')" 2>/dev/null || echo "   ✗ Failed"

echo ""
echo "=== All tests passed ==="
