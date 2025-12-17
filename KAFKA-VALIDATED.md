# Kafka Configuration - Validated on Minikube

## Status: ✅ WORKING

Date: December 17, 2025
Environment: Minikube (ARM64 Mac)

## Validation Results

### All Pods Running
```
NAME                                       READY   STATUS    RESTARTS   AGE
task-manager-backend-c58dc8f74-frchr       1/1     Running   0          2m
task-manager-backend-c58dc8f74-nqjqs       1/1     Running   0          2m
task-manager-consumer-8498767b94-2fnvl     1/1     Running   0          2m
task-manager-frontend-7fc5476cb4-bcvb6     1/1     Running   0          2m
task-manager-frontend-7fc5476cb4-m9zjz     1/1     Running   0          2m
task-manager-kafka-5f74bd6b95-c2hlv        1/1     Running   0          2m
task-manager-postgresql-869d6f7dfd-ssgqk   1/1     Running   0          2m
task-manager-zookeeper-57bf49bf7f-v6rp6    1/1     Running   0          2m
```

### Consumer Successfully Connected
From consumer logs:
```
2025-12-17 20:43:02,780 - kafka.conn - INFO - Connection complete.
2025-12-17 20:43:02,887 - kafka.conn - INFO - Broker version identified as 2.5.0
2025-12-17 20:43:02,899 - __main__ - INFO - Consumer ready, waiting for messages...
2025-12-17 20:43:07,194 - kafka.coordinator - INFO - Successfully joined group task-consumer-group
2025-12-17 20:43:07,194 - kafka.consumer.subscription_state - INFO - Updated partition assignment: [TopicPartition(topic='task-events', partition=0)]
```

### Kafka Topic Created
From Kafka logs:
```
[2025-12-17 20:43:04,005] INFO Created log for partition task-events-0 in /var/lib/kafka/data/task-events-0
[2025-12-17 20:43:04,006] INFO [Partition task-events-0 broker=1] Log loaded for partition task-events-0
```

## Working Configuration

### Simple Single-Listener Setup
The key to success was simplifying from a dual-listener configuration to a single-listener setup:

**Environment Variables:**
```yaml
- KAFKA_BROKER_ID=1
- KAFKA_ZOOKEEPER_CONNECT=task-manager-zookeeper:2181
- KAFKA_LISTENERS=PLAINTEXT://0.0.0.0:9092
- KAFKA_ADVERTISED_LISTENERS=PLAINTEXT://task-manager-kafka:9092
- KAFKA_LISTENER_SECURITY_PROTOCOL_MAP=PLAINTEXT:PLAINTEXT
- KAFKA_INTER_BROKER_LISTENER_NAME=PLAINTEXT
- KAFKA_OFFSETS_TOPIC_REPLICATION_FACTOR=1
- KAFKA_AUTO_CREATE_TOPICS_ENABLE=true
```

**Health Checks:**
Changed from exec-based checks (kafka-topics command) to TCP socket checks:
```yaml
livenessProbe:
  tcpSocket:
    port: 9092
  initialDelaySeconds: 60
  periodSeconds: 30
readinessProbe:
  tcpSocket:
    port: 9092
  initialDelaySeconds: 30
  periodSeconds: 10
```

## What Fixed It

1. **Removed Dual Listener Complexity**: The initial configuration tried to use separate INTERNAL and EXTERNAL listeners which caused controller connection issues
2. **Single Listener on 9092**: Using one PLAINTEXT listener for all communication
3. **TCP Health Checks**: More reliable than exec-based checks that require kafka-topics command
4. **Fresh Install**: Cleared old Zookeeper state by doing a complete uninstall/reinstall

## Deployment Command

```bash
# Deploy to Minikube
helm install task-manager ./helm/task-manager \
  -f helm/task-manager/values-lab.yaml \
  --set namespace.create=false \
  -n task-app

# If namespace doesn't exist, create it first:
kubectl create namespace task-app
```

## Testing

### Check All Pods
```bash
kubectl get pods -n task-app
```

### Check Consumer Logs
```bash
kubectl logs -n task-app -l app=consumer --tail=50
```

### Check Kafka Logs
```bash
kubectl logs -n task-app -l app=kafka --tail=50
```

### Run Diagnostics
```bash
./scripts/diagnose-kafka.sh
```

## Access the Application

Get the frontend URL:
```bash
minikube service task-manager-frontend -n task-app --url
```

Or use port-forward:
```bash
kubectl port-forward -n task-app svc/task-manager-frontend 8080:80
# Then access at http://localhost:8080
```

## Notes

- Kafka auto-creates topics when messages are published
- Consumer joins `task-consumer-group` and receives partition assignments
- All pods are healthy and ready
- Configuration is optimized for single-broker Minikube deployment
- Health checks use TCP sockets which are more reliable in containerized environments

## Next Steps

This configuration has been committed to the repository and will be used in the CI/CD pipeline for building and deploying to production-like environments.

