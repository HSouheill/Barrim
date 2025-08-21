import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _emailKey = 'user_email';
  static const String _roleKey = 'user_role';

  // Store token in secure storage
  Future<void> setToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  // Get token from secure storage
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  // Store user email
  Future<void> setEmail(String email) async {
    await _storage.write(key: _emailKey, value: email);
  }

  // Get user email
  Future<String?> getEmail() async {
    return await _storage.read(key: _emailKey);
  }

  // Store user role
  Future<void> setRole(String role) async {
    await _storage.write(key: _roleKey, value: role);
  }

  // Get user role
  Future<String?> getRole() async {
    return await _storage.read(key: _roleKey);
  }

  // Clear all stored data (for logout)
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }
}