#!/bin/bash

echo "☸️  Deploying with Helm"
echo "======================="
echo ""

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "✅ Helm is available"
echo ""

# Check if kubectl is available
if ! command -v kubectl &> /dev/null; then
    echo "❌ kubectl is not installed. Please install kubectl first."
    exit 1
fi

echo "✅ kubectl is available"
echo ""

# Check cluster connection
if ! kubectl cluster-info > /dev/null 2>&1; then
    echo "❌ Cannot connect to Kubernetes cluster."
    echo "   Please ensure your cluster is running and kubectl is configured."
    exit 1
fi

echo "✅ Connected to Kubernetes cluster"
echo ""

# Build images
echo "🔨 Building Docker images..."
docker build -t task-backend:latest ./backend
docker build -t task-consumer:latest ./consumer
docker build -t task-frontend:latest ./frontend

echo ""
echo "✅ Images built successfully"
echo ""

# Check if using Minikube
if kubectl config current-context | grep -q "minikube"; then
    echo "📦 Detected Minikube - loading images..."
    minikube image load task-backend:latest
    minikube image load task-consumer:latest
    minikube image load task-frontend:latest
    echo "✅ Images loaded to Minikube"
    echo ""
fi

# Deploy with Helm
echo "🚀 Deploying with Helm..."
helm upgrade --install task-manager ./helm/task-manager \
    --namespace task-app \
    --create-namespace \
    --wait \
    --timeout 5m

echo ""
echo "✅ Deployment complete!"
echo ""

# Get service information
echo "📍 Service Information:"
helm list -n task-app
echo ""
kubectl get pods -n task-app
echo ""
kubectl get services -n task-app

echo ""
echo "🎉 Helm deployment complete!"
echo ""

# Check if Minikube
if kubectl config current-context | grep -q "minikube"; then
    echo "🌐 Access the application with:"
    echo "   minikube service task-manager-frontend -n task-app"
else
    echo "🌐 Get the frontend URL with:"
    echo "   kubectl get service task-manager-frontend -n task-app"
fi

echo ""
echo "📊 View Helm release: helm status task-manager -n task-app"
echo "📋 View pods: kubectl get pods -n task-app"
echo "🔄 Upgrade: helm upgrade task-manager ./helm/task-manager -n task-app"
echo "🗑️  Uninstall: helm uninstall task-manager -n task-app"
echo ""

