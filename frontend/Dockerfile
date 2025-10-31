# Multi-stage build: First stage builds Flutter app
FROM dart:stable AS flutter-builder

# Build arguments for cache busting
ARG BUILD_DATE
ARG VERSION
ARG BUILD_TIMESTAMP
ARG CACHE_BUST

# Install Flutter dependencies
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"

# Pre-download Flutter artifacts
RUN flutter precache
RUN flutter config --enable-web

# Set working directory
WORKDIR /app

# Copy pubspec files first for better layer caching
COPY pubspec.yaml pubspec.lock ./

# Get dependencies
RUN flutter pub get

# Copy source code
COPY . .

# Create web platform if it doesn't exist
RUN if [ ! -d "web" ]; then \
    flutter create . --platforms web; \
    fi

# Clean previous build to ensure fresh build
RUN flutter clean

# Build Flutter web app for production
RUN flutter build web --release --no-tree-shake-icons

# Second stage: Serve with nginx
FROM nginx:alpine

# Remove default nginx website and config
RUN rm -rf /usr/share/nginx/html/*
RUN rm /etc/nginx/conf.d/default.conf

# Copy built web files from the Flutter build stage
COPY --from=flutter-builder /app/build/web/ /usr/share/nginx/html/

# Copy custom nginx config
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Verify the index.html file exists and has content
RUN ls -la /usr/share/nginx/html/ && \
    [ -f /usr/share/nginx/html/index.html ] && \
    [ -s /usr/share/nginx/html/index.html ] || (echo "index.html is missing or empty!" && exit 1)

# Test nginx configuration
RUN nginx -t

# Expose port 80
EXPOSE 80