#!/bin/bash

# Script to set up SSL certificates for privacy.barrim.online subdomain
# This script should be run on the server where you want to generate SSL certificates

echo "Setting up SSL certificates for privacy.barrim.online..."

# Check if certbot is installed
if ! command -v certbot &> /dev/null; then
    echo "Error: certbot is not installed. Please install it first."
    echo "On Ubuntu/Debian: sudo apt-get install certbot"
    echo "On CentOS/RHEL: sudo yum install certbot"
    exit 1
fi

# Create webroot directory if it doesn't exist
sudo mkdir -p /var/www/certbot

# Generate SSL certificate for privacy subdomain
echo "Generating SSL certificate for privacy.barrim.online..."
sudo certbot certonly --webroot \
    --webroot-path=/var/www/certbot \
    --email info@barrim.com \
    --agree-tos \
    --no-eff-email \
    --domains privacy.barrim.online

if [ $? -eq 0 ]; then
    echo "SSL certificate generated successfully!"
    echo "Certificate location: /etc/letsencrypt/live/privacy.barrim.online/"
    
    # Test nginx configuration
    echo "Testing nginx configuration..."
    sudo nginx -t
    
    if [ $? -eq 0 ]; then
        echo "Nginx configuration is valid. You can now reload nginx:"
        echo "sudo nginx -s reload"
    else
        echo "Nginx configuration has errors. Please fix them before reloading."
    fi
else
    echo "Error: Failed to generate SSL certificate."
    echo "Please check the error messages above and try again."
    exit 1
fi

echo ""
echo "Next steps:"
echo "1. Make sure your DNS has an A record for privacy.barrim.online pointing to your server IP"
echo "2. Ensure ports 80 and 443 are open on your firewall"
echo "3. Reload nginx: sudo nginx -s reload"
echo "4. Test the subdomain: https://privacy.barrim.online"
