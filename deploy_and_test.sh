#!/bin/bash

echo "🚀 Deploying Barrim with fixes..."
echo "=================================="

# Stop existing containers
echo "📦 Stopping existing containers..."
docker-compose down

# Remove old images to ensure clean build
echo "🧹 Removing old images..."
docker-compose rm -f
docker system prune -f

# Build and start services
echo "🔨 Building and starting services..."
docker-compose up --build -d

# Wait for services to be ready
echo "⏳ Waiting for services to be ready..."
sleep 30

# Check container status
echo "📊 Container status:"
docker ps

# Check logs for any errors
echo "📋 Checking logs for errors..."
echo "Backend logs:"
docker logs barrim-backend --tail 20

echo "Admin dashboard logs:"
docker logs admin-dashboard --tail 10

echo "Nginx proxy logs:"
docker logs nginx-proxy --tail 10

# Test endpoints
echo "🧪 Testing endpoints..."
echo "Testing backend health endpoint..."
curl -s http://localhost:8080/health || echo "Backend not accessible"

echo "Testing admin dashboard..."
curl -s http://localhost:3000 | head -5 || echo "Admin dashboard not accessible"

echo "Testing nginx proxy..."
curl -s http://localhost | head -5 || echo "Nginx proxy not accessible"

echo "✅ Deployment complete! Check the logs above for any issues."
echo ""
echo "🌐 Access URLs:"
echo "   Backend API: http://localhost:8080"
echo "   Admin Dashboard: http://localhost:3000"
echo "   Nginx Proxy: http://localhost"
echo "   MongoDB: localhost:27017"
echo ""
echo "📝 To view logs in real-time:"
echo "   docker logs -f barrim-backend"
echo "   docker logs -f admin-dashboard"
echo "   docker logs -f nginx-proxy"
