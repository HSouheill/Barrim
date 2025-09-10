#!/bin/bash

# Script to rebuild frontend with cache busting
# This ensures latest changes are included in the Docker build

echo "🔄 Rebuilding frontend with latest changes..."

# Set cache busting variables
export CACHE_BUST=$(date +%s)
export BUILD_DATE=$(date +%Y%m%d_%H%M%S)
export BUILD_TIMESTAMP=$(date +%s)

echo "📅 Build Date: $BUILD_DATE"
echo "⏰ Cache Bust: $CACHE_BUST"

# Navigate to project root
cd "$(dirname "$0")"

# Stop existing frontend container
echo "🛑 Stopping existing frontend container..."
docker-compose stop barrim-admin-dashboard

# Remove existing frontend container and image
echo "🗑️  Removing existing frontend container and image..."
docker-compose rm -f barrim-admin-dashboard
docker rmi barrim-admin-dashboard 2>/dev/null || true

# Build frontend with no cache
echo "🔨 Building frontend with latest changes..."
docker-compose build --no-cache barrim-admin-dashboard

# Start the frontend service
echo "🚀 Starting frontend service..."
docker-compose up -d barrim-admin-dashboard

echo "✅ Frontend rebuild complete!"
echo "🌐 Frontend should be available at: http://localhost:3000"
echo "📊 Check status with: docker-compose ps"
