#!/bin/bash

# Deployment script for Barrim services
# This script handles the complete deployment process

set -e  # Exit on any error

# Configuration
DOCKER_USERNAME="hsouheil"
BACKEND_IMAGE="barrim-backend"
FRONTEND_IMAGE="barrim-frontend"
PRIVACY_IMAGE="barrim-privacy"
VERSION=${1:-latest}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if Docker is running
check_docker() {
    if ! docker info > /dev/null 2>&1; then
        print_error "Docker is not running. Please start Docker and try again."
        exit 1
    fi
}

# Function to check if logged into Docker Hub
check_docker_login() {
    if ! docker info | grep -q "Username"; then
        print_warning "Not logged into Docker Hub. Please run 'docker login' first."
        read -p "Do you want to login now? (y/n): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            docker login
        else
            print_error "Cannot proceed without Docker Hub login."
            exit 1
        fi
    fi
}

# Function to build and push images
build_and_push() {
    print_status "Starting build and push process..."
    print_status "Version: $VERSION"
    print_status "Timestamp: $(date)"
    
    # Build backend
    print_status "Building backend image..."
    if docker build -f Dockerfile.backend -t $DOCKER_USERNAME/$BACKEND_IMAGE:$VERSION .; then
        docker tag $DOCKER_USERNAME/$BACKEND_IMAGE:$VERSION $DOCKER_USERNAME/$BACKEND_IMAGE:latest
        print_success "Backend image built successfully"
    else
        print_error "Backend image build failed"
        exit 1
    fi
    
    # Build frontend
    print_status "Building frontend image..."
    if docker build -f frontend/Dockerfile -t $DOCKER_USERNAME/$FRONTEND_IMAGE:$VERSION ./frontend; then
        docker tag $DOCKER_USERNAME/$FRONTEND_IMAGE:$VERSION $DOCKER_USERNAME/$FRONTEND_IMAGE:latest
        print_success "Frontend image built successfully"
    else
        print_error "Frontend image build failed"
        exit 1
    fi
    
    # Build privacy service
    print_status "Building privacy service image..."
    if docker build -f privacy/Dockerfile -t $DOCKER_USERNAME/$PRIVACY_IMAGE:$VERSION ./privacy; then
        docker tag $DOCKER_USERNAME/$PRIVACY_IMAGE:$VERSION $DOCKER_USERNAME/$PRIVACY_IMAGE:latest
        print_success "Privacy service image built successfully"
    else
        print_error "Privacy service image build failed"
        exit 1
    fi
    
    # Push images
    print_status "Pushing images to Docker Hub..."
    
    print_status "Pushing backend image..."
    if docker push $DOCKER_USERNAME/$BACKEND_IMAGE:$VERSION && docker push $DOCKER_USERNAME/$BACKEND_IMAGE:latest; then
        print_success "Backend image pushed successfully"
    else
        print_error "Backend image push failed"
        exit 1
    fi
    
    print_status "Pushing frontend image..."
    if docker push $DOCKER_USERNAME/$FRONTEND_IMAGE:$VERSION && docker push $DOCKER_USERNAME/$FRONTEND_IMAGE:latest; then
        print_success "Frontend image pushed successfully"
    else
        print_error "Frontend image push failed"
        exit 1
    fi
    
    print_status "Pushing privacy service image..."
    if docker push $DOCKER_USERNAME/$PRIVACY_IMAGE:$VERSION && docker push $DOCKER_USERNAME/$PRIVACY_IMAGE:latest; then
        print_success "Privacy service image pushed successfully"
    else
        print_error "Privacy service image push failed"
        exit 1
    fi
}

# Function to generate deployment commands
generate_deployment_commands() {
    print_success "Build and push completed successfully!"
    echo
    print_status "Your images are now available at:"
    echo "  - $DOCKER_USERNAME/$BACKEND_IMAGE:$VERSION"
    echo "  - $DOCKER_USERNAME/$FRONTEND_IMAGE:$VERSION"
    echo "  - $DOCKER_USERNAME/$PRIVACY_IMAGE:$VERSION"
    echo
    print_status "To deploy on your server, run these commands:"
    echo
    echo "# 1. Pull the latest images"
    echo "docker pull $DOCKER_USERNAME/$BACKEND_IMAGE:$VERSION"
    echo "docker pull $DOCKER_USERNAME/$FRONTEND_IMAGE:$VERSION"
    echo "docker pull $DOCKER_USERNAME/$PRIVACY_IMAGE:$VERSION"
    echo
    echo "# 2. Copy necessary files to server"
    echo "scp docker-compose.prod.yml user@your-server:/path/to/app/"
    echo "scp .env user@your-server:/path/to/app/"
    echo "scp -r nginx/ user@your-server:/path/to/app/"
    echo "scp -r mongo-init/ user@your-server:/path/to/app/"
    echo
    echo "# 3. Deploy on server"
    echo "cd /path/to/app"
    echo "docker-compose -f docker-compose.prod.yml up -d"
    echo
    print_status "Or use the automated deployment script:"
    echo "./deploy-remote.sh user@your-server /path/to/app"
}

# Main execution
main() {
    print_status "Barrim Deployment Script"
    print_status "========================"
    
    check_docker
    check_docker_login
    build_and_push
    generate_deployment_commands
}

# Run main function
main "$@"
