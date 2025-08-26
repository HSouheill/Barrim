FROM alpine:latest

# Install ca-certificates for HTTPS requests, curl for health checks, and redis-cli for debugging
RUN apk --no-cache add ca-certificates curl tzdata redis

WORKDIR /app

# Create non-root user
RUN addgroup -g 1001 -S appuser && \
    adduser -S appuser -u 1001

# Copy pre-built binary into the image
COPY barrim_backend ./barrim_backend

# Change ownership to non-root user
RUN chown -R appuser:appuser /app

USER appuser

# Expose port 8080
EXPOSE 8080

CMD ["./barrim_backend"]
