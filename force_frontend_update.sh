#!/bin/bash

# Force Frontend Update Script - Nuclear Option
echo "🚀 FORCING Frontend Update (Nuclear Option)..."

# Check if .env file exists
if [ ! -f .env ]; then
    echo "❌ Error: .env file not found!"
    exit 1
fi

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "❌ Error: Docker is not running!"
    exit 1
fi

# Set build timestamp to force rebuilds
export BUILD_DATE=$(date +%Y%m%d_%H%M%S)
export VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "local")
export BUILD_TIMESTAMP=$(date +%s)

echo "📅 Build Date: $BUILD_DATE"
echo "🏷️  Version: $VERSION"
echo "⏰ Timestamp: $BUILD_TIMESTAMP"

# Stop all services
echo "🛑 Stopping all services..."
docker-compose down

# Remove ALL frontend-related images and containers
echo "🗑️  Removing ALL frontend artifacts..."
docker rmi $(docker images | grep admin-dashboard | awk '{print $3}') 2>/dev/null || true
docker rmi $(docker images | grep barrim_admin-dashboard | awk '{print $3}') 2>/dev/null || true
docker rmi $(docker images | grep frontend | awk '{print $3}') 2>/dev/null || true

# Remove all stopped containers
echo "🧹 Cleaning up stopped containers..."
docker container prune -f

# Remove all unused images
echo "🧹 Cleaning up unused images..."
docker image prune -f

# Remove all unused volumes (be careful with this in production)
echo "🧹 Cleaning up unused volumes..."
docker volume prune -f

# Clear Docker build cache
echo "🧹 Clearing Docker build cache..."
docker builder prune -f

# Rebuild frontend with no cache
echo "🔨 Rebuilding frontend from scratch..."
docker-compose build --no-cache admin-dashboard

# Start all services
echo "▶️  Starting all services..."
docker-compose up -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 20

# Check status
echo "📊 Service status:"
docker-compose ps

# Test frontend
echo "🧪 Testing frontend..."
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Frontend is accessible at http://localhost:3000"
    
    # Check build info
    echo "📋 Build information:"
    curl -s http://localhost:3000/build_info.txt || echo "Build info not accessible"
else
    echo "❌ Frontend might not be ready yet. Check logs:"
    echo "   docker-compose logs admin-dashboard"
fi

echo ""
echo "🎉 Force frontend update completed!"
echo "🌐 Access your updated frontend at: http://localhost:3000"
echo ""
echo "📝 If issues persist, check:"
echo "   - Frontend logs: docker-compose logs -f admin-dashboard"
echo "   - All logs: docker-compose logs -f"
echo "   - Docker system: docker system df"
