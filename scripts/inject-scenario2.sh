#!/bin/bash
# Scenario 2: Table & Index Bloat / Dead Tuples
# Generates heavy dead-tuple churn on order_events table
set -e

echo "=== Injecting Scenario 2: Table & Index Bloat ==="

CLUSTER_ARN=$(aws rds describe-db-clusters --db-cluster-identifier aurora-postgres-cluster-1 \
  --query "DBClusters[0].DBClusterArn" --output text)
SECRET_ARN=$(aws cloudformation describe-stacks --stack-name aurora-mcp-server \
  --query "Stacks[0].Outputs[?OutputKey=='DBCredentialsSecretArn'].OutputValue" --output text)

run_sql() {
  aws rds-data execute-statement \
    --resource-arn "$CLUSTER_ARN" \
    --secret-arn "$SECRET_ARN" \
    --database postgres \
    --sql "$1" > /dev/null
}

echo ""
echo "1. Disabling autovacuum on order_events..."
run_sql "ALTER TABLE order_events SET (autovacuum_enabled = false)"

echo "2. Generating dead tuples (updating all rows 3 times)..."
for i in 1 2 3; do
  echo "   Pass $i/3..."
  run_sql "UPDATE order_events SET status = status"
done

echo ""
echo "=== Scenario 2 Injected ==="
echo ""
echo "The order_events table now has heavy dead-tuple bloat."
echo "Queries will gradually slow down as the table bloats."
echo ""
echo "Ask DevOps Agent:"
echo "  \"Queries on order_events are getting progressively slower. CloudWatch shows"
echo "   a gentle rise in IOPS but no clear anomaly. Can you investigate?\""
