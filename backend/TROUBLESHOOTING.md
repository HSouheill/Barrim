# Troubleshooting Guide

## Issue 1: Google Auth 500 Error

### Problem
The `/api/auth/google-auth-without-firebase` endpoint is returning a 500 internal server error.

### Root Causes
1. **Missing JWT_SECRET environment variable** - Required for generating JWT tokens
2. **Database connection issues** - MongoDB connection problems
3. **Google token validation failures** - Network issues or invalid tokens

### Solutions

#### 1. Check Environment Variables
Run the environment checker:
```bash
go run check_env.go
```

Ensure these variables are set in your `.env` file:
```env
JWT_SECRET=your_secure_jwt_secret_here
MONGODB_URI=your_mongodb_connection_string
PORT=8080
```

#### 2. Verify MongoDB Connection
Check if MongoDB is running and accessible:
```bash
# Test MongoDB connection
mongo your_mongodb_uri --eval "db.runCommand('ping')"
```

#### 3. Check Logs
The enhanced logging will now show detailed error messages. Look for:
- "Google auth error:" messages
- Database connection errors
- JWT generation failures

#### 4. Test Google Auth Endpoint
```bash
curl -X POST http://localhost:8080/api/auth/google-auth-without-firebase \
  -H "Content-Type: application/json" \
  -d '{"idToken": "your_google_id_token"}'
```

## Issue 2: WebSocket 400 Error

### Problem
The `/api/ws` endpoint is rejecting connections with a 400 error: "websocket: the client is not using the websocket protocol: 'upgrade' token not found in 'Connection' header"

### Root Causes
1. **Client not sending proper WebSocket headers**
2. **Missing Connection: upgrade header**
3. **Authentication middleware blocking WebSocket upgrade**

### Solutions

#### 1. Client Implementation
Ensure your client sends proper WebSocket headers:

**Dart/Flutter:**
```dart
import 'package:web_socket_channel/web_socket_channel.dart';

final channel = WebSocketChannel.connect(
  Uri.parse('wss://barrim.online/api/ws'),
  protocols: ['websocket'],
);

// After connection, authenticate:
channel.sink.add('AUTH:your_jwt_token_here');
```

**JavaScript:**
```javascript
const ws = new WebSocket('wss://barrim.online/api/ws');

ws.onopen = function() {
  // Authenticate after connection
  ws.send('AUTH:your_jwt_token_here');
};
```

#### 2. Server Changes Made
- Added public WebSocket endpoint at `/api/ws` (no authentication required)
- Enhanced WebSocket handler to support unauthenticated connections
- Added authentication flow after connection establishment

#### 3. Test WebSocket Connection
```bash
# Test with wscat (install with: npm install -g wscat)
wscat -c wss://barrim.online/api/ws

# After connection, send authentication:
AUTH:your_jwt_token_here
```

## General Debugging

### 1. Check Server Logs
Look for detailed error messages in your server logs:
```bash
# If running with Docker
docker logs your_container_name

# If running directly
go run main.go
```

### 2. Test Endpoints
```bash
# Health check
curl http://localhost:8080/health

# Test database connection
curl http://localhost:8080/api/users/profile \
  -H "Authorization: Bearer your_jwt_token"
```

### 3. Environment Variables
Create a `.env` file in your project root:
```env
JWT_SECRET=your_very_secure_secret_key_here
MONGODB_URI=mongodb://localhost:27017/barrim
PORT=8080
TWILIO_ACCOUNT_SID=your_twilio_sid
TWILIO_AUTH_TOKEN=your_twilio_token
TWILIO_PHONE_NUMBER=your_twilio_phone
TWILIO_VERIFY_SERVICE_SID=your_verify_service_sid
```

### 4. Restart Services
After making changes:
```bash
# Stop the server
# Rebuild if using Docker
docker-compose down
docker-compose up --build

# Or restart the Go server
go run main.go
```

## Prevention

1. **Always check environment variables** before starting the server
2. **Test WebSocket connections** with proper headers
3. **Monitor server logs** for detailed error messages
4. **Use the enhanced logging** added to the Google auth function
5. **Test authentication flow** after WebSocket connection

## Support

If issues persist:
1. Check the enhanced server logs for specific error messages
2. Verify all environment variables are set correctly
3. Test database connectivity
4. Ensure proper WebSocket headers are sent from the client
