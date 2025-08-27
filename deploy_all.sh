#!/bin/bash

# Deploy All Services Script
echo "🚀 Deploying All Barrim Services..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    echo "Please copy env_template.txt to .env and configure your environment variables."
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running!"
    echo "Please start Docker and try again."
    exit 1
fi

# Set build timestamp to force rebuilds
export BUILD_DATE=$(date +%Y%m%d_%H%M%S)
export VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "local")

echo "📅 Build Date: $BUILD_DATE"
echo "🏷️  Version: $VERSION"

# Ask user what to rebuild
echo ""
echo "🔧 What would you like to rebuild?"
echo "1) Frontend only (fastest)"
echo "2) Backend only"
echo "3) Both frontend and backend"
echo "4) Everything (including databases)"
echo ""
read -p "Enter your choice (1-4): " choice

case $choice in
    1)
        echo "🔄 Rebuilding frontend only..."
        docker-compose stop admin-dashboard
        docker-compose rm -f admin-dashboard
        docker rmi barrim_admin-dashboard 2>/dev/null || true
        docker-compose build --no-cache admin-dashboard
        docker-compose up -d admin-dashboard
        ;;
    2)
        echo "🔄 Rebuilding backend only..."
        docker-compose stop backend
        docker-compose rm -f backend
        docker rmi barrim_backend 2>/dev/null || true
        docker-compose build --no-cache backend
        docker-compose up -d backend
        ;;
    3)
        echo "🔄 Rebuilding frontend and backend..."
        docker-compose stop admin-dashboard backend
        docker-compose rm -f admin-dashboard backend
        docker rmi barrim_admin-dashboard barrim_backend 2>/dev/null || true
        docker-compose build --no-cache admin-dashboard backend
        docker-compose up -d admin-dashboard backend
        ;;
    4)
        echo "🔄 Rebuilding everything..."
        docker-compose down
        docker-compose build --no-cache
        docker-compose up -d
        ;;
    *)
        echo "❌ Invalid choice. Exiting."
        exit 1
        ;;
esac

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 15

# Check status
echo "📊 Service deployment status:"
docker-compose ps

# Test services
echo "🧪 Testing services..."

# Test backend
if curl -s http://localhost:8080 > /dev/null 2>&1; then
    echo "✅ Backend is accessible at http://localhost:8080"
else
    echo "❌ Backend might not be ready yet"
fi

# Test frontend
if curl -s http://localhost:3000 > /dev/null 2>&1; then
    echo "✅ Frontend is accessible at http://localhost:3000"
else
    echo "❌ Frontend might not be ready yet"
fi

# Test Redis
if docker exec redis redis-cli -a "$(grep REDIS_PASSWORD .env | cut -d'=' -f2)" ping > /dev/null 2>&1; then
    echo "✅ Redis is running"
else
    echo "❌ Redis might not be ready yet"
fi

echo ""
echo "🎉 Deployment completed!"
echo ""
echo "📝 Useful commands:"
echo "   View all logs: docker-compose logs -f"
echo "   View specific service: docker-compose logs -f [service_name]"
echo "   Restart service: docker-compose restart [service_name]"
echo "   Stop all: docker-compose down"
echo "   Start all: docker-compose up -d"
