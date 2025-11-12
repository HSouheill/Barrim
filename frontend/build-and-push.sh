#!/bin/bash

# Script to build and push admin dashboard Docker image to Docker Hub
# Usage: ./build-and-push.sh [version] [dockerhub-username]
# Example: ./build-and-push.sh 1.0.1 myusername

set -e  # Exit on error

# Configuration
DOCKERHUB_USERNAME="${2:-hsouheil}"  # Replace with your Docker Hub username
IMAGE_NAME="barrim-admin-dashboard"
VERSION="${1:-latest}"

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Building Admin Dashboard Docker Image${NC}"
echo -e "${BLUE}========================================${NC}"

# Navigate to frontend directory
cd "$(dirname "$0")"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${YELLOW}Error: Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if logged in to Docker Hub
if ! docker info | grep -q "Username"; then
    echo -e "${YELLOW}Warning: Not logged in to Docker Hub. Attempting to login...${NC}"
    docker login
fi

# Full image name
FULL_IMAGE_NAME="${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${VERSION}"
LATEST_IMAGE_NAME="${DOCKERHUB_USERNAME}/${IMAGE_NAME}:latest"

echo -e "${GREEN}Building image: ${FULL_IMAGE_NAME}${NC}"

# Build the Docker image
docker build \
    --tag "${FULL_IMAGE_NAME}" \
    --tag "${LATEST_IMAGE_NAME}" \
    --build-arg BUILD_DATE="$(date -u +'%Y-%m-%dT%H:%M:%SZ')" \
    --build-arg VERSION="${VERSION}" \
    --build-arg BUILD_TIMESTAMP="$(date +%s)" \
    --build-arg CACHE_BUST="$(date +%s)" \
    -f Dockerfile \
    .

echo -e "${GREEN}Build completed successfully!${NC}"

# Ask user if they want to push
read -p "Do you want to push the image to Docker Hub? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${BLUE}Pushing ${FULL_IMAGE_NAME}...${NC}"
    docker push "${FULL_IMAGE_NAME}"
    
    if [ "$VERSION" != "latest" ]; then
        echo -e "${BLUE}Pushing ${LATEST_IMAGE_NAME}...${NC}"
        docker push "${LATEST_IMAGE_NAME}"
    fi
    
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}Successfully pushed to Docker Hub!${NC}"
    echo -e "${GREEN}Image: ${FULL_IMAGE_NAME}${NC}"
    echo -e "${GREEN}Image: ${LATEST_IMAGE_NAME}${NC}"
    echo -e "${GREEN}========================================${NC}"
else
    echo -e "${YELLOW}Image built but not pushed. To push manually, run:${NC}"
    echo -e "  docker push ${FULL_IMAGE_NAME}"
    echo -e "  docker push ${LATEST_IMAGE_NAME}"
fi

