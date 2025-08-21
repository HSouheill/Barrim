#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="barrim"
IMAGE_NAME="barrim-backend"
REPO_DIR="./main.go"

log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}"
}

info() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')] INFO: $1${NC}"
}

# Check if swarm is initialized
check_swarm() {
    if ! docker info | grep -q "Swarm: active"; then
        error "Docker Swarm is not initialized. Run 'docker swarm init' first."
        exit 1
    fi
}

# Build new image
build_image() {
    local version=$1
    log "Building new image: $IMAGE_NAME:$version"
    
    cd $REPO_DIR
    docker build -t $IMAGE_NAME:$version .
    docker tag $IMAGE_NAME:$version $IMAGE_NAME:latest
    
    log "Image built successfully"
}

# Deploy stack
deploy_stack() {
    log "Deploying stack: $STACK_NAME"
    
    cd $REPO_DIR
    docker stack deploy -c docker-compose.yml $STACK_NAME
    
    log "Stack deployed successfully"
}

# Update service
update_service() {
    local version=$1
    log "Updating backend service with image: $IMAGE_NAME:$version"
    
    docker service update \
        --image $IMAGE_NAME:$version \
        --update-parallelism 1 \
        --update-delay 10s \
        --update-failure-action rollback \
        --update-monitor 60s \
        $STACK_NAME\_backend
    
    log "Service update initiated"
}

# Monitor deployment
monitor_deployment() {
    log "Monitoring deployment progress..."
    
    # Wait for deployment to complete
    local max_attempts=60
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local status=$(docker service ps $STACK_NAME\_backend --format "table {{.CurrentState}}" | grep -E "(Running|Failed|Rejected)" | head -1)
        
        if echo "$status" | grep -q "Running"; then
            log "Deployment successful!"
            return 0
        elif echo "$status" | grep -q -E "(Failed|Rejected)"; then
            error "Deployment failed!"
            return 1
        fi
        
        info "Deployment in progress... (attempt $attempt/$max_attempts)"
        sleep 10
        ((attempt++))
    done
    
    error "Deployment timed out!"
    return 1
}

# Rollback service
rollback_service() {
    log "Rolling back service..."
    
    docker service rollback $STACK_NAME\_backend
    
    if monitor_deployment; then
        log "Rollback successful!"
    else
        error "Rollback failed!"
        exit 1
    fi
}

# Show service status
show_status() {
    echo
    info "=== Stack Status ==="
    docker stack ps $STACK_NAME
    
    echo
    info "=== Service Status ==="
    docker service ls --filter name=$STACK_NAME
    
    echo
    info "=== Backend Service Details ==="
    docker service ps $STACK_NAME\_backend
}

# Show logs
show_logs() {
    local service=${1:-backend}
    log "Showing logs for $STACK_NAME\_$service"
    docker service logs -f $STACK_NAME\_$service
}

# Scale service
scale_service() {
    local service=$1
    local replicas=$2
    
    log "Scaling $STACK_NAME\_$service to $replicas replicas"
    docker service scale $STACK_NAME\_$service=$replicas
}

# Remove stack
remove_stack() {
    warn "Removing stack: $STACK_NAME"
    read -p "Are you sure? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        docker stack rm $STACK_NAME
        log "Stack removed"
    else
        log "Operation cancelled"
    fi
}

# Main script logic
case "$1" in
    "init")
        check_swarm
        log "Creating secrets..."
        
        # Create secrets if they don't exist
        if ! docker secret ls | grep -q mongo_password; then
            read -s -p "Enter MongoDB password: " mongo_pass
            echo
            echo "$mongo_pass" | docker secret create mongo_password -
        fi
        
        if ! docker secret ls | grep -q jwt_secret; then
            read -s -p "Enter JWT secret: " jwt_secret
            echo
            echo "$jwt_secret" | docker secret create jwt_secret -
        fi
        
        log "Secrets created successfully"
        ;;
    
    "deploy")
        check_swarm
        VERSION=${2:-$(date +%Y%m%d-%H%M%S)}
        
        log "Starting deployment with version: $VERSION"
        
        # Pull latest changes
        cd $REPO_DIR
        git pull origin main
        
        # Build and deploy
        build_image $VERSION
        
        if docker stack ls | grep -q $STACK_NAME; then
            update_service $VERSION
        else
            deploy_stack
        fi
        
        if monitor_deployment; then
            show_status
        else
            error "Deployment failed!"
            exit 1
        fi
        ;;
    
    "rollback")
        check_swarm
        rollback_service
        ;;
    
    "status")
        check_swarm
        show_status
        ;;
    
    "logs")
        check_swarm
        show_logs $2
        ;;
    
    "scale")
        check_swarm
        if [ -z "$2" ] || [ -z "$3" ]; then
            error "Usage: $0 scale <service> <replicas>"
            exit 1
        fi
        scale_service $2 $3
        ;;
    
    "remove")
        check_swarm
        remove_stack
        ;;
    
    *)
        echo "Usage: $0 {init|deploy|rollback|status|logs|scale|remove}"
        echo ""
        echo "Commands:"
        echo "  init                 - Initialize secrets and prepare for deployment"
        echo "  deploy [version]     - Deploy or update the application"
        echo "  rollback             - Rollback to previous version"
        echo "  status               - Show current stack status"
        echo "  logs [service]       - Show logs for a service (default: backend)"
        echo "  scale <service> <n>  - Scale a service to n replicas"
        echo "  remove               - Remove the entire stack"
        echo ""
        echo "Examples:"
        echo "  $0 init"
        echo "  $0 deploy"
        echo "  $0 deploy v1.2.3"
        echo "  $0 scale backend 3"
        echo "  $0 logs backend"
        exit 1
        ;;
esac
