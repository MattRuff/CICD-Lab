#!/bin/bash

echo "☸️  Deploying to Kubernetes"
echo "============================"
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

# Deploy to Kubernetes
echo "🚀 Deploying to Kubernetes..."
kubectl apply -k k8s/

echo ""
echo "⏳ Waiting for deployments to be ready..."
echo ""

# Wait for deployments
kubectl wait --for=condition=available --timeout=300s \
    deployment/postgres \
    deployment/kafka \
    deployment/zookeeper \
    -n task-app

kubectl wait --for=condition=available --timeout=300s \
    deployment/backend \
    deployment/consumer \
    deployment/frontend \
    -n task-app

echo ""
echo "✅ All deployments are ready!"
echo ""

# Get service information
echo "📍 Service Information:"
kubectl get services -n task-app

echo ""
echo "🎉 Deployment complete!"
echo ""

# Check if Minikube
if kubectl config current-context | grep -q "minikube"; then
    echo "🌐 Access the application with:"
    echo "   minikube service frontend -n task-app"
else
    echo "🌐 Get the frontend URL with:"
    echo "   kubectl get service frontend -n task-app"
fi

echo ""
echo "📊 View pods: kubectl get pods -n task-app"
echo "📋 View logs: kubectl logs -f deployment/backend -n task-app"
echo ""

