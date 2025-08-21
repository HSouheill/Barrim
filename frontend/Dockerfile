# Build stage
FROM debian:latest AS build-env

# Install Flutter dependencies
RUN apt-get update 
RUN apt-get install -y curl git wget unzip libgconf-2-4 gdb libstdc++6 libglu1-mesa fonts-droid-fallback lib32stdc++6 python3
RUN apt-get clean

# Clone the flutter repo
RUN git clone https://github.com/flutter/flutter.git /usr/local/flutter

# Set flutter path
ENV PATH="/usr/local/flutter/bin:/usr/local/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Run flutter doctor
RUN flutter doctor -v

# Enable flutter web
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# Copy the app files to the container
COPY . /app/
WORKDIR /app/

# Get app dependencies
RUN flutter pub get

# Build the app for the web
RUN flutter build web

# Production stage
FROM nginx:alpine

# Copy the built Flutter web files
COPY --from=build-env /app/build/web /usr/share/nginx/html

# Copy nginx configuration
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
