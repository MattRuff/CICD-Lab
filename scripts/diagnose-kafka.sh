#!/bin/bash
# Kafka diagnostic script for troubleshooting connection issues

set -e

NAMESPACE="${NAMESPACE:-task-app}"
RELEASE_NAME="${RELEASE_NAME:-task-manager}"

echo "=== Kafka Diagnostics ==="
echo ""

echo "1. Checking Zookeeper status..."
kubectl get pods -n "$NAMESPACE" -l app=zookeeper
echo ""

echo "2. Checking Kafka pod status..."
kubectl get pods -n "$NAMESPACE" -l app=kafka
echo ""

echo "3. Checking Kafka service..."
kubectl get svc -n "$NAMESPACE" "${RELEASE_NAME}-kafka"
echo ""

echo "4. Getting Kafka pod logs (last 50 lines)..."
KAFKA_POD=$(kubectl get pods -n "$NAMESPACE" -l app=kafka -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$KAFKA_POD" ]; then
  echo "Kafka pod: $KAFKA_POD"
  kubectl logs -n "$NAMESPACE" "$KAFKA_POD" --tail=50
else
  echo "No Kafka pod found!"
fi
echo ""

echo "5. Checking if Kafka is listening on port 9092..."
if [ -n "$KAFKA_POD" ]; then
  echo "Running netstat in Kafka pod..."
  kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- sh -c "netstat -tuln | grep 9092 || echo 'Port 9092 not listening!'"
fi
echo ""

echo "6. Testing Kafka connectivity from within the cluster..."
if [ -n "$KAFKA_POD" ]; then
  echo "Listing Kafka topics..."
  kubectl exec -n "$NAMESPACE" "$KAFKA_POD" -- kafka-topics --bootstrap-server localhost:9092 --list || echo "Failed to connect to Kafka!"
fi
echo ""

echo "7. Checking consumer pod status..."
kubectl get pods -n "$NAMESPACE" -l app=consumer
echo ""

echo "8. Getting consumer logs (last 30 lines)..."
CONSUMER_POD=$(kubectl get pods -n "$NAMESPACE" -l app=consumer -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
if [ -n "$CONSUMER_POD" ]; then
  echo "Consumer pod: $CONSUMER_POD"
  kubectl logs -n "$NAMESPACE" "$CONSUMER_POD" --tail=30
else
  echo "No consumer pod found!"
fi
echo ""

echo "=== End Diagnostics ==="

