#!/bin/bash

# Configuration
DOMAIN="barrim.com"
EMAIL="husseinsouheil15@gmail.com"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}Setting up SSL with Let's Encrypt for $DOMAIN${NC}"

# Check if domain is set
if [ "$DOMAIN" = "barrim.com" ]; then
    echo -e "${RED}Error: Please update the DOMAIN variable in this script${NC}"
    exit 1
fi

# Check if email is set
if [ "$EMAIL" = "husseinsouheil15@gmail.com" ]; then
    echo -e "${RED}Error: Please update the EMAIL variable in this script${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p nginx/conf.d
mkdir -p certbot/conf
mkdir -p certbot/www

# Update nginx configuration with actual domain
echo -e "${YELLOW}Updating nginx configuration...${NC}"
sed -i "s/barrim.com/$DOMAIN/g" nginx/conf.d/default.conf

# Update docker-compose with actual domain and email
echo -e "${YELLOW}Updating docker-compose configuration...${NC}"
sed -i "s/barrim.com/$DOMAIN/g" docker-compose.yml
sed -i "s/husseinsouheil15@gmail.com/$EMAIL/g" docker-compose.yml

# Start services without SSL first
echo -e "${YELLOW}Starting services for initial setup...${NC}"
docker-compose up -d mongodb backend nginx

# Wait for services to be ready
echo -e "${YELLOW}Waiting for services to start...${NC}"
sleep 10

# Test if nginx is responding
echo -e "${YELLOW}Testing nginx configuration...${NC}"
if curl -f http://localhost/.well-known/acme-challenge/test 2>/dev/null; then
    echo -e "${GREEN}Nginx is ready for SSL setup${NC}"
else
    echo -e "${YELLOW}Nginx test endpoint not ready, continuing anyway...${NC}"
fi

# Get SSL certificate
echo -e "${YELLOW}Requesting SSL certificate from Let's Encrypt...${NC}"
docker-compose run --rm certbot certonly --webroot \
    -w /var/www/certbot \
    --force-renewal \
    --email $EMAIL \
    -d $DOMAIN \
    --agree-tos \
    --no-eff-email

# Check if certificate was created
if [ -f "./certbot/conf/live/$DOMAIN/fullchain.pem" ]; then
    echo -e "${GREEN}SSL certificate obtained successfully!${NC}"
    
    # Restart nginx to load SSL certificate
    echo -e "${YELLOW}Restarting nginx with SSL configuration...${NC}"
    docker-compose restart nginx
    
    echo -e "${GREEN}Setup complete! Your API is now available at https://$DOMAIN${NC}"
    echo -e "${YELLOW}Don't forget to update your Flutter app to use https://$DOMAIN${NC}"
else
    echo -e "${RED}Failed to obtain SSL certificate. Please check the logs above.${NC}"
    exit 1
fi

# Create renewal script
echo -e "${YELLOW}Creating SSL renewal script...${NC}"
cat > renew-ssl.sh << EOF
#!/bin/bash
docker-compose run --rm certbot renew --quiet
docker-compose restart nginx
EOF

chmod +x renew-ssl.sh

echo -e "${GREEN}SSL renewal script created: renew-ssl.sh${NC}"
echo -e "${YELLOW}Add this to your crontab to auto-renew: 0 12 * * * /root/barrim_backend_backup/renew-ssl.sh${NC}"
