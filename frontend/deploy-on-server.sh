#!/bin/bash

# Script to pull and deploy admin dashboard on server
# Usage: ./deploy-on-server.sh [version] [dockerhub-username]
# Example: ./deploy-on-server.sh 1.0.1 myusername

set -e  # Exit on error

# Configuration
DOCKERHUB_USERNAME="${2:-hsouheil}"  # Replace with your Docker Hub username
IMAGE_NAME="barrim-admin-dashboard"
VERSION="${1:-latest}"
CONTAINER_NAME="barrim-admin-dashboard"
PORT="${3:-3000}"  # Port to expose on host

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}Deploying Admin Dashboard on Server${NC}"
echo -e "${BLUE}========================================${NC}"

# Full image name
FULL_IMAGE_NAME="${DOCKERHUB_USERNAME}/${IMAGE_NAME}:${VERSION}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}Error: Docker is not running. Please start Docker and try again.${NC}"
    exit 1
fi

# Check if logged in to Docker Hub (if pulling private images)
if ! docker info | grep -q "Username"; then
    echo -e "${YELLOW}Warning: Not logged in to Docker Hub. You may need to login for private images.${NC}"
    read -p "Do you want to login to Docker Hub? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker login
    fi
fi

# Stop and remove existing container if it exists
if [ "$(docker ps -aq -f name=${CONTAINER_NAME})" ]; then
    echo -e "${YELLOW}Stopping existing container...${NC}"
    docker stop "${CONTAINER_NAME}" || true
    docker rm "${CONTAINER_NAME}" || true
fi

# Pull the latest image
echo -e "${BLUE}Pulling image: ${FULL_IMAGE_NAME}...${NC}"
docker pull "${FULL_IMAGE_NAME}"

# Run the container
echo -e "${BLUE}Starting container...${NC}"
docker run -d \
    --name "${CONTAINER_NAME}" \
    --restart unless-stopped \
    -p "${PORT}:80" \
    "${FULL_IMAGE_NAME}"

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}Admin Dashboard deployed successfully!${NC}"
echo -e "${GREEN}Container: ${CONTAINER_NAME}${NC}"
echo -e "${GREEN}Access at: http://localhost:${PORT}${NC}"
echo -e "${GREEN}========================================${NC}"

# Show container status
echo -e "${BLUE}Container status:${NC}"
docker ps -f name="${CONTAINER_NAME}"

# Show logs
echo -e "${BLUE}Container logs (last 20 lines):${NC}"
docker logs --tail 20 "${CONTAINER_NAME}"

