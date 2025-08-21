# Build stage
FROM debian:latest AS build-env

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

# Copy the built Flutter web files
COPY --from=build-env /home/flutter/app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
