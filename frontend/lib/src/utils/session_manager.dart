import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_constant.dart';
import '../services/api_services.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'performance_config.dart';

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userInfoKey = 'user_info';
  static const String _lastActivityKey = 'last_activity';
  static const String _sessionTimeoutKey = 'session_timeout';

  // Session configuration
  static const Duration _defaultSessionTimeout = Duration(hours: 24);
  static Duration get _tokenRefreshThreshold => PerformanceConfig.tokenRefreshThreshold;
  static Duration get _activityTimeout => Duration(minutes: 30);

  // Timer for session management
  Timer? _sessionTimer;
  Timer? _activityTimer;
  DateTime? _lastActivity;

  // Stream controllers for session events
  final StreamController<bool> _sessionStatusController = StreamController<bool>.broadcast();
  final StreamController<String> _sessionErrorController = StreamController<String>.broadcast();

  // Getters for streams
  Stream<bool> get sessionStatusStream => _sessionStatusController.stream;
  Stream<String> get sessionErrorStream => _sessionErrorController.stream;

  // Initialize session manager
  Future<void> initialize() async {
    try {
      await _loadSessionData().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Session data loading timeout');
        },
      );
      await _startSessionMonitoring().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          throw Exception('Session monitoring start timeout');
        },
      );
      _startActivityMonitoring();
    } catch (e) {
      debugPrint('Error initializing session manager: $e');
      // Handle stream-related errors gracefully
      if (e.toString().toLowerCase().contains('stream') ||
          e.toString().toLowerCase().contains('addstream')) {
        _sessionErrorController.add('Session initialization failed. Please try logging in again.');
      } else {
        _sessionErrorController.add('Failed to initialize session: ${e.toString()}');
      }
    }
  }

  // Load session data from storage
  Future<void> _loadSessionData() async {
    try {
      final token = await _storage.read(key: _tokenKey).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Token read timeout');
        },
      );
      final lastActivityStr = await _storage.read(key: _lastActivityKey).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Last activity read timeout');
        },
      );
      
      if (lastActivityStr != null) {
        _lastActivity = DateTime.parse(lastActivityStr);
      }
      
      // Skip token validation during development for faster loading
      // if (token != null) {
      //   await _validateTokenAndUpdateStatus();
      // }
    } catch (e) {
      debugPrint('Error loading session data: $e');
      await _clearSession();
    }
  }

  // Start session monitoring
  Future<void> _startSessionMonitoring() async {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(PerformanceConfig.sessionCheckInterval, (timer) async {
      await _checkSessionStatus();
    });
  }

  // Start activity monitoring
  void _startActivityMonitoring() {
    _activityTimer?.cancel();
    _activityTimer = Timer.periodic(PerformanceConfig.activityCheckInterval, (timer) {
      _checkActivityTimeout();
    });
  }

  // Check session status
  Future<void> _checkSessionStatus() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) {
        await _clearSession();
        return;
      }

      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        await _attemptTokenRefresh();
        return;
      }

      // Check if token needs refresh
      final decodedToken = JwtDecoder.decode(token);
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final timeUntilExpiry = expirationTime.difference(DateTime.now());

      if (timeUntilExpiry < _tokenRefreshThreshold) {
        await _attemptTokenRefresh();
      }
    } catch (e) {
      debugPrint('Error checking session status: $e');
      // Handle stream-related errors gracefully
      if (e.toString().toLowerCase().contains('stream') ||
          e.toString().toLowerCase().contains('addstream')) {
        _sessionErrorController.add('Session validation failed. Please try logging in again.');
      } else {
        _sessionErrorController.add('Session validation error: ${e.toString()}');
      }
      await _clearSession();
    }
  }

  // Check activity timeout
  void _checkActivityTimeout() {
    if (_lastActivity != null) {
      final timeSinceLastActivity = DateTime.now().difference(_lastActivity!);
      if (timeSinceLastActivity > _activityTimeout) {
        _sessionErrorController.add('Session expired due to inactivity');
        _clearSession();
      }
    }
  }

  // Update last activity
  void updateActivity() {
    _lastActivity = DateTime.now();
    _storage.write(key: _lastActivityKey, value: _lastActivity!.toIso8601String());
  }

  // Validate token with backend
  Future<bool> _validateTokenAndUpdateStatus() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return false;

      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}${ApiConstants.validateToken}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        if (responseData['data']?['valid'] == true) {
          _sessionStatusController.add(true);
          return true;
        }
      }

      // Token is invalid
      await _clearSession();
      return false;
    } catch (e) {
      debugPrint('Error validating token: $e');
      return false;
    }
  }

  // Attempt to refresh token
  Future<bool> _attemptTokenRefresh() async {
    try {
      final refreshToken = await _storage.read(key: _refreshTokenKey);
      if (refreshToken == null) {
        await _clearSession();
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}${ApiConstants.refreshToken}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $refreshToken',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Token refresh request timeout');
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        
        // Handle different response formats
        Map<String, dynamic>? tokenData;
        if (responseData['data'] != null) {
          tokenData = responseData['data'];
        } else if (responseData['token'] != null) {
          tokenData = responseData;
        }
        
        if (tokenData != null && tokenData['token'] != null) {
          // Update tokens
          await _storage.write(key: _tokenKey, value: tokenData['token']);
          if (tokenData['refreshToken'] != null) {
            await _storage.write(key: _refreshTokenKey, value: tokenData['refreshToken']);
          }
          
          // Update user info if provided
          if (tokenData['user'] != null) {
            await _storage.write(key: _userInfoKey, value: json.encode(tokenData['user']));
          }

          // Update activity timestamp
          updateActivity();
          
          _sessionStatusController.add(true);
          return true;
        }
      } else if (response.statusCode == 401) {
        // Refresh token is invalid or expired
        debugPrint('Refresh token is invalid or expired');
        await _clearSession();
        return false;
      }

      // Refresh failed
      await _clearSession();
      return false;
    } catch (e) {
      debugPrint('Error refreshing token: $e');
      // Handle stream-related errors gracefully
      if (e.toString().toLowerCase().contains('stream') ||
          e.toString().toLowerCase().contains('addstream')) {
        _sessionErrorController.add('Token refresh failed. Please try logging in again.');
      }
      await _clearSession();
      return false;
    }
  }

  // Attempt to refresh token with retry
  Future<bool> attemptTokenRefreshWithRetry({int maxRetries = 2}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        debugPrint('Attempting token refresh (attempt $attempt/$maxRetries)');
        final success = await _attemptTokenRefresh();
        if (success) {
          debugPrint('Token refresh successful on attempt $attempt');
          return true;
        }
        
        if (attempt < maxRetries) {
          // Wait before retry (exponential backoff)
          final delay = Duration(seconds: attempt * 2);
          debugPrint('Token refresh failed, retrying in ${delay.inSeconds} seconds...');
          await Future.delayed(delay);
        }
      } catch (e) {
        debugPrint('Error during token refresh attempt $attempt: $e');
        if (attempt < maxRetries) {
          await Future.delayed(Duration(seconds: attempt));
        }
      }
    }
    
    debugPrint('Token refresh failed after $maxRetries attempts');
    return false;
  }

  // Public method to validate token
  Future<bool> validateToken() async {
    return await _validateTokenAndUpdateStatus();
  }

  // Public method to refresh token
  Future<bool> refreshToken() async {
    return await _attemptTokenRefresh();
  }

  // Check if session is valid
  Future<bool> isSessionValid() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return false;

      if (JwtDecoder.isExpired(token)) {
        return await _attemptTokenRefresh().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('Token refresh timeout');
            return false;
          },
        );
      }

      return true;
    } catch (e) {
      debugPrint('Error checking session validity: $e');
      // Handle stream-related errors gracefully
      if (e.toString().toLowerCase().contains('stream') ||
          e.toString().toLowerCase().contains('addstream')) {
        _sessionErrorController.add('Session validation failed. Please try logging in again.');
      }
      return false;
    }
  }

  // Get current token
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Get current refresh token
  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  // Check if there's a stored token
  Future<bool> hasStoredToken() async {
    final token = await _storage.read(key: _tokenKey);
    return token != null;
  }

  // Get user info
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final userInfoStr = await _storage.read(key: _userInfoKey);
      if (userInfoStr != null) {
        return json.decode(userInfoStr);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Clear session
  Future<void> _clearSession() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _userInfoKey);
    await _storage.delete(key: _lastActivityKey);
    
    _lastActivity = null;
    _sessionStatusController.add(false);
  }

  // Public method to clear session
  Future<void> clearSession() async {
    await _clearSession();
  }

  // Logout
  Future<void> logout() async {
    try {
      // Attempt to notify backend about logout (optional)
      final token = await getToken();
      if (token != null) {
        try {
          await http.post(
            Uri.parse('${ApiService.baseUrl}${ApiConstants.logout}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (e) {
          // Ignore logout notification errors
          debugPrint('Failed to notify backend about logout: $e');
        }
      }
    } finally {
      // Always clear local session data
      await _clearSession();
      _sessionTimer?.cancel();
      _activityTimer?.cancel();
    }
  }

  // Check if user is actively using the app
  bool get isUserActive {
    if (_lastActivity == null) return false;
    final timeSinceLastActivity = DateTime.now().difference(_lastActivity!);
    return timeSinceLastActivity < _activityTimeout;
  }

  // Get session statistics
  Map<String, dynamic> getSessionStats() {
    return {
      'isValid': isSessionValid(),
      'lastActivity': _lastActivity?.toIso8601String(),
      'isUserActive': isUserActive,
      'sessionTimeout': _defaultSessionTimeout.inMinutes,
      'activityTimeout': _activityTimeout.inMinutes,
    };
  }

  // Dispose resources
  void dispose() {
    _sessionTimer?.cancel();
    _activityTimer?.cancel();
    _sessionStatusController.close();
    _sessionErrorController.close();
  }

  // Get session timeout duration
  Duration get sessionTimeout => _defaultSessionTimeout;

  // Get time until session expires
  Future<Duration?> getTimeUntilExpiry() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return null;

      final decodedToken = JwtDecoder.decode(token);
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      return expirationTime.difference(DateTime.now());
    } catch (e) {
      return null;
    }
  }

  // Check if token needs refresh
  Future<bool> needsTokenRefresh() async {
    try {
      final token = await _storage.read(key: _tokenKey);
      if (token == null) return false;

      final decodedToken = JwtDecoder.decode(token);
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final timeUntilExpiry = expirationTime.difference(DateTime.now());

      return timeUntilExpiry < _tokenRefreshThreshold;
    } catch (e) {
      debugPrint('Error checking if token needs refresh: $e');
      return false;
    }
  }
}
