# Build stage
FROM debian:latest AS build-env

# Add build arguments to force rebuilds
ARG BUILD_DATE
ARG VERSION
ARG BUILD_TIMESTAMP

# Install Flutter dependencies
RUN apt-get update 
RUN apt-get install -y curl git wget unzip gdb libstdc++6 libglu1-mesa fonts-droid-fallback python3 ca-certificates
RUN apt-get clean

# Create a non-root user
RUN useradd -m -s /bin/bash flutter
USER flutter
WORKDIR /home/flutter

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git /home/flutter/flutter

# Set flutter path
ENV PATH="/home/flutter/flutter/bin:/home/flutter/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor
RUN flutter doctor -v

# Enable flutter web
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# Create a file with build timestamp to force rebuilds
RUN echo "Build Date: ${BUILD_DATE:-$(date)}" > /home/flutter/build_info.txt
RUN echo "Version: ${VERSION:-local}" >> /home/flutter/build_info.txt
RUN echo "Timestamp: ${BUILD_TIMESTAMP:-$(date +%s)}" >> /home/flutter/build_info.txt

# Copy the app files to the container
COPY --chown=flutter:flutter . /home/flutter/app/
WORKDIR /home/flutter/app/

# Get app dependencies
RUN flutter pub get

# Add web platform support
RUN flutter create . --platforms web

# Build the app for the web
RUN flutter build web

# Production stage
FROM nginx:alpine

# Add build arguments to production stage
ARG BUILD_DATE
ARG VERSION
ARG BUILD_TIMESTAMP

# Copy the built Flutter web files
COPY --from=build-env /home/flutter/app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Create a build info file in the production image
RUN echo "Build Date: ${BUILD_DATE:-$(date)}" > /usr/share/nginx/html/build_info.txt
RUN echo "Version: ${VERSION:-local}" >> /usr/share/nginx/html/build_info.txt
RUN echo "Timestamp: ${BUILD_TIMESTAMP:-$(date +%s)}" >> /usr/share/nginx/html/build_info.txt

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
