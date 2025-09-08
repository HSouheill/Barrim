# Use official Flutter image for much faster builds
FROM dart:stable

# Add build arguments to force rebuilds
ARG BUILD_DATE
ARG VERSION
ARG BUILD_TIMESTAMP

# Install Flutter
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    nginx \
    && rm -rf /var/lib/apt/lists/*

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"

# Pre-download Flutter artifacts
RUN flutter precache

# Enable flutter web
RUN flutter config --enable-web

# Create a file with build timestamp to force rebuilds
RUN echo "Build Date: ${BUILD_DATE:-$(date)}" > /build_info.txt \
    && echo "Version: ${VERSION:-local}" >> /build_info.txt \
    && echo "Timestamp: ${BUILD_TIMESTAMP:-$(date +%s)}" >> /build_info.txt

# Set working directory
WORKDIR /app

# Copy only pubspec files first for better layer caching
COPY pubspec.yaml pubspec.lock ./

# Get app dependencies (this layer will be cached unless pubspec changes)
RUN flutter pub get

# Copy the app source code
COPY . .

# Debug: Check if web directory exists and list contents
RUN echo "Checking web directory..." && \
    if [ -d "web" ]; then \
        echo "Web directory exists, listing contents:" && \
        ls -la web/; \
    else \
        echo "Web directory does not exist"; \
    fi

# Ensure Flutter doctor is working and web is enabled
RUN flutter doctor -v

# Ensure web platform is properly created (skip if already exists)
RUN if [ ! -d "web" ]; then \
        echo "Creating web platform..."; \
        flutter create . --platforms web; \
    else \
        echo "Web platform already exists, skipping creation"; \
    fi

# Debug: Verify web directory after creation
RUN echo "Final web directory check:" && \
    ls -la web/ && \
    echo "Web directory contents verified"

# Expose port for Flutter web development server
EXPOSE 3000

# Create a startup script to debug and run Flutter web
RUN echo '#!/bin/bash' > /start.sh && \
    echo 'echo "=== Container startup debug ==="' >> /start.sh && \
    echo 'echo "Current directory: $(pwd)"' >> /start.sh && \
    echo 'echo "Directory contents:"' >> /start.sh && \
    echo 'ls -la' >> /start.sh && \
    echo 'echo "Web directory check:"' >> /start.sh && \
    echo 'if [ -d "web" ]; then' >> /start.sh && \
    echo '    echo "Web directory exists, contents:"' >> /start.sh && \
    echo '    ls -la web/' >> /start.sh && \
    echo 'else' >> /start.sh && \
    echo '    echo "Web directory does not exist, creating..."' >> /start.sh && \
    echo '    flutter create . --platforms web' >> /start.sh && \
    echo 'fi' >> /start.sh && \
    echo 'echo "Starting Flutter web server..."' >> /start.sh && \
    echo 'flutter run web --web-port 3000 --web-hostname 0.0.0.0' >> /start.sh && \
    chmod +x /start.sh

# Start Flutter web development server
CMD ["/start.sh"]
