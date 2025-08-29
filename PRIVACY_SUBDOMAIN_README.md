# Privacy Subdomain Setup

This document explains how to set up the `privacy.barrim.online` subdomain to serve the privacy policy.

## Overview

The privacy subdomain is configured to serve a static HTML version of the privacy policy through a dedicated nginx service container.

## Files Created/Modified

### New Files
- `privacy/index.html` - HTML version of the privacy policy
- `privacy/Dockerfile` - Docker configuration for the privacy service
- `privacy/nginx.conf` - Nginx configuration for the privacy service
- `setup-privacy-ssl.sh` - Script to generate SSL certificates
- `PRIVACY_SUBDOMAIN_README.md` - This documentation

### Modified Files
- `docker-compose.yml` - Added privacy-service container
- `nginx/default.conf` - Added privacy subdomain configuration

## Setup Steps

### 1. DNS Configuration
Add an A record for `privacy.barrim.online` pointing to your server's IP address.

### 2. SSL Certificate Generation
Run the SSL setup script on your server:

```bash
./setup-privacy-ssl.sh
```

This script will:
- Check if certbot is installed
- Generate SSL certificates for the privacy subdomain
- Test the nginx configuration
- Provide next steps

### 3. Deploy the Services
Start the services using Docker Compose:

```bash
docker-compose up -d
```

This will start:
- `privacy-service` - Serves the privacy policy HTML
- `nginx` - Reverse proxy with SSL termination

### 4. Test the Subdomain
Visit `https://privacy.barrim.online` to verify the setup.

## Architecture

```
Internet → nginx (SSL termination) → privacy-service (HTML serving)
```

- **nginx**: Handles SSL termination and routes requests to the appropriate service
- **privacy-service**: Lightweight nginx container serving the privacy policy HTML
- **SSL**: Let's Encrypt certificates for secure HTTPS access

## Security Features

- HTTPS enforcement with automatic HTTP to HTTPS redirects
- Security headers (X-Frame-Options, X-Content-Type-Options, etc.)
- No-cache headers for privacy policy content
- Resource limits in Docker containers

## Maintenance

### SSL Certificate Renewal
SSL certificates will auto-renew if you have a cron job set up for certbot:

```bash
# Add to crontab (runs twice daily)
0 */12 * * * /usr/bin/certbot renew --quiet
```

### Content Updates
To update the privacy policy:
1. Edit `privacy/index.html`
2. Rebuild and restart the privacy service:
   ```bash
   docker-compose build privacy-service
   docker-compose up -d privacy-service
   ```

### Monitoring
Check service health:
```bash
# Check container status
docker-compose ps

# View logs
docker-compose logs privacy-service

# Health check
curl http://localhost:3001/health
```

## Troubleshooting

### Common Issues

1. **SSL Certificate Errors**
   - Verify DNS A record exists
   - Check firewall settings (ports 80 and 443)
   - Ensure certbot has access to `/var/www/certbot`

2. **Service Not Starting**
   - Check Docker logs: `docker-compose logs privacy-service`
   - Verify port 3001 is not in use
   - Check resource limits in docker-compose.yml

3. **Nginx Configuration Errors**
   - Test configuration: `nginx -t`
   - Check syntax in `nginx/default.conf`
   - Verify SSL certificate paths

### Logs and Debugging
```bash
# View all service logs
docker-compose logs

# View specific service logs
docker-compose logs privacy-service

# View nginx logs
docker-compose logs nginx

# Access privacy service directly
curl http://localhost:3001
```

## Performance Considerations

- The privacy service is lightweight (64MB memory limit)
- Static HTML content is served efficiently
- No database queries or complex processing
- Suitable for high-traffic privacy policy access

## Compliance

The privacy policy HTML includes:
- Proper meta tags for accessibility
- Responsive design for mobile devices
- Semantic HTML structure
- Security headers for compliance
- Clear contact information
- Last updated timestamp
