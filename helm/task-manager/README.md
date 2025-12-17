# Task Manager Helm Chart

A Helm chart for deploying the Task Manager microservices application to Kubernetes.

## Prerequisites

- Kubernetes 1.19+
- Helm 3.0+
- PV provisioner support in the underlying infrastructure

## Installing the Chart

### Basic Installation

```bash
helm install task-manager ./helm/task-manager --namespace task-app --create-namespace
```

### Installation with Custom Values

```bash
# Development
helm install task-manager ./helm/task-manager \
  -f helm/task-manager/values-dev.yaml \
  --namespace task-app-dev \
  --create-namespace

# Production
helm install task-manager ./helm/task-manager \
  -f helm/task-manager/values-prod.yaml \
  --namespace task-app-prod \
  --create-namespace
```

### Installation with Specific Values

```bash
helm install task-manager ./helm/task-manager \
  --namespace task-app \
  --create-namespace \
  --set backend.replicaCount=3 \
  --set postgresql.config.password=supersecret
```

## Uninstalling the Chart

```bash
helm uninstall task-manager --namespace task-app
```

This removes all the Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the Task Manager chart and their default values.

### Global Settings

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace.name` | Namespace name | `task-app` |
| `namespace.create` | Create namespace | `true` |

### PostgreSQL

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `postgresql.image.repository` | PostgreSQL image repository | `postgres` |
| `postgresql.image.tag` | PostgreSQL image tag | `16-alpine` |
| `postgresql.config.database` | Database name | `taskdb` |
| `postgresql.config.username` | Database username | `postgres` |
| `postgresql.config.password` | Database password | `postgres` |
| `postgresql.persistence.enabled` | Enable persistence | `true` |
| `postgresql.persistence.size` | PVC size | `1Gi` |
| `postgresql.resources.requests.memory` | Memory request | `256Mi` |
| `postgresql.resources.requests.cpu` | CPU request | `250m` |

### Kafka

| Parameter | Description | Default |
|-----------|-------------|---------|
| `kafka.enabled` | Enable Kafka | `true` |
| `kafka.image.repository` | Kafka image repository | `confluentinc/cp-kafka` |
| `kafka.image.tag` | Kafka image tag | `7.5.0` |
| `kafka.config.brokerId` | Kafka broker ID | `1` |
| `kafka.config.replicationFactor` | Replication factor | `1` |
| `kafka.resources.requests.memory` | Memory request | `512Mi` |
| `kafka.resources.requests.cpu` | CPU request | `500m` |

### Backend

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backend.enabled` | Enable backend | `true` |
| `backend.replicaCount` | Number of replicas | `2` |
| `backend.image.repository` | Backend image repository | `task-backend` |
| `backend.image.tag` | Backend image tag | `latest` |
| `backend.service.type` | Service type | `ClusterIP` |
| `backend.service.port` | Service port | `3000` |
| `backend.autoscaling.enabled` | Enable HPA | `false` |
| `backend.autoscaling.minReplicas` | Minimum replicas | `2` |
| `backend.autoscaling.maxReplicas` | Maximum replicas | `10` |
| `backend.resources.requests.memory` | Memory request | `256Mi` |
| `backend.resources.requests.cpu` | CPU request | `250m` |

### Consumer

| Parameter | Description | Default |
|-----------|-------------|---------|
| `consumer.enabled` | Enable consumer | `true` |
| `consumer.replicaCount` | Number of replicas | `1` |
| `consumer.image.repository` | Consumer image repository | `task-consumer` |
| `consumer.image.tag` | Consumer image tag | `latest` |
| `consumer.resources.requests.memory` | Memory request | `128Mi` |
| `consumer.resources.requests.cpu` | CPU request | `100m` |

### Frontend

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.enabled` | Enable frontend | `true` |
| `frontend.replicaCount` | Number of replicas | `2` |
| `frontend.image.repository` | Frontend image repository | `task-frontend` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `frontend.service.type` | Service type | `LoadBalancer` |
| `frontend.service.port` | Service port | `80` |
| `frontend.autoscaling.enabled` | Enable HPA | `false` |
| `frontend.autoscaling.minReplicas` | Minimum replicas | `2` |
| `frontend.autoscaling.maxReplicas` | Maximum replicas | `10` |
| `frontend.resources.requests.memory` | Memory request | `128Mi` |
| `frontend.resources.requests.cpu` | CPU request | `100m` |

## Examples

### Scale Backend

```bash
helm upgrade task-manager ./helm/task-manager \
  --namespace task-app \
  --set backend.replicaCount=5 \
  --reuse-values
```

### Enable Autoscaling

```bash
helm upgrade task-manager ./helm/task-manager \
  --namespace task-app \
  --set backend.autoscaling.enabled=true \
  --set frontend.autoscaling.enabled=true \
  --reuse-values
```

### Change Database Password

```bash
helm upgrade task-manager ./helm/task-manager \
  --namespace task-app \
  --set postgresql.config.password=newsecretpassword \
  --reuse-values
```

### Disable a Component

```bash
helm upgrade task-manager ./helm/task-manager \
  --namespace task-app \
  --set consumer.enabled=false \
  --reuse-values
```

## Upgrading

```bash
# Upgrade with new values
helm upgrade task-manager ./helm/task-manager \
  --namespace task-app \
  -f helm/task-manager/values.yaml

# Upgrade and wait for completion
helm upgrade task-manager ./helm/task-manager \
  --namespace task-app \
  --wait \
  --timeout 5m
```

## Rollback

```bash
# List releases
helm history task-manager --namespace task-app

# Rollback to previous version
helm rollback task-manager --namespace task-app

# Rollback to specific revision
helm rollback task-manager 1 --namespace task-app
```

## Debugging

```bash
# Check release status
helm status task-manager --namespace task-app

# Get values
helm get values task-manager --namespace task-app

# Get all values (including defaults)
helm get values task-manager --namespace task-app --all

# Render templates locally (dry-run)
helm template task-manager ./helm/task-manager \
  --namespace task-app \
  --debug
```

## Testing

```bash
# Lint the chart
helm lint ./helm/task-manager

# Test installation (dry-run)
helm install task-manager ./helm/task-manager \
  --namespace task-app \
  --dry-run \
  --debug
```

## Dependencies

This chart includes all dependencies:
- PostgreSQL (database)
- Zookeeper (required for Kafka)
- Kafka (message queue)

To manage dependencies separately, you can disable them:

```bash
helm install task-manager ./helm/task-manager \
  --set postgresql.enabled=false \
  --set kafka.enabled=false \
  --set zookeeper.enabled=false
```

## Notes

- Default passwords are insecure and should be changed in production
- For production, use external database services when possible
- Consider using cert-manager for TLS certificates
- Use proper secrets management (e.g., Sealed Secrets, External Secrets)

