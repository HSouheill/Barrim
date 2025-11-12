# Admin Dashboard Docker Deployment Guide

This guide explains how to build, push, and deploy the admin dashboard Docker image.

## Prerequisites

1. **Docker installed** on your local machine and server
2. **Docker Hub account** (create one at https://hub.docker.com if you don't have one)
3. **Docker Hub credentials** for pushing/pulling images

## Step 1: Build and Push to Docker Hub

### Option A: Using the Build Script (Recommended)

1. Make the script executable:
   ```bash
   chmod +x build-and-push.sh
   ```

2. Run the script:
   ```bash
   ./build-and-push.sh [version] [dockerhub-username]
   ```
   
   Example:
   ```bash
   ./build-and-push.sh 1.0.1 myusername
   ```

   If you don't provide arguments, it will use:
   - Version: `latest`
   - Username: `your-username` (you'll need to edit the script or provide it)

### Option B: Manual Build and Push

1. **Login to Docker Hub:**
   ```bash
   docker login
   ```

2. **Navigate to the frontend directory:**
   ```bash
   cd frontend
   ```

3. **Build the image:**
   ```bash
   docker build \
     --tag your-username/barrim-admin-dashboard:1.0.1 \
     --tag your-username/barrim-admin-dashboard:latest \
     -f Dockerfile \
     .
   ```
   
   Replace `your-username` with your Docker Hub username.

4. **Push the image:**
   ```bash
   # Push versioned tag
   docker push your-username/barrim-admin-dashboard:1.0.1
   
   # Push latest tag
   docker push your-username/barrim-admin-dashboard:latest
   ```

## Step 2: Pull and Deploy on Server

### Option A: Using the Deploy Script (Recommended)

1. **Copy the deploy script to your server** (or clone the repo on the server)

2. **Make the script executable:**
   ```bash
   chmod +x deploy-on-server.sh
   ```

3. **Run the script:**
   ```bash
   ./deploy-on-server.sh [version] [dockerhub-username] [port]
   ```
   
   Example:
   ```bash
   ./deploy-on-server.sh 1.0.1 myusername 3000
   ```

   Defaults:
   - Version: `latest`
   - Username: `your-username` (edit script or provide it)
   - Port: `3000`

### Option B: Manual Deployment on Server

1. **SSH into your server**

2. **Login to Docker Hub (if needed):**
   ```bash
   docker login
   ```

3. **Pull the image:**
   ```bash
   docker pull your-username/barrim-admin-dashboard:1.0.1
   ```

4. **Stop and remove existing container (if any):**
   ```bash
   docker stop barrim-admin-dashboard || true
   docker rm barrim-admin-dashboard || true
   ```

5. **Run the container:**
   ```bash
   docker run -d \
     --name barrim-admin-dashboard \
     --restart unless-stopped \
     -p 3000:80 \
     your-username/barrim-admin-dashboard:1.0.1
   ```

6. **Verify it's running:**
   ```bash
   docker ps
   docker logs barrim-admin-dashboard
   ```

## Step 3: Access the Dashboard

Once deployed, access the admin dashboard at:
- **Local:** http://localhost:3000
- **Server:** http://your-server-ip:3000

If you're using a reverse proxy (nginx, etc.), configure it to proxy to `localhost:3000`.

## Updating the Dashboard

To update the dashboard with a new version:

1. **Build and push new version** (on your local machine):
   ```bash
   ./build-and-push.sh 1.0.2 myusername
   ```

2. **Pull and redeploy** (on your server):
   ```bash
   ./deploy-on-server.sh 1.0.2 myusername 3000
   ```

   Or manually:
   ```bash
   docker pull your-username/barrim-admin-dashboard:1.0.2
   docker stop barrim-admin-dashboard
   docker rm barrim-admin-dashboard
   docker run -d \
     --name barrim-admin-dashboard \
     --restart unless-stopped \
     -p 3000:80 \
     your-username/barrim-admin-dashboard:1.0.2
   ```

## Troubleshooting

### Build Issues

- **Flutter build fails:** Make sure all dependencies are up to date:
  ```bash
  cd frontend
  flutter pub get
  ```

- **Docker build is slow:** The first build downloads Flutter SDK. Subsequent builds will be faster due to layer caching.

### Deployment Issues

- **Port already in use:** Change the port in the deploy command:
  ```bash
   -p 8080:80  # Use port 8080 instead of 3000
   ```

- **Container won't start:** Check logs:
  ```bash
   docker logs barrim-admin-dashboard
   ```

- **Image not found:** Make sure you've pushed the image to Docker Hub and are using the correct username/tag.

### Viewing Logs

```bash
# View all logs
docker logs barrim-admin-dashboard

# Follow logs in real-time
docker logs -f barrim-admin-dashboard

# View last 50 lines
docker logs --tail 50 barrim-admin-dashboard
```

## Docker Compose Alternative

You can also use docker-compose for deployment. Create a `docker-compose.prod.yml` on your server:

```yaml
version: '3.8'

services:
  admin-dashboard:
    image: your-username/barrim-admin-dashboard:latest
    container_name: barrim-admin-dashboard
    ports:
      - "3000:80"
    restart: unless-stopped
```

Then deploy with:
```bash
docker-compose -f docker-compose.prod.yml pull
docker-compose -f docker-compose.prod.yml up -d
```

## Security Notes

- For production, consider using Docker secrets or environment variables for sensitive configuration
- Use specific version tags instead of `latest` in production
- Set up proper firewall rules on your server
- Consider using HTTPS with a reverse proxy (nginx, Traefik, etc.)

