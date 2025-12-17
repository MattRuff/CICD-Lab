# Helm Deployment Guide

## What is Helm?

Helm is a package manager for Kubernetes. Think of it like npm for Node.js or pip for Python, but for Kubernetes applications.

### Benefits of Using Helm:

- **Simplified Deployment**: Deploy entire application with one command
- **Configuration Management**: Easy environment-specific configurations
- **Version Control**: Track and rollback releases
- **Reusability**: Share and reuse charts
- **Templating**: Dynamic Kubernetes manifests

## 🚀 Quick Start

### 1. Install Helm

**macOS:**
```bash
brew install helm
```

**Linux:**
```bash
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
```

**Windows:**
```powershell
choco install kubernetes-helm
```

### 2. Deploy with One Command

```bash
./scripts/deploy-helm.sh
```

That's it! Your entire application is deployed.

## 📋 Manual Deployment

### Basic Installation

```bash
# Build Docker images
docker build -t task-backend:latest ./backend
docker build -t task-consumer:latest ./consumer
docker build -t task-frontend:latest ./frontend

# Deploy with Helm
helm install task-manager ./helm/task-manager \
  --namespace task-app \
  --create-namespace
```

### Check Deployment Status

```bash
# View Helm releases
helm list -n task-app

# Check status
helm status task-manager -n task-app

# View pods
kubectl get pods -n task-app

# View services
kubectl get services -n task-app
```

## 🎯 Environment-Specific Deployments

### Development Environment

```bash
helm install task-manager ./helm/task-manager \
  -f helm/task-manager/values-dev.yaml \
  --namespace task-app-dev \
  --create-namespace
```

**Development Configuration:**
- 1 replica per service
- Smaller resource limits
- 500Mi storage
- Optimized for local testing

### Production Environment

```bash
helm install task-manager ./helm/task-manager \
  -f helm/task-manager/values-prod.yaml \
  --namespace task-app-prod \
  --create-namespace
```

**Production Configuration:**
- Multiple replicas (3 backend, 3 frontend)
- Autoscaling enabled
- Larger resource limits
- 10Gi storage
- Production-grade settings

## 🔧 Customization

### Override Specific Values

```bash
# Scale backend to 5 replicas
helm install task-manager ./helm/task-manager \
  --set backend.replicaCount=5 \
  --namespace task-app

# Change database password
helm install task-manager ./helm/task-manager \
  --set postgresql.config.password=mysecretpassword \
  --namespace task-app

# Multiple overrides
helm install task-manager ./helm/task-manager \
  --set backend.replicaCount=3 \
  --set frontend.replicaCount=3 \
  --set postgresql.persistence.size=5Gi \
  --namespace task-app
```

### Custom Values File

Create your own `values-custom.yaml`:

```yaml
backend:
  replicaCount: 4
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"

postgresql:
  config:
    password: "my-secure-password"
  persistence:
    size: 5Gi
```

Deploy with custom values:

```bash
helm install task-manager ./helm/task-manager \
  -f helm/task-manager/values-custom.yaml \
  --namespace task-app \
  --create-namespace
```

## 🔄 Upgrades and Updates

### Upgrade Application

```bash
# After code changes, rebuild images
docker build -t task-backend:latest ./backend

# Upgrade Helm release
helm upgrade task-manager ./helm/task-manager \
  --namespace task-app
```

### Upgrade with New Values

```bash
helm upgrade task-manager ./helm/task-manager \
  -f helm/task-manager/values-prod.yaml \
  --namespace task-app
```

### Upgrade and Wait

```bash
helm upgrade task-manager ./helm/task-manager \
  --namespace task-app \
  --wait \
  --timeout 5m
```

### Reuse Existing Values

```bash
# Change only backend replicas, keep everything else
helm upgrade task-manager ./helm/task-manager \
  --set backend.replicaCount=10 \
  --reuse-values \
  --namespace task-app
```

## ⏮️ Rollback

### View Release History

```bash
helm history task-manager -n task-app
```

Example output:
```
REVISION  UPDATED                   STATUS      CHART               DESCRIPTION
1         Mon Jan 1 10:00:00 2024   superseded  task-manager-1.0.0  Install complete
2         Mon Jan 1 11:00:00 2024   superseded  task-manager-1.0.0  Upgrade complete
3         Mon Jan 1 12:00:00 2024   deployed    task-manager-1.0.0  Upgrade complete
```

### Rollback to Previous Version

```bash
helm rollback task-manager -n task-app
```

### Rollback to Specific Revision

```bash
helm rollback task-manager 1 -n task-app
```

## 🗑️ Uninstall

```bash
# Uninstall release
helm uninstall task-manager -n task-app

# Also delete namespace
kubectl delete namespace task-app
```

## 🎛️ Common Helm Commands

### Installation

```bash
# Install
helm install [RELEASE_NAME] [CHART] [flags]

# Install with dry-run (test without applying)
helm install task-manager ./helm/task-manager --dry-run --debug

# Install and wait for completion
helm install task-manager ./helm/task-manager --wait
```

### Viewing Information

```bash
# List releases
helm list -n task-app

# Get release status
helm status task-manager -n task-app

# Get values used
helm get values task-manager -n task-app

# Get all values (including defaults)
helm get values task-manager -n task-app --all

# Get manifest
helm get manifest task-manager -n task-app
```

### Upgrading

```bash
# Upgrade release
helm upgrade task-manager ./helm/task-manager -n task-app

# Upgrade or install if not exists
helm upgrade --install task-manager ./helm/task-manager -n task-app
```

### Testing

```bash
# Lint chart
helm lint ./helm/task-manager

# Template (render locally)
helm template task-manager ./helm/task-manager

# Dry-run
helm install task-manager ./helm/task-manager --dry-run --debug
```

## 📊 Configuration Reference

### Complete values.yaml Overview

```yaml
# Namespace
namespace:
  name: task-app
  create: true

# PostgreSQL
postgresql:
  enabled: true
  image:
    repository: postgres
    tag: "16-alpine"
  config:
    database: taskdb
    username: postgres
    password: postgres  # Change in production!
  persistence:
    enabled: true
    size: 1Gi
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"

# Kafka & Zookeeper
kafka:
  enabled: true
  config:
    brokerId: 1
    replicationFactor: 1

zookeeper:
  enabled: true

# Backend
backend:
  enabled: true
  replicaCount: 2
  image:
    repository: task-backend
    tag: latest
  service:
    type: ClusterIP
    port: 3000
  autoscaling:
    enabled: false
    minReplicas: 2
    maxReplicas: 10

# Consumer
consumer:
  enabled: true
  replicaCount: 1
  image:
    repository: task-consumer
    tag: latest

# Frontend
frontend:
  enabled: true
  replicaCount: 2
  image:
    repository: task-frontend
    tag: latest
  service:
    type: LoadBalancer
    port: 80
  autoscaling:
    enabled: false
    minReplicas: 2
    maxReplicas: 10
```

## 🔐 Security Best Practices

### 1. External Secrets

Don't store secrets in values files. Use Kubernetes Secrets or external secret managers:

```bash
# Create secret manually
kubectl create secret generic db-password \
  --from-literal=password=mySecurePassword \
  -n task-app

# Reference in values
postgresql:
  existingSecret: db-password
```

### 2. Use Sealed Secrets

```bash
# Install Sealed Secrets controller
helm install sealed-secrets sealed-secrets/sealed-secrets

# Create sealed secret
kubeseal --format yaml < secret.yaml > sealed-secret.yaml
```

### 3. External Secret Operator

```yaml
# Use External Secrets Operator to pull from AWS Secrets Manager, etc.
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: db-credentials
spec:
  secretStoreRef:
    name: aws-secret-store
  target:
    name: postgresql-secret
  data:
    - secretKey: password
      remoteRef:
        key: prod/db/password
```

## 🎓 Advanced Usage

### Enable Autoscaling

```bash
helm upgrade task-manager ./helm/task-manager \
  --set backend.autoscaling.enabled=true \
  --set backend.autoscaling.minReplicas=3 \
  --set backend.autoscaling.maxReplicas=20 \
  --set backend.autoscaling.targetCPUUtilizationPercentage=70 \
  --namespace task-app \
  --reuse-values
```

### Disable Components

```bash
# Deploy without Kafka (use external Kafka)
helm install task-manager ./helm/task-manager \
  --set kafka.enabled=false \
  --set zookeeper.enabled=false \
  --namespace task-app
```

### Use External Database

```bash
helm install task-manager ./helm/task-manager \
  --set postgresql.enabled=false \
  --set backend.config.dbHost=my-external-db.example.com \
  --namespace task-app
```

## 🐛 Troubleshooting

### Chart Not Installing

```bash
# Check chart syntax
helm lint ./helm/task-manager

# Dry-run with debug
helm install task-manager ./helm/task-manager \
  --dry-run --debug \
  --namespace task-app
```

### Pods Not Starting

```bash
# Check Helm status
helm status task-manager -n task-app

# Check pod logs
kubectl logs -l app=backend -n task-app

# Describe pod
kubectl describe pod <pod-name> -n task-app
```

### Values Not Applied

```bash
# Check actual values used
helm get values task-manager -n task-app --all

# Re-upgrade without reuse-values
helm upgrade task-manager ./helm/task-manager \
  -f helm/task-manager/values.yaml \
  --namespace task-app
```

### Rollback Failed Upgrade

```bash
# View history
helm history task-manager -n task-app

# Rollback
helm rollback task-manager -n task-app
```

## 📚 Further Reading

- [Helm Documentation](https://helm.sh/docs/)
- [Helm Best Practices](https://helm.sh/docs/chart_best_practices/)
- [Chart Development Guide](https://helm.sh/docs/topics/charts/)
- [Values Files](https://helm.sh/docs/chart_template_guide/values_files/)

## 🆚 Helm vs kubectl apply

### kubectl apply (Raw Manifests)

```bash
kubectl apply -k k8s/
```

**Pros:**
- Simple and straightforward
- No additional tools needed
- Direct control

**Cons:**
- Hard to manage multiple environments
- No release versioning
- Manual rollbacks
- Complex configuration management

### Helm

```bash
helm install task-manager ./helm/task-manager
```

**Pros:**
- Easy configuration management
- Environment-specific deployments
- Release versioning and rollbacks
- Templating for dynamic values
- Package and share charts
- Track deployment history

**Cons:**
- Additional tool to learn
- Slightly more complex setup

**Recommendation**: Use Helm for production deployments, kubectl for quick testing.

## ✨ Summary

Helm makes it incredibly easy to:
1. Deploy entire applications with one command
2. Manage different environments (dev, staging, prod)
3. Track and rollback changes
4. Share deployment configurations
5. Scale and configure services dynamically

**Quick Commands:**

```bash
# Deploy
./scripts/deploy-helm.sh

# Or manually
helm install task-manager ./helm/task-manager -n task-app --create-namespace

# Upgrade
helm upgrade task-manager ./helm/task-manager -n task-app

# Rollback
helm rollback task-manager -n task-app

# Uninstall
helm uninstall task-manager -n task-app
```

