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

# Add web platform support (only if not already present)
RUN if [ ! -d "web" ]; then flutter create . --platforms web; fi

# Build the app for the web
RUN flutter build web --release

# Copy nginx configuration
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Create a build info file in the production image
RUN echo "Build Date: ${BUILD_DATE:-$(date)}" > /app/build/web/build_info.txt \
    && echo "Version: ${VERSION:-local}" >> /app/build/web/build_info.txt \
    && echo "Timestamp: ${BUILD_TIMESTAMP:-$(date +%s)}" >> /app/build/web/build_info.txt

# Expose port 80
EXPOSE 80

# Start nginx with the built Flutter app
CMD ["nginx", "-g", "daemon off;"]
