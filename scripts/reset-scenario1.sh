#!/bin/bash
# Reset Scenario 1: Restore sequence to a safe value
set -e

echo "=== Resetting Scenario 1: Sequence Exhaustion ==="

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

echo "1. Resetting orders_id_seq to 100001..."
run_sql "ALTER SEQUENCE orders_id_seq RESTART WITH 100001"

echo "2. Verifying INSERT works..."
run_sql "INSERT INTO orders (customer_id, total) VALUES (1, 10.00)"

echo ""
echo "=== Scenario 1 Reset Complete ==="
echo "Inserts are working again. Ready for next demo run."
