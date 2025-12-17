# Lab Setup Guide - Minikube + GitHub Actions CI/CD

This guide sets up a production-grade CI/CD pipeline using GitHub Actions with Minikube for local deployment.

## Architecture

```
┌─────────────┐     ┌──────────────────┐     ┌─────────────────┐     ┌──────────────┐
│  Developer  │────▶│  GitHub Actions  │────▶│  ghcr.io        │────▶│  Minikube    │
│  (Git Push) │     │  (Test & Build)  │     │  (Registry)     │     │  (Deploy)    │
└─────────────┘     └──────────────────┘     └─────────────────┘     └──────────────┘
                            │
                            │ Runs Tests
                            │ Builds Images
                            │ Pushes to Registry
                            │ Tagged with git SHA
```

## Prerequisites

1. **Minikube installed and running**
   ```bash
   minikube start --cpus=4 --memory=8192
   ```

2. **GitHub Account** with this repository

3. **GitHub Token** for pulling images (if private repo)

## Step 1: Configure GitHub Container Registry

### 1.1 Make GitHub Packages Public (Easiest for Lab)

After GitHub Actions builds your images:

1. Go to your GitHub repository
2. Click on "Packages" (right sidebar)
3. Click on each package (task-backend, task-frontend, task-consumer)
4. Click "Package settings"
5. Scroll to "Danger Zone"
6. Change visibility to **Public**

**This makes your images publicly accessible - perfect for a lab!**

### 1.2 Or Use a GitHub Token (For Private Images)

If you keep images private, you'll need a pull secret:

```bash
# Create a GitHub Personal Access Token (PAT)
# Go to: Settings → Developer settings → Personal access tokens → Tokens (classic)
# Select scopes: read:packages

# Create pull secret in Minikube
kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=YOUR_GITHUB_USERNAME \
  --docker-password=YOUR_GITHUB_TOKEN \
  --docker-email=YOUR_EMAIL \
  -n task-app
```

## Step 2: Update Helm Values for Production Registry

Create `helm/task-manager/values-lab.yaml`:

```yaml
# Lab environment values - uses images from GitHub Container Registry
namespace:
  name: task-app
  create: true

# Update image repositories to use ghcr.io
backend:
  replicaCount: 2
  image:
    repository: ghcr.io/YOUR_GITHUB_USERNAME/task-backend
    tag: latest
    pullPolicy: Always  # Always pull latest from registry
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"

consumer:
  replicaCount: 1
  image:
    repository: ghcr.io/YOUR_GITHUB_USERNAME/task-consumer
    tag: latest
    pullPolicy: Always
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

frontend:
  replicaCount: 2
  image:
    repository: ghcr.io/YOUR_GITHUB_USERNAME/task-frontend
    tag: latest
    pullPolicy: Always
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "200m"

# Use smaller resources for Minikube
postgresql:
  persistence:
    size: 1Gi
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"

kafka:
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"

zookeeper:
  resources:
    requests:
      memory: "128Mi"
      cpu: "100m"
    limits:
      memory: "256Mi"
      cpu: "250m"

# If using private images, uncomment:
# imagePullSecrets:
#   - name: ghcr-secret
```

## Step 3: Update GitHub Actions Workflow

Your `.github/workflows/ci-cd.yml` is already configured! Just need to verify the image names match your GitHub username.

The workflow will:
- ✅ Run tests on every push
- ✅ Build Docker images
- ✅ Push to `ghcr.io/YOUR_USERNAME/task-*:latest`
- ✅ Tag with git SHA for versioning

## Step 4: Complete Workflow

### Initial Setup

1. **Start Minikube**
   ```bash
   minikube start --cpus=4 --memory=8192
   minikube addons enable ingress
   ```

2. **Initialize Git Repository**
   ```bash
   git init
   git add .
   git commit -m "Initial commit: Task Manager with CI/CD"
   ```

3. **Create GitHub Repository**
   ```bash
   # On GitHub, create a new repository
   # Then push your code:
   git remote add origin https://github.com/YOUR_USERNAME/CICD-Lab.git
   git branch -M main
   git push -u origin main
   ```

4. **GitHub Actions Runs Automatically**
   - Go to your repo → Actions tab
   - Watch the CI/CD pipeline run
   - Images will be built and pushed to ghcr.io

5. **Make Images Public** (if needed)
   - Go to Packages in your GitHub repo
   - Change each package to Public visibility

### Deployment to Minikube

#### Option A: Using Helm (Recommended)

```bash
# Update values-lab.yaml with your GitHub username
# Then deploy:
helm install task-manager ./helm/task-manager \
  -f helm/task-manager/values-lab.yaml \
  --namespace task-app \
  --create-namespace \
  --wait

# Check deployment
kubectl get pods -n task-app
helm status task-manager -n task-app
```

#### Option B: Quick Command with Overrides

```bash
helm install task-manager ./helm/task-manager \
  --namespace task-app \
  --create-namespace \
  --set backend.image.repository=ghcr.io/YOUR_USERNAME/task-backend \
  --set backend.image.pullPolicy=Always \
  --set consumer.image.repository=ghcr.io/YOUR_USERNAME/task-consumer \
  --set consumer.image.pullPolicy=Always \
  --set frontend.image.repository=ghcr.io/YOUR_USERNAME/task-frontend \
  --set frontend.image.pullPolicy=Always \
  --wait
```

### Access Your Application

```bash
# Get the frontend URL
minikube service task-manager-frontend -n task-app

# Or use port forwarding
kubectl port-forward service/task-manager-frontend 8080:80 -n task-app
# Then visit: http://localhost:8080
```

## Step 5: Complete CI/CD Workflow

### Make a Code Change

```bash
# 1. Make changes to your code
echo "// Updated code" >> backend/src/index.ts

# 2. Commit and push
git add .
git commit -m "feat: Add new feature"
git push origin main
```

### GitHub Actions Automatically:
1. ✅ Runs all tests (backend, consumer, frontend)
2. ✅ Builds Docker images with `latest` and `main-SHA` tags
3. ✅ Pushes to ghcr.io
4. ✅ Reports success/failure

### Update Your Minikube Deployment

```bash
# Pull latest images and upgrade
helm upgrade task-manager ./helm/task-manager \
  -f helm/task-manager/values-lab.yaml \
  --namespace task-app

# Or force recreation of pods to pull new images
kubectl rollout restart deployment/task-manager-backend -n task-app
kubectl rollout restart deployment/task-manager-consumer -n task-app
kubectl rollout restart deployment/task-manager-frontend -n task-app
```

## Verification Steps

### 1. Verify CI/CD Pipeline

```bash
# Check GitHub Actions status
# Go to: https://github.com/YOUR_USERNAME/CICD-Lab/actions

# Should see:
# ✅ Test Backend
# ✅ Test Consumer  
# ✅ Test Frontend
# ✅ Build Images
# ✅ Push to ghcr.io
```

### 2. Verify Images in Registry

```bash
# Check your packages
# Go to: https://github.com/YOUR_USERNAME?tab=packages

# Should see:
# - task-backend:latest, main-<SHA>
# - task-consumer:latest, main-<SHA>
# - task-frontend:latest, main-<SHA>
```

### 3. Verify Minikube Deployment

```bash
# Check pods are running
kubectl get pods -n task-app

# Check images being used
kubectl get pods -n task-app -o jsonpath='{.items[*].spec.containers[*].image}' | tr ' ' '\n'

# Should show ghcr.io/YOUR_USERNAME/...
```

### 4. Verify Application

```bash
# Access frontend
minikube service task-manager-frontend -n task-app

# Test API
kubectl port-forward service/task-manager-backend 3000:3000 -n task-app
curl http://localhost:3000/health
```

## Production-Level Features Demonstrated

✅ **Automated Testing** - All tests run on every commit
✅ **Container Registry** - Images pushed to ghcr.io
✅ **Semantic Versioning** - Images tagged with git SHA
✅ **Multi-stage Builds** - Optimized Docker images
✅ **Health Checks** - Liveness and readiness probes
✅ **Resource Limits** - CPU and memory constraints
✅ **Rolling Updates** - Zero-downtime deployments
✅ **Rollback Capability** - Helm rollback support
✅ **Configuration Management** - Environment-specific configs
✅ **Infrastructure as Code** - All config in Git

## Troubleshooting

### Images Not Pulling

```bash
# Check image pull errors
kubectl describe pod <pod-name> -n task-app

# Common issues:
# 1. Images are private - make them public or add pull secret
# 2. Wrong repository name - verify YOUR_USERNAME
# 3. Images don't exist yet - wait for GitHub Actions to complete
```

### GitHub Actions Failed

```bash
# Check the Actions tab in GitHub
# Common issues:
# 1. Tests failing - fix the tests
# 2. Docker build failing - check Dockerfiles
# 3. Push permission denied - check repository permissions
```

### Minikube Issues

```bash
# Restart Minikube
minikube stop
minikube delete
minikube start --cpus=4 --memory=8192

# Check resources
kubectl top nodes
kubectl top pods -n task-app
```

## Advanced: Using Specific Tags

Instead of always using `:latest`, you can pin to specific versions:

```bash
# Get the git SHA from GitHub Actions
# Deploy specific version:
helm upgrade task-manager ./helm/task-manager \
  --set backend.image.tag=main-abc1234 \
  --set consumer.image.tag=main-abc1234 \
  --set frontend.image.tag=main-abc1234 \
  --reuse-values \
  -n task-app
```

## Summary

You now have:
- ✅ Production-grade CI/CD pipeline with GitHub Actions
- ✅ Automated testing on every commit
- ✅ Container images in GitHub Container Registry
- ✅ Minikube deployment using Helm
- ✅ Complete GitOps workflow

Perfect for demonstrating enterprise-level practices in a lab environment! 🚀

