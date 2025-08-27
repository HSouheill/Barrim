#!/bin/bash

# Deploy Frontend Updates Script
echo "🚀 Deploying Frontend Updates..."

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

# Set build timestamp to force rebuild
export BUILD_DATE=$(date +%Y%m%d_%H%M%S)
export VERSION=$(git rev-parse --short HEAD 2>/dev/null || echo "local")

echo "📅 Build Date: $BUILD_DATE"
echo "🏷️  Version: $VERSION"

# Stop frontend container
echo "🛑 Stopping frontend container..."
docker-compose stop admin-dashboard

# Remove frontend container and image to force rebuild
echo "🗑️  Removing old frontend container and image..."
docker-compose rm -f admin-dashboard
docker rmi barrim_admin-dashboard 2>/dev/null || true

# Build frontend with no cache
echo "🔨 Building frontend (no cache)..."
docker-compose build --no-cache admin-dashboard

# Start frontend
echo "▶️  Starting frontend..."
docker-compose up -d admin-dashboard

# Wait for frontend to be ready
echo "⏳ Waiting for frontend to be ready..."
sleep 10

# Check status
echo "📊 Frontend deployment status:"
docker-compose ps admin-dashboard

# Test frontend
echo "🧪 Testing frontend..."
if curl -s http://localhost:3000 > /dev/null; then
    echo "✅ Frontend is accessible at http://localhost:3000"
else
    echo "❌ Frontend might not be ready yet. Check logs with:"
    echo "   docker-compose logs admin-dashboard"
fi

echo ""
echo "🎉 Frontend deployment completed!"
echo "🌐 Access your updated frontend at: http://localhost:3000"
echo ""
echo "📝 Useful commands:"
echo "   View logs: docker-compose logs -f admin-dashboard"
echo "   Restart: docker-compose restart admin-dashboard"
echo "   Status: docker-compose ps admin-dashboard"
