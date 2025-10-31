#!/bin/bash

# Script to deploy frontend to production server
# This ensures latest changes are pushed and built on the server

echo "🚀 Deploying frontend to production server..."

# Set cache busting variables
export CACHE_BUST=$(date +%s)
export BUILD_DATE=$(date +%Y%m%d_%H%M%S)
export BUILD_TIMESTAMP=$(date +%s)

echo "📅 Build Date: $BUILD_DATE"
echo "⏰ Cache Bust: $CACHE_BUST"

# Navigate to project root
cd "$(dirname "$0")"

# Push latest changes to git (if needed)
echo "📤 Pushing latest changes to git..."
git add .
git commit -m "Update frontend with latest changes - $BUILD_DATE" || echo "No changes to commit"
git push origin main || echo "Git push failed or no remote configured"

# Deploy to server using existing script
echo "🌐 Deploying to server..."
if [ -f "deploy-to-server.sh" ]; then
    chmod +x deploy-to-server.sh
    ./deploy-to-server.sh
else
    echo "❌ deploy-to-server.sh not found. Please run deployment manually."
fi

echo "✅ Frontend deployment initiated!"
echo "🔍 Check server logs for build progress"
