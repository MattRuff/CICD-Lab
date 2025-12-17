#!/bin/bash

echo "🧹 Cleanup Script"
echo "================="
echo ""

read -p "This will remove all containers, volumes, and Kubernetes resources. Continue? (y/N) " -n 1 -r
echo ""

if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Cancelled"
    exit 0
fi

echo ""
echo "🐳 Stopping and removing Docker containers..."
docker-compose down -v

echo ""
echo "☸️  Removing Kubernetes resources..."
if command -v kubectl &> /dev/null; then
    kubectl delete namespace task-app --ignore-not-found=true
    echo "✅ Kubernetes resources removed"
else
    echo "⚠️  kubectl not found, skipping Kubernetes cleanup"
fi

echo ""
echo "🗑️  Removing Docker images..."
docker rmi task-backend:latest task-consumer:latest task-frontend:latest 2>/dev/null || true

echo ""
echo "✨ Cleanup complete!"

