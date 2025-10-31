import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../services/api_constant.dart';
import '../services/api_services.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'performance_config.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const FlutterSecureStorage _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userInfoKey = 'user_info';
  static const String _lastActivityKey = 'last_activity';

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
        if (!_sessionErrorController.isClosed) {
          _sessionErrorController.add('Session initialization failed. Please try logging in again.');
        }
      } else {
        if (!_sessionErrorController.isClosed) {
          _sessionErrorController.add('Failed to initialize session: ${e.toString()}');
        }
      }
    }
  }

  // Load session data from storage
  Future<void> _loadSessionData() async {
    try {
      print('=== SESSION MANAGER LOADING DATA ===');
      final token = await _storage.read(key: _tokenKey).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Token read timeout');
        },
      );
      print('Session manager - Token found: ${token != null}');
      
      final lastActivityStr = await _storage.read(key: _lastActivityKey).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          throw Exception('Last activity read timeout');
        },
      );
      print('Session manager - Last activity found: ${lastActivityStr != null}');
      
      if (lastActivityStr != null) {
        _lastActivity = DateTime.parse(lastActivityStr);
      }
      
      // Skip token validation during development for faster loading
      // if (token != null) {
      //   await _validateTokenAndUpdateStatus();
      // }
    } catch (e) {
      debugPrint('Error loading session data: $e');
      // Do not clear session on initialization/read errors to avoid logging users out on reload
      // await _clearSession();
    }
  }

  // Start session monitoring
  Future<void> _startSessionMonitoring() async {
    _sessionTimer?.cancel();
    // Temporarily disable automatic session monitoring to debug auth issues
    // _sessionTimer = Timer.periodic(PerformanceConfig.sessionCheckInterval, (timer) async {
    //   await _checkSessionStatus();
    // });
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
      final token = await _getItem(_tokenKey);
      print('=== SESSION STATUS CHECK ===');
      print('Token found: ${token != null}');
      
      if (token == null) {
        print('No token found - clearing session');
        await _clearSession();
        return;
      }

      // Check if token is expired
      if (JwtDecoder.isExpired(token)) {
        print('Token is expired - attempting refresh');
        await _attemptTokenRefresh();
        return;
      }

      // Check if token needs refresh
      final decodedToken = JwtDecoder.decode(token);
      final expirationTime = DateTime.fromMillisecondsSinceEpoch(decodedToken['exp'] * 1000);
      final timeUntilExpiry = expirationTime.difference(DateTime.now());

      print('Time until expiry: ${timeUntilExpiry.inMinutes} minutes');
      print('Refresh threshold: ${_tokenRefreshThreshold.inMinutes} minutes');

      if (timeUntilExpiry < _tokenRefreshThreshold) {
        print('Token needs refresh - attempting refresh');
        await _attemptTokenRefresh();
      } else {
        print('Token is still valid');
      }
    } catch (e) {
      debugPrint('Error checking session status: $e');
      // Handle stream-related errors gracefully
      if (e.toString().toLowerCase().contains('stream') ||
          e.toString().toLowerCase().contains('addstream')) {
        if (!_sessionErrorController.isClosed) {
          _sessionErrorController.add('Session validation failed. Please try logging in again.');
        }
      } else {
        if (!_sessionErrorController.isClosed) {
          _sessionErrorController.add('Session validation error: ${e.toString()}');
        }
      }
      await _clearSession();
    }
  }

  // Check activity timeout
  void _checkActivityTimeout() {
    if (_lastActivity != null) {
      final timeSinceLastActivity = DateTime.now().difference(_lastActivity!);
      if (timeSinceLastActivity > _activityTimeout) {
        if (!_sessionErrorController.isClosed) {
          _sessionErrorController.add('Session expired due to inactivity');
        }
        _clearSession();
      }
    }
  }

  // Update last activity
  void updateActivity() {
    _lastActivity = DateTime.now();
    _setItem(_lastActivityKey, _lastActivity!.toIso8601String());
  }

  // Validate token with backend
  Future<bool> _validateTokenAndUpdateStatus() async {
    try {
      final token = await _getItem(_tokenKey);
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
          if (!_sessionStatusController.isClosed) {
            _sessionStatusController.add(true);
          }
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
      print('=== ATTEMPTING TOKEN REFRESH ===');
      final refreshToken = await _getItem(_refreshTokenKey);
      print('Refresh token found: ${refreshToken != null}');
      
      if (refreshToken == null) {
        print('No refresh token - clearing session');
        await _clearSession();
        return false;
      }

      final response = await http.post(
        Uri.parse('${ApiService.baseUrl}${ApiConstants.refreshToken}'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'refreshToken': refreshToken,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Token refresh request timeout');
        },
      );

      print('Refresh token response status: ${response.statusCode}');
      print('Refresh token response body: ${response.body}');

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
          await _setItem(_tokenKey, tokenData['token']);
          if (tokenData['refreshToken'] != null) {
            await _setItem(_refreshTokenKey, tokenData['refreshToken']);
          }
          
          // Update user info if provided
          if (tokenData['user'] != null) {
            await _setItem(_userInfoKey, json.encode(tokenData['user']));
          }

          // Update activity timestamp
          updateActivity();
          
          if (!_sessionStatusController.isClosed) {
            _sessionStatusController.add(true);
          }
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
        if (!_sessionErrorController.isClosed) {
          _sessionErrorController.add('Token refresh failed. Please try logging in again.');
        }
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

  // Enhanced retry method with better error handling
  Future<bool> retrySessionRefresh({int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        print('Session refresh attempt $attempt/$maxRetries');
        
        // Check if we have a refresh token
        final refreshToken = await _getItem(_refreshTokenKey);
        if (refreshToken == null) {
          print('No refresh token available for retry');
          return false;
        }
        
        // Attempt refresh
        final success = await _attemptTokenRefresh();
        
        if (success) {
          print('Session refresh successful on attempt $attempt');
          return true;
        }
        
        // If not the last attempt, wait before retrying
        if (attempt < maxRetries) {
          final delay = Duration(seconds: attempt * 2); // Exponential backoff
          print('Refresh failed, retrying in ${delay.inSeconds} seconds...');
          await Future.delayed(delay);
        }
      } catch (e) {
        print('Error during retry attempt $attempt: $e');
        if (attempt == maxRetries) {
          // Last attempt failed
          if (!_sessionErrorController.isClosed) {
            _sessionErrorController.add('Session refresh failed after $maxRetries attempts. Please login again.');
          }
          return false;
        }
      }
    }
    
    print('All retry attempts failed');
    return false;
  }

  // Check if session is valid
  Future<bool> isSessionValid() async {
    try {
      final token = await _getItem(_tokenKey);
      if (token == null) return false;

      if (JwtDecoder.isExpired(token)) {
        return await _attemptTokenRefresh().timeout(
          const Duration(seconds: 10), // Increased timeout for better reliability
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
        if (!_sessionErrorController.isClosed) {
          _sessionErrorController.add('Session validation failed. Please try logging in again.');
        }
      }
      return false;
    }
  }

  // Enhanced session validation with better error handling
  Future<Map<String, dynamic>> validateSessionWithDetails() async {
    try {
      final token = await _getItem(_tokenKey);
      if (token == null) {
        return {
          'isValid': false,
          'reason': 'No token found',
          'canRetry': false,
        };
      }

      if (JwtDecoder.isExpired(token)) {
        final refreshSuccess = await _attemptTokenRefresh().timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            debugPrint('Token refresh timeout');
            return false;
          },
        );
        
        return {
          'isValid': refreshSuccess,
          'reason': refreshSuccess ? 'Token refreshed' : 'Token refresh failed',
          'canRetry': !refreshSuccess,
        };
      }

      return {
        'isValid': true,
        'reason': 'Token is valid',
        'canRetry': false,
      };
    } catch (e) {
      debugPrint('Error validating session: $e');
      return {
        'isValid': false,
        'reason': 'Validation error: ${e.toString()}',
        'canRetry': true,
      };
    }
  }

  // Get current token
  Future<String?> getToken() async {
    return await _getItem(_tokenKey);
  }

  // Get current refresh token
  Future<String?> getRefreshToken() async {
    return await _getItem(_refreshTokenKey);
  }

  // Check if there's a stored token
  Future<bool> hasStoredToken() async {
    final token = await _getItem(_tokenKey);
    return token != null;
  }

  // Get user info
  Future<Map<String, dynamic>?> getUserInfo() async {
    try {
      final userInfoStr = await _getItem(_userInfoKey);
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
    await _removeItem(_tokenKey);
    await _removeItem(_refreshTokenKey);
    await _removeItem(_userInfoKey);
    await _removeItem(_lastActivityKey);
    
    _lastActivity = null;
    if (!_sessionStatusController.isClosed) {
      _sessionStatusController.add(false);
    }
    
    print('Session cleared successfully');
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
    // Don't close stream controllers for singleton - they might be used elsewhere
    // _sessionStatusController.close();
    // _sessionErrorController.close();
  }

  // Get session timeout duration
  Duration get sessionTimeout => _defaultSessionTimeout;

  // Get time until session expires
  Future<Duration?> getTimeUntilExpiry() async {
    try {
      final token = await _getItem(_tokenKey);
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
      final token = await _getItem(_tokenKey);
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

  // Utility for cross-platform storage:
  static Future<void> _setItem(String key, String value) async {
    if (kIsWeb) {
      html.window.localStorage[key] = value;
    } else {
      await _storage.write(key: key, value: value);
    }
  }
  static Future<String?> _getItem(String key) async {
    if (kIsWeb) {
      return html.window.localStorage[key];
    } else {
      return await _storage.read(key: key);
    }
  }
  static Future<void> _removeItem(String key) async {
    if (kIsWeb) {
      html.window.localStorage.remove(key);
    } else {
      await _storage.delete(key: key);
    }
  }
}
