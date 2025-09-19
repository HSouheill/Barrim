# Barrim Backend - Development Setup

This guide will help you set up the Barrim Backend for local development using Docker.

## Prerequisites

- Docker and Docker Compose installed
- Git

## Quick Start

1. **Run the setup script:**
   ```bash
   ./setup-dev.sh
   ```

2. **Start the development environment:**
   ```bash
   docker-compose -f docker-compose.dev.yml up --build
   ```

3. **Access the application:**
   - Backend API: http://localhost:8080
   - MongoDB: localhost:27017
   - Redis: localhost:6379

## Development Features

### Hot Reloading
The development setup uses [Air](https://github.com/cosmtrek/air) for hot reloading. Any changes to Go files will automatically rebuild and restart the server.

### Services Included

- **Backend**: Go application with hot reloading
- **MongoDB**: Database server
- **Redis**: Cache and session store

### File Structure
```
.
├── Dockerfile.dev          # Development Dockerfile
├── docker-compose.dev.yml  # Development Docker Compose
├── .air.toml              # Air configuration for hot reloading
├── setup-dev.sh           # Development setup script
└── README-DEV.md          # This file
```

## Development Commands

### Start Development Environment
```bash
docker-compose -f docker-compose.dev.yml up --build
```

### Stop Development Environment
```bash
docker-compose -f docker-compose.dev.yml down
```

### View Logs
```bash
# All services
docker-compose -f docker-compose.dev.yml logs -f

# Backend only
docker-compose -f docker-compose.dev.yml logs -f backend

# MongoDB only
docker-compose -f docker-compose.dev.yml logs -f mongodb

# Redis only
docker-compose -f docker-compose.dev.yml logs -f redis
```

### Rebuild Backend Only
```bash
docker-compose -f docker-compose.dev.yml up --build backend
```

### Access Container Shell
```bash
# Backend container
docker-compose -f docker-compose.dev.yml exec backend bash

# MongoDB container
docker-compose -f docker-compose.dev.yml exec mongodb mongosh

# Redis container
docker-compose -f docker-compose.dev.yml exec redis redis-cli
```

## Environment Variables

The development environment uses the following default values:

- **MongoDB**: `mongodb://admin:admin123@localhost:27017/barrim_dev?authSource=admin`
- **Redis**: `localhost:6379` (no password)
- **JWT Secret**: `dev-jwt-secret-key-change-in-production`
- **Port**: `8080`

## Testing the Social Media Fix

Once the development environment is running, you can test the social media update functionality:

1. **Create a test branch:**
   ```bash
   curl -X POST "http://localhost:8080/api/wholesaler/branches" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -F 'data={"name": "Test Branch","phone": "1234567890","category": "Wholesale","subCategory": "Electronics","description": "Test description","country": "Egypt","governorate": "Cairo","district": "Nasr City","city": "Cairo","lat": 30.0444,"lng": 31.2357,"facebook": "https://facebook.com/test","instagram": "https://instagram.com/test"}'
   ```

2. **Update the branch with social media:**
   ```bash
   curl -X PUT "http://localhost:8080/api/wholesaler/branches/BRANCH_ID" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN" \
     -F 'data={"name": "Updated Branch","phone": "1234567890","category": "Wholesale","subCategory": "Electronics","description": "Updated description","country": "Egypt","governorate": "Cairo","district": "Nasr City","city": "Cairo","lat": 30.0444,"lng": 31.2357,"facebook": "https://facebook.com/updated","instagram": "https://instagram.com/updated"}'
   ```

3. **Verify the update:**
   ```bash
   curl -X GET "http://localhost:8080/api/wholesaler/branches/BRANCH_ID" \
     -H "Authorization: Bearer YOUR_JWT_TOKEN"
   ```

## Troubleshooting

### Port Already in Use
If you get a "port already in use" error, stop any existing containers:
```bash
docker-compose -f docker-compose.dev.yml down
docker system prune -f
```

### Permission Issues
If you encounter permission issues with the uploads directory:
```bash
sudo chown -R $USER:$USER uploads/
```

### Database Connection Issues
Make sure MongoDB and Redis are healthy:
```bash
docker-compose -f docker-compose.dev.yml ps
```

### View Build Logs
If the backend fails to start, check the build logs:
```bash
docker-compose -f docker-compose.dev.yml logs backend
```

## Production vs Development

This development setup is different from the production setup:

- **Hot Reloading**: Enabled for faster development
- **Debug Mode**: GIN_MODE=debug for detailed logs
- **Volume Mounting**: Source code is mounted for live changes
- **Simplified Security**: Reduced security constraints for development
- **Local Database**: Uses local MongoDB and Redis instances

For production deployment, use the original `docker-compose.yml` and `Dockerfile`.

