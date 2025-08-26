# Remember Me Functionality

This document describes the implementation of the "Remember Me" feature in the Barrim Backend application.

## Overview

The "Remember Me" functionality allows users to save their login credentials securely in Redis, enabling automatic login on subsequent visits without re-entering their email/phone and password.

## Features

- **Secure Storage**: Credentials are encrypted using AES-GCM before storing in Redis
- **Token-based**: Uses secure random tokens to retrieve stored credentials
- **Automatic Cleanup**: Expired tokens are automatically removed
- **Device Tracking**: Stores device information for security
- **Configurable Expiration**: Default 30-day expiration for remembered credentials

## Architecture

### Components

1. **Redis Storage**: Encrypted credentials stored in Redis with TTL
2. **Encryption**: AES-GCM encryption with configurable keys
3. **Token Generation**: Secure random tokens for credential retrieval
4. **Cleanup Routines**: Background processes to remove expired tokens

### Data Flow

1. User logs in with `rememberMe: true`
2. System generates secure remember me token
3. Credentials are encrypted and stored in Redis
4. Token is returned to frontend
5. Frontend stores token securely (localStorage, cookies, etc.)
6. On subsequent visits, frontend uses token to retrieve credentials
7. User can be automatically logged in

## API Endpoints

### Login with Remember Me

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "user@example.com",
  "password": "password123",
  "rememberMe": true
}
```

**Response:**
```json
{
  "status": 200,
  "message": "Login successful",
  "data": {
    "token": "jwt_token_here",
    "refreshToken": "refresh_token_here",
    "user": { ... },
    "rememberMeToken": "remember_me_token_here"
  }
}
```

### Get Remembered Credentials

```http
POST /api/auth/remember-me/get
Content-Type: application/json

{
  "rememberMeToken": "token_here"
}
```

**Response:**
```json
{
  "status": 200,
  "message": "Remembered credentials retrieved successfully",
  "data": {
    "email": "user@example.com",
    "phone": "+1234567890",
    "userType": "user",
    "userId": "user_id_here"
  }
}
```

### Remove Remembered Credentials

```http
POST /api/auth/remember-me/remove
Content-Type: application/json

{
  "rememberMeToken": "token_here"
}
```

**Response:**
```json
{
  "status": 200,
  "message": "Remembered credentials removed successfully"
}
```

## Configuration

### Environment Variables

```env
# Redis Configuration
REDIS_ADDR=localhost:6379
REDIS_PASSWORD=your_redis_password
REDIS_DB=0

# Encryption Key (32 bytes recommended)
REMEMBER_ME_ENCRYPTION_KEY=your_32_byte_encryption_key_here
```

### Docker Configuration

The Redis service is configured in `docker-compose.yml`:

```yaml
redis:
  image: redis:7-alpine
  container_name: redis
  ports:
    - "127.0.0.1:6379:6379"
  command: redis-server --appendonly yes --requirepass ${REDIS_PASSWORD:-}
  volumes:
    - redis_data:/data
  networks:
    - app-network
```

## Security Features

### Encryption

- **Algorithm**: AES-GCM (Galois/Counter Mode)
- **Key Size**: 32 bytes (256 bits)
- **Nonce**: Randomly generated for each encryption
- **Authentication**: Built-in integrity verification

### Token Security

- **Length**: 32 random bytes (256 bits)
- **Encoding**: Base64 URL-safe
- **Entropy**: Cryptographically secure random generation
- **Expiration**: Automatic cleanup of expired tokens

### Data Protection

- **No Password Storage**: Only email, phone, userType, and userId stored
- **Device Tracking**: User agent information stored for audit
- **Automatic Cleanup**: Expired tokens removed automatically
- **Redis Security**: Password-protected Redis instance

## Implementation Details

### Frontend Integration

```javascript
// Store remember me token after login
if (response.data.rememberMeToken) {
  localStorage.setItem('rememberMeToken', response.data.rememberMeToken);
}

// Check for remembered credentials on app start
const rememberMeToken = localStorage.getItem('rememberMeToken');
if (rememberMeToken) {
  try {
    const response = await fetch('/api/auth/remember-me/get', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ rememberMeToken })
    });
    
    if (response.ok) {
      const data = await response.json();
      // Auto-fill login form or auto-login
      fillLoginForm(data.data);
    }
  } catch (error) {
    // Remove invalid token
    localStorage.removeItem('rememberMeToken');
  }
}
```

### Cleanup Routines

The system runs automatic cleanup every 6 hours:

```go
func (ac *AuthController) startRememberMeCleanupRoutine() {
    ticker := time.NewTicker(6 * time.Hour)
    defer ticker.Stop()

    for range ticker.C {
        if err := ac.cleanupExpiredRememberMeTokens(); err != nil {
            ac.logger.Printf("Remember me cleanup failed: %v", err)
        }
    }
}
```

## Error Handling

### Common Error Scenarios

1. **Redis Unavailable**: Graceful fallback, remember me disabled
2. **Invalid Token**: 401 Unauthorized response
3. **Expired Token**: Automatic cleanup, 401 response
4. **Encryption Errors**: Logged for debugging, 500 response

### Error Responses

```json
{
  "status": 401,
  "message": "Invalid or expired remember me token"
}
```

```json
{
  "status": 500,
  "message": "Remember me service unavailable"
}
```

## Monitoring and Logging

### Log Messages

- `"Initial remember me cleanup failed: %v"`
- `"Remember me cleanup failed: %v"`
- `"Failed to store remember me credentials: %v"`

### Metrics to Monitor

- Redis connection status
- Remember me token count
- Cleanup routine success rate
- Encryption/decryption errors

## Best Practices

### Frontend

1. **Secure Storage**: Use secure storage methods (localStorage for development, secure cookies for production)
2. **Token Validation**: Always validate tokens before use
3. **Error Handling**: Gracefully handle service unavailability
4. **User Control**: Allow users to disable remember me

### Backend

1. **Key Management**: Use strong, unique encryption keys
2. **Token Rotation**: Consider implementing token rotation for long-lived sessions
3. **Rate Limiting**: Apply rate limiting to remember me endpoints
4. **Audit Logging**: Log remember me usage for security monitoring

## Troubleshooting

### Common Issues

1. **Redis Connection Failed**
   - Check Redis service status
   - Verify network connectivity
   - Check authentication credentials

2. **Encryption Errors**
   - Verify encryption key length (32 bytes)
   - Check for special characters in key
   - Ensure consistent key across deployments

3. **Token Not Working**
   - Check token expiration
   - Verify Redis data persistence
   - Check cleanup routine logs

### Debug Commands

```bash
# Check Redis status
docker exec -it redis redis-cli ping

# Check remember me keys
docker exec -it redis redis-cli keys "remember_me:*"

# Monitor Redis operations
docker exec -it redis redis-cli monitor
```

## Future Enhancements

1. **Multi-device Support**: Allow multiple devices per user
2. **Device Management**: User control over remembered devices
3. **Enhanced Security**: Biometric authentication integration
4. **Analytics**: Usage patterns and security insights
5. **Compliance**: GDPR and privacy regulation compliance features
