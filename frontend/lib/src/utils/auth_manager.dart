// utils/auth_manager.dart
import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class AuthManager {
  static final _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';

  // HTTP headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // Get auth token from secure storage
  static Future<String?> _getToken() async {
    return await _getItem(_tokenKey);
  }

  // Add authorization header if token exists
  static Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _getToken();
    final headers = Map<String, String>.from(_headers);

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }

    return headers;
  }

  // Public method to get auth headers for API calls
  static Future<Map<String, String>> getAuthHeaders() async {
    return await _getAuthHeaders();
  }

  // Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await _getToken();
    if (token == null) {
      return false;
    }

    try {
      return !JwtDecoder.isExpired(token);
    } catch (e) {
      return false;
    }
  }

  // Save auth token to secure storage
  static Future<void> _saveToken(String token) async {
    await _setItem(_tokenKey, token);
  }

  // Clear auth token from secure storage
  static Future<void> clearToken() async {
    await _removeItem(_tokenKey);
  }

  // Logout function - clears token from storage
  static Future<void> logout() async {
    await clearToken();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await _getToken();
    return token != null;
  }

  // Get current user (admin) ObjectID from JWT token
  static Future<String?> getCurrentUserId() async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final decoded = JwtDecoder.decode(token);
      // Try common keys for user id
      if (decoded.containsKey('id')) return decoded['id'];
      if (decoded.containsKey('_id')) return decoded['_id'];
      if (decoded.containsKey('userId')) return decoded['userId'];
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get current user object from JWT token
  static Future<Map<String, dynamic>?> getCurrentUser() async {
    final token = await _getToken();
    if (token == null) return null;
    try {
      final decoded = JwtDecoder.decode(token);
      return decoded;
    } catch (e) {
      return null;
    }
  }

  static Future<bool> hasFinancialDashboardAccess() async {
    final user = await getCurrentUser();
    if (user == null) return false;
    final roles = user['roles_access'] as List<dynamic>? ?? [];
    return roles.contains('financial_dashboard');
  }

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