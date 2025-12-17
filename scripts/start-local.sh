#!/bin/bash

echo "🚀 Starting Task Manager Application"
echo "===================================="
echo ""

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Docker is not running. Please start Docker Desktop first."
    exit 1
fi

echo "✅ Docker is running"
echo ""

# Start services
echo "📦 Starting all services with Docker Compose..."
docker-compose up -d

echo ""
echo "⏳ Waiting for services to be ready..."
sleep 10

# Check service health
echo ""
echo "🔍 Checking service health..."

# Check backend
if curl -f http://localhost:3000/health > /dev/null 2>&1; then
    echo "✅ Backend is healthy"
else
    echo "⚠️  Backend is starting up..."
fi

# Check frontend
if curl -f http://localhost:3001 > /dev/null 2>&1; then
    echo "✅ Frontend is accessible"
else
    echo "⚠️  Frontend is starting up..."
fi

echo ""
echo "✨ Application is starting!"
echo ""
echo "📍 Access points:"
echo "   Frontend:  http://localhost:3001"
echo "   Backend:   http://localhost:3000"
echo "   API Docs:  http://localhost:3000/health"
echo ""
echo "📊 View logs with: docker-compose logs -f"
echo "🛑 Stop services with: docker-compose down"
echo ""

