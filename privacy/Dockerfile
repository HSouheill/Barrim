FROM nginx:alpine

# Copy the HTML file to nginx's default serving directory
COPY index.html /usr/share/nginx/html/index.html

# Copy a custom nginx configuration for the privacy service
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Expose port 80
EXPOSE 80

# Start nginx
CMD ["nginx", "-g", "daemon off;"]
