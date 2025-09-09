# Multi-stage build: First stage builds Flutter app
FROM dart:stable AS flutter-builder

# Install Flutter
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

# Build Flutter web app for production
RUN flutter build web --release

# Second stage: Serve with nginx
FROM nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy built web files from the Flutter build stage
COPY --from=flutter-builder /app/build/web/ /usr/share/nginx/html

# Copy custom nginx config
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Expose port 80 (nginx default)
EXPOSE 80