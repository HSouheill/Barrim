import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'user_email';
  static const String _roleKey = 'user_role';

  // Store token in secure storage
  Future<void> setToken(String token) async {
    await _setItem(_tokenKey, token);
  }

  // Get token from secure storage
  Future<String?> getToken() async {
    return await _getItem(_tokenKey);
  }

  // Store user email
  Future<void> setEmail(String email) async {
    await _setItem(_emailKey, email);
  }

  // Get user email
  Future<String?> getEmail() async {
    return await _getItem(_emailKey);
  }

  // Store user role
  Future<void> setRole(String role) async {
    await _setItem(_roleKey, role);
  }

  // Get user role
  Future<String?> getRole() async {
    return await _getItem(_roleKey);
  }

  // Clear all stored data (for logout)
  Future<void> clearAll() async {
    await _removeItem(_tokenKey);
    await _removeItem(_emailKey);
    await _removeItem(_roleKey);
  }

  Future<void> _setItem(String key, String value) async {
    if (kIsWeb) {
      html.window.localStorage[key] = value;
    } else {
      await _storage.write(key: key, value: value);
    }
  }
  Future<String?> _getItem(String key) async {
    if (kIsWeb) {
      return html.window.localStorage[key];
    } else {
      return await _storage.read(key: key);
    }
  }
  Future<void> _removeItem(String key) async {
    if (kIsWeb) {
      html.window.localStorage.remove(key);
    } else {
      await _storage.delete(key: key);
    }
  }
}