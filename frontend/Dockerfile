# Use the official Nginx image
FROM nginx:alpine

# Remove default nginx website
RUN rm -rf /usr/share/nginx/html/*

# Copy built web files from build/web (Flutter build output)
COPY build/web/ /usr/share/nginx/html

# Copy custom nginx config
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

# Expose port 80 (nginx default)
EXPOSE 80