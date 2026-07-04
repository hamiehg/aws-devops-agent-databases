#!/bin/bash
# One-command deployment for AWS DevOps Agent for Databases demo
set -e

echo "=============================================="
echo " AWS DevOps Agent for AWS Databases"
echo " One-Command Deployment"
echo "=============================================="
echo ""

# Check prerequisites
command -v aws >/dev/null 2>&1 || { echo "ERROR: AWS CLI not found. Install it first."; exit 1; }
command -v python3 >/dev/null 2>&1 || { echo "ERROR: python3 not found. Install it first."; exit 1; }

# Require VPC and subnet parameters
if [ -z "$VPC_ID" ] || [ -z "$SUBNET_ID_1" ] || [ -z "$SUBNET_ID_2" ]; then
  echo "Please set environment variables before running:"
  echo ""
  echo "  export VPC_ID=vpc-xxxxxxxxx"
  echo "  export SUBNET_ID_1=subnet-xxxxxxx"
  echo "  export SUBNET_ID_2=subnet-yyyyyyy"
  echo "  export AWS_REGION=us-east-1  (optional, defaults to us-east-1)"
  echo ""
  echo "Then re-run: bash scripts/deploy-all.sh"
  exit 1
fi

REGION=${AWS_REGION:-us-east-1}
echo "Region: $REGION"
echo "VPC: $VPC_ID"
echo "Subnets: $SUBNET_ID_1, $SUBNET_ID_2"
echo ""

# Step 1: Deploy Aurora cluster
echo "=== Step 1/4: Deploying Aurora PostgreSQL cluster ==="
aws cloudformation create-stack \
  --stack-name aurora-postgres-cluster \
  --template-body file://cloudformation/aurora-postgresql-cluster.yaml \
  --parameters \
    ParameterKey=VpcId,ParameterValue=$VPC_ID \
    ParameterKey=SubnetId1,ParameterValue=$SUBNET_ID_1 \
    ParameterKey=SubnetId2,ParameterValue=$SUBNET_ID_2 \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

echo "Waiting for cluster creation (~8-10 minutes)..."
aws cloudformation wait stack-create-complete --stack-name aurora-postgres-cluster --region $REGION
echo "✓ Aurora cluster created"
echo ""

# Step 2: Deploy MCP server
echo "=== Step 2/4: Deploying MCP server ==="
aws cloudformation create-stack \
  --stack-name aurora-mcp-server \
  --template-body file://cloudformation/aurora-postgresql-mcp-server.yaml \
  --parameters \
    ParameterKey=Environment,ParameterValue=demo \
    ParameterKey=DBUsername,ParameterValue=postgres \
    ParameterKey=DBPassword,ParameterValue=Welcome1! \
    ParameterKey=AllowWriteQueries,ParameterValue=true \
  --capabilities CAPABILITY_NAMED_IAM \
  --region $REGION

echo "Waiting for MCP server creation (~3-5 minutes)..."
aws cloudformation wait stack-create-complete --stack-name aurora-mcp-server --region $REGION
echo "✓ MCP server created"
echo ""

# Step 3: Setup test schema
echo "=== Step 3/4: Setting up test schema ==="
bash scripts/setup-schema.sh
echo ""

# Step 4: Test connectivity
echo "=== Step 4/4: Testing connectivity ==="
bash scripts/test-connection.sh
echo ""

# Output
MCP_URL=$(aws cloudformation describe-stacks --stack-name aurora-mcp-server \
  --query "Stacks[0].Outputs[?OutputKey=='McpEndpointUrl'].OutputValue" --output text --region $REGION)

echo "=============================================="
echo " Deployment Complete"
echo "=============================================="
echo ""
echo "MCP Endpoint: $MCP_URL"
echo ""
echo "Next steps:"
echo "  1. Register the MCP server with DevOps Agent (see docs/DEVOPS_AGENT_INTEGRATION.md)"
echo "  2. Run a scenario: bash scripts/inject-scenario1.sh"
echo "  3. Ask DevOps Agent to investigate"
echo ""
