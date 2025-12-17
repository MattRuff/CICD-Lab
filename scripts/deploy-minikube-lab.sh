#!/bin/bash

echo "🎓 Deploying to Minikube for Lab Environment"
echo "============================================="
echo ""

# Check if minikube is running
if ! minikube status > /dev/null 2>&1; then
    echo "❌ Minikube is not running."
    echo "   Starting Minikube..."
    minikube start --cpus=4 --memory=8192
fi

echo "✅ Minikube is running"
echo ""

# Check if helm is available
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Installing Helm..."
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

echo "✅ Helm is available"
echo ""

# Get GitHub username
echo "📝 Configuration"
echo "==============="
echo ""
read -p "Enter your GitHub username: " GITHUB_USERNAME

if [ -z "$GITHUB_USERNAME" ]; then
    echo "❌ GitHub username is required"
    exit 1
fi

echo ""
echo "Images will be pulled from:"
echo "  - ghcr.io/$GITHUB_USERNAME/task-backend:latest"
echo "  - ghcr.io/$GITHUB_USERNAME/task-consumer:latest"
echo "  - ghcr.io/$GITHUB_USERNAME/task-frontend:latest"
echo ""

# Ask if images are public
read -p "Are your GitHub Container Registry images public? (y/n) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo ""
    echo "📝 You need to create a pull secret for private images."
    echo ""
    read -p "Enter your GitHub Personal Access Token (with read:packages scope): " GITHUB_TOKEN
    
    if [ -z "$GITHUB_TOKEN" ]; then
        echo "❌ GitHub token is required for private images"
        exit 1
    fi
    
    read -p "Enter your email: " EMAIL
    
    # Create namespace first
    kubectl create namespace task-app --dry-run=client -o yaml | kubectl apply -f -
    
    # Create pull secret
    kubectl create secret docker-registry ghcr-secret \
        --docker-server=ghcr.io \
        --docker-username="$GITHUB_USERNAME" \
        --docker-password="$GITHUB_TOKEN" \
        --docker-email="$EMAIL" \
        -n task-app \
        --dry-run=client -o yaml | kubectl apply -f -
    
    echo "✅ Pull secret created"
    PULL_SECRET_FLAG="--set imagePullSecrets[0].name=ghcr-secret"
else
    PULL_SECRET_FLAG=""
fi

echo ""
echo "🚀 Deploying with Helm..."
echo ""

# Deploy with Helm
helm upgrade --install task-manager ./helm/task-manager \
    --namespace task-app \
    --create-namespace \
    --set backend.image.repository="ghcr.io/$GITHUB_USERNAME/task-backend" \
    --set backend.image.pullPolicy=Always \
    --set consumer.image.repository="ghcr.io/$GITHUB_USERNAME/task-consumer" \
    --set consumer.image.pullPolicy=Always \
    --set frontend.image.repository="ghcr.io/$GITHUB_USERNAME/task-frontend" \
    --set frontend.image.pullPolicy=Always \
    $PULL_SECRET_FLAG \
    --wait \
    --timeout 5m

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Deployment successful!"
    echo ""
    
    # Show status
    echo "📊 Deployment Status:"
    echo "===================="
    kubectl get pods -n task-app
    echo ""
    
    echo "📍 Services:"
    echo "==========="
    kubectl get services -n task-app
    echo ""
    
    echo "🌐 Access Your Application:"
    echo "==========================="
    echo ""
    echo "Run this command to access the frontend:"
    echo "  minikube service task-manager-frontend -n task-app"
    echo ""
    echo "Or use port forwarding:"
    echo "  kubectl port-forward service/task-manager-frontend 8080:80 -n task-app"
    echo "  Then visit: http://localhost:8080"
    echo ""
    echo "Backend API:"
    echo "  kubectl port-forward service/task-manager-backend 3000:3000 -n task-app"
    echo "  Then visit: http://localhost:3000/health"
    echo ""
    
    echo "📚 Useful Commands:"
    echo "==================="
    echo "  View logs:     kubectl logs -f deployment/task-manager-backend -n task-app"
    echo "  Check status:  helm status task-manager -n task-app"
    echo "  Upgrade:       helm upgrade task-manager ./helm/task-manager -f helm/task-manager/values-lab.yaml -n task-app"
    echo "  Uninstall:     helm uninstall task-manager -n task-app"
    echo ""
    
    echo "🔄 To Update After Code Changes:"
    echo "================================"
    echo "1. Push to GitHub (triggers CI/CD)"
    echo "2. Wait for GitHub Actions to complete"
    echo "3. Run: kubectl rollout restart deployment/task-manager-backend -n task-app"
    echo "   (Repeat for consumer and frontend)"
    echo ""
else
    echo ""
    echo "❌ Deployment failed!"
    echo ""
    echo "Troubleshooting:"
    echo "==============="
    echo "1. Check if images exist in GitHub Container Registry"
    echo "2. Make sure images are public OR pull secret is configured"
    echo "3. Check pod status: kubectl get pods -n task-app"
    echo "4. Check pod logs: kubectl describe pod <pod-name> -n task-app"
    echo ""
    exit 1
fi

