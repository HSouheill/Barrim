#!/bin/bash

# SSL Certificate Renewal Script for Let's Encrypt
# This script renews SSL certificates and restarts nginx

# Configuration
DOMAIN="barrim.com"
PROJECT_DIR="/root/barrim_backend_backup"  # Update this to your actual project path
LOG_FILE="$PROJECT_DIR/ssl-renewal.log"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log with timestamp
log_message() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Change to project directory
cd "$PROJECT_DIR" || {
    log_message "${RED}Error: Cannot change to project directory $PROJECT_DIR${NC}"
    exit 1
}

log_message "${YELLOW}Starting SSL certificate renewal process...${NC}"

# Check if certificates exist
if [ ! -f "./certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
    log_message "${RED}Error: SSL certificate not found for $DOMAIN${NC}"
    exit 1
fi

# Check certificate expiry (optional - certbot handles this automatically)
CERT_EXPIRY=$(openssl x509 -enddate -noout -in "./certbot/conf/live/$DOMAIN/fullchain.pem" 2>/dev/null | cut -d= -f 2)
if [ $? -eq 0 ]; then
    log_message "${YELLOW}Current certificate expires: $CERT_EXPIRY${NC}"
fi

# Attempt certificate renewal
log_message "${YELLOW}Attempting to renew SSL certificate...${NC}"
RENEWAL_OUTPUT=$(docker-compose run --rm certbot renew --quiet 2>&1)
RENEWAL_EXIT_CODE=$?

if [ $RENEWAL_EXIT_CODE -eq 0 ]; then
    log_message "${GREEN}Certificate renewal check completed successfully${NC}"
    
    # Check if renewal actually happened
    if echo "$RENEWAL_OUTPUT" | grep -q "renewed"; then
        log_message "${GREEN}Certificate was renewed! Restarting nginx...${NC}"
        
        # Restart nginx to load new certificate
        docker-compose restart nginx
        NGINX_EXIT_CODE=$?
        
        if [ $NGINX_EXIT_CODE -eq 0 ]; then
            log_message "${GREEN}Nginx restarted successfully${NC}"
            
            # Test HTTPS connection
            if curl -f -s -I "https://$DOMAIN" > /dev/null; then
                log_message "${GREEN}HTTPS connection test successful${NC}"
            else
                log_message "${YELLOW}Warning: HTTPS connection test failed${NC}"
            fi
        else
            log_message "${RED}Error: Failed to restart nginx${NC}"
            exit 1
        fi
    else
        log_message "${GREEN}Certificate is still valid, no renewal needed${NC}"
    fi
else
    log_message "${RED}Error: Certificate renewal failed${NC}"
    log_message "${RED}Output: $RENEWAL_OUTPUT${NC}"
    exit 1
fi

# Clean up old log entries (keep last 100 lines)
if [ -f "$LOG_FILE" ]; then
    tail -n 100 "$LOG_FILE" > "${LOG_FILE}.tmp" && mv "${LOG_FILE}.tmp" "$LOG_FILE"
fi

log_message "${GREEN}SSL renewal process completed${NC}"
