import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:path/path.dart' as path;
import '../models/user_model.dart';
import '../utils/session_manager.dart';
import '../utils/performance_config.dart';
import 'api_constant.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
// Add this import for web storage
// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

class ApiResponse {
  final bool success;
  final String message;
  final dynamic data;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
  });
}

class LoginResult {
  final String token;
  final String refreshToken;
  final UserInfo user;

  LoginResult({
    required this.token,
    required this.refreshToken,
    required this.user,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    return LoginResult(
      token: json['token'],
      refreshToken: json['refreshToken'],
      user: UserInfo.fromJson(json['user']),
    );
  }
}

class UserInfo {
  final String email;
  final String role;
  final String type;
  final String? id;
  final String? fullName;
  final String? phoneNumber;
  final String? territory;
  final String? region;
  final String? salesManagerId;
  final String? status;

  UserInfo({
    required this.email,
    required this.role,
    required this.type,
    this.id,
    this.fullName,
    this.phoneNumber,
    this.territory,
    this.region,
    this.salesManagerId,
    this.status,
  });

  factory UserInfo.fromJson(Map<String, dynamic> json) {
    return UserInfo(
      email: json['email'],
      role: json['role'],
      type: json['type'],
      id: json['id']?.toString(),
      fullName: json['fullName'],
      phoneNumber: json['phoneNumber'],
      territory: json['territory'],
      region: json['region'],
      salesManagerId: json['salesManagerId']?.toString(),
      status: json['status'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'email': email,
      'role': role,
      'type': type,
      'id': id,
      'fullName': fullName,
      'phoneNumber': phoneNumber,
      'territory': territory,
      'region': region,
      'salesManagerId': salesManagerId,
      'status': status,
    };
  }
}

class ApiService {
  // Base URL for API - update this with your actual backend URL
  static const String baseUrl = 'https://barrim.online';
  static const _storage = FlutterSecureStorage();
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userInfoKey = 'user_info';
  
  // Temporary in-memory storage for debugging
  static String? _tempToken;
  static String? _tempRefreshToken;
  static String? _tempUserInfo;

  // Session manager instance
  static final SessionManager _sessionManager = SessionManager();

  // HTTP headers
  static Map<String, String> get _headers => {
    'Content-Type': 'application/json',
  };

  // Utility methods:
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

  // Get auth token from secure storage
  static Future<String?> getToken() async {
    // Try temporary storage first
    if (_tempToken != null) {
      print('=== GETTING TOKEN (TEMP) ===');
      print('Token found in temp storage: true');
      print('Token length: ${_tempToken!.length}');
      print('Token preview: ${_tempToken!.substring(0, 20)}...');
      return _tempToken;
    }
    
    final token = await _getItem(_tokenKey);
    print('=== GETTING TOKEN (STORAGE) ===');
    print('Token key: $_tokenKey');
    print('Token found: ${token != null}');
    if (token != null) {
      print('Token length: ${token.length}');
      print('Token preview: ${token.substring(0, 20)}...');
    }
    return token;
  }

  // Get refresh token from secure storage
  static Future<String?> _getRefreshToken() async {
    return await _getItem(_refreshTokenKey);
  }

  // Get user info from secure storage
  static Future<UserInfo?> getUserInfo() async {
    try {
      print('=== GETTING USER INFO ===');
      final userInfoJson = await _getItem(_userInfoKey);
      print('Raw user info from storage: $userInfoJson');
      
      if (userInfoJson != null) {
        final userInfoMap = json.decode(userInfoJson);
        print('Decoded user info map: $userInfoMap');
        
        final userInfo = UserInfo.fromJson(userInfoMap);
        
        // Debug logging
        print('=== USER INFO RETRIEVED ===');
        print('User Type: ${userInfo.type}');
        print('User Role: ${userInfo.role}');
        print('User Email: ${userInfo.email}');
        
        return userInfo;
      }
      print('No user info found in storage');
      return null;
    } catch (e) {
      print('Error retrieving user info: $e');
      return null;
    }
  }

  // Save auth data to secure storage
  static Future<void> _saveAuthData(LoginResult loginResult) async {
    try {
      print('=== SAVING AUTH DATA ===');
      print('Token key: $_tokenKey');
      print('Refresh token key: $_refreshTokenKey');
      print('User info key: $_userInfoKey');
      
      // Store tokens in both temporary and secure storage
      _tempToken = loginResult.token;
      _tempRefreshToken = loginResult.refreshToken;
      
      await _setItem(_tokenKey, loginResult.token);
      await _setItem(_refreshTokenKey, loginResult.refreshToken);
      
      // Store user info
      final userInfo = loginResult.user.toJson();
      _tempUserInfo = json.encode(userInfo);
      await _setItem(_userInfoKey, json.encode(userInfo));
      
      print('Tokens saved successfully (both temp and storage)');
      
      // Verify tokens were saved
      final savedToken = await _getItem(_tokenKey);
      final savedRefreshToken = await _getItem(_refreshTokenKey);
      print('Verification - Token saved: ${savedToken != null}');
      print('Verification - Refresh token saved: ${savedRefreshToken != null}');
      
      // Initialize session manager
      await _sessionManager.initialize();
      
      // Debug logging
      print('=== AUTH DATA SAVED ===');
      print('Token: ${loginResult.token.substring(0, 20)}...');
      print('User Type: ${loginResult.user.type}');
      print('User Role: ${loginResult.user.role}');
      print('User Email: ${loginResult.user.email}');
      
      // Verify data was saved
      final savedUserInfo = await getUserInfo();
      if (savedUserInfo == null) {
        print('WARNING: User info was not saved properly');
      } else {
        print('=== VERIFIED SAVED USER INFO ===');
        print('User Type: ${savedUserInfo.type}');
        print('User Role: ${savedUserInfo.role}');
        print('User Email: ${savedUserInfo.email}');
      }
    } catch (e) {
      print('Error saving auth data: $e');
      rethrow;
    }
  }

  // Clear all auth data from secure storage
  static Future<void> clearAuthData() async {
    // Clear temporary storage
    _tempToken = null;
    _tempRefreshToken = null;
    _tempUserInfo = null;
    
    await _removeItem(_tokenKey);
    await _removeItem(_refreshTokenKey);
    await _removeItem(_userInfoKey);
    await _sessionManager.clearSession();
  }

  // Legacy method - kept for backward compatibility
  static Future<void> clearToken() async {
    await clearAuthData();
  }

  // Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    if (token == null) return false;
    
    // Also check if session is valid
    return await _sessionManager.isSessionValid();
  }

  // Get current user type
  static Future<String?> getCurrentUserType() async {
    try {
      final userInfo = await getUserInfo();
      if (userInfo != null) {
        print('Current user type: ${userInfo.type}');
        return userInfo.type;
      }
      return null;
    } catch (e) {
      print('Error getting current user type: $e');
      return null;
    }
  }

  // Logout function - clears all auth data from storage
  static Future<void> logout() async {
    try {
      final token = await getToken();
      if (token != null) {
        // Notify backend about logout
        try {
          await http.post(
            Uri.parse('${baseUrl}${ApiConstants.logout}'),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer $token',
            },
          );
        } catch (e) {
          // Ignore backend logout errors
          debugPrint('Failed to notify backend about logout: $e');
        }
      }
    } catch (e) {
      debugPrint('Error during logout: $e');
    } finally {
      // Always clear local auth data
      await clearAuthData();
      await _sessionManager.logout();
    }
  }

  // Add authorization header if token exists
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getToken();
    final headers = Map<String, String>.from(_headers);

    print('=== GETTING AUTH HEADERS ===');
    print('Token retrieved: ${token != null ? '${token.substring(0, 20)}...' : 'null'}');

    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
      print('Authorization header added: Bearer ${token.substring(0, 20)}...');
    } else {
      print('No token found - no Authorization header added');
    }

    print('Final headers: $headers');
    return headers;
  }

  // Handle API response
  static ApiResponse _handleResponse(http.Response response) {
    final int statusCode = response.statusCode;
    final responseBody = json.decode(response.body);

    if (statusCode >= 200 && statusCode < 300) {
      return ApiResponse(
        success: true,
        message: responseBody['message'] ?? 'Success',
        data: responseBody['data'],
      );
    } else {
      return ApiResponse(
        success: false,
        message: responseBody['message'] ?? 'An error occurred',
        data: responseBody['data'],
      );
    }
  }

  // Make HTTP request with automatic token refresh
  static Future<http.Response> _makeRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    try {
      // Skip token refresh for login endpoints to prevent infinite loops
      final isLoginRequest = url.contains('/login') || url.contains('/admin/login');
      
      // Check if token needs refresh before making request (skip for login requests)
      // Temporarily disabled to debug auth issues
      // if (!isLoginRequest && await _sessionManager.needsTokenRefresh()) {
      //   await _sessionManager.refreshToken();
      // }

      // For login requests, use the provided headers directly
      // For other requests, use getAuthHeaders if no headers provided
      final requestHeaders = isLoginRequest ? (headers ?? _headers) : (headers ?? await getAuthHeaders());
      final uri = Uri.parse(url);

      print('=== MAKING REQUEST ===');
      print('URL: $url');
      print('Method: $method');
      print('Is login request: $isLoginRequest');
      print('Headers provided: ${headers != null}');
      print('Final request headers: $requestHeaders');

      http.Response response;
      switch (method.toLowerCase()) {
        case 'get':
          response = await http.get(uri, headers: requestHeaders);
          break;
        case 'post':
          response = await http.post(uri, headers: requestHeaders, body: body);
          break;
        case 'put':
          response = await http.put(uri, headers: requestHeaders, body: body);
          break;
        case 'delete':
          response = await http.delete(uri, headers: requestHeaders);
          break;
        default:
          throw UnsupportedError('HTTP method not supported: $method');
      }

      // If response is 401, try to refresh token and retry once (skip for login requests)
      if (response.statusCode == 401 && !isLoginRequest) {
        final refreshSuccess = await _sessionManager.refreshToken();
        if (refreshSuccess) {
          // Retry with new token
          final newHeaders = headers ?? await getAuthHeaders();
          switch (method.toLowerCase()) {
            case 'get':
              response = await http.get(uri, headers: newHeaders);
              break;
            case 'post':
              response = await http.post(uri, headers: newHeaders, body: body);
              break;
            case 'put':
              response = await http.put(uri, headers: newHeaders, body: body);
              break;
            case 'delete':
              response = await http.delete(uri, headers: newHeaders);
              break;
          }
        }
      }

      return response;
    } catch (e) {
      // Handle specific error types that might cause addStream errors
      if (e.toString().toLowerCase().contains('stream') ||
          e.toString().toLowerCase().contains('addstream')) {
        throw Exception('Network error: Please check your internet connection and try again');
      } else if (e.toString().toLowerCase().contains('timeout')) {
        throw Exception('Request timeout: Please try again');
      } else if (e.toString().toLowerCase().contains('network') ||
                 e.toString().toLowerCase().contains('connection') ||
                 e.toString().toLowerCase().contains('socket')) {
        throw Exception('Network error: Please check your internet connection');
      }
      rethrow;
    }
  }

  // Unified Login function - handles admin, sales manager, manager, and salesperson login
  static Future<ApiResponse> unifiedLogin(String email, String password) async {
    try {
      print('=== ATTEMPTING OPTIMIZED LOGIN ===');
      print('Email: $email');
      
      // Make all login attempts in parallel for better performance
      final loginData = {
        'email': email,
        'password': password,
      };
      
      // Add timeout to individual requests to prevent hanging
      final requestTimeout = Duration(seconds: 10);
      
      final adminFuture = _makeRequest(
        'post',
        '${baseUrl}${ApiConstants.adminLogin}',
        headers: _headers,
        body: json.encode(loginData),
      ).timeout(requestTimeout, onTimeout: () => throw Exception('Admin login request timeout'));
      
      final salesManagerFuture = _makeRequest(
        'post',
        '${baseUrl}${ApiConstants.salesManagerLogin}',
        headers: _headers,
        body: json.encode(loginData),
      ).timeout(requestTimeout, onTimeout: () => throw Exception('Sales Manager login request timeout'));
      
      final managerFuture = _makeRequest(
        'post',
        '${baseUrl}${ApiConstants.managerLogin}',
        headers: _headers,
        body: json.encode(loginData),
      ).timeout(requestTimeout, onTimeout: () => throw Exception('Manager login request timeout'));
      
      final salespersonFuture = _makeRequest(
        'post',
        '${baseUrl}${ApiConstants.salespersonLogin}',
        headers: _headers,
        body: json.encode(loginData),
      ).timeout(requestTimeout, onTimeout: () => throw Exception('Salesperson login request timeout'));
      
      // Wait for all responses with timeout
      final responses = await Future.wait([
        adminFuture,
        salesManagerFuture,
        managerFuture,
        salespersonFuture,
      ]).timeout(
        PerformanceConfig.loginTimeout,
        onTimeout: () => throw Exception('Login timeout - please try again'),
      );
      
      print('All login responses received. Processing results...');
      
      // Check responses in priority order: admin > sales_manager > manager > salesperson
      final adminResponse = responses[0];
      final salesManagerResponse = responses[1];
      final managerResponse = responses[2];
      final salespersonResponse = responses[3];
      
      print('Admin response status: ${adminResponse.statusCode}');
      print('Sales Manager response status: ${salesManagerResponse.statusCode}');
      print('Manager response status: ${managerResponse.statusCode}');
      print('Salesperson response status: ${salespersonResponse.statusCode}');
      
      // Try admin first
      if (adminResponse.statusCode == 200) {
        print('Admin login successful');
        return await _handleSuccessfulLogin(adminResponse, 'admin');
      }
      
      // Try sales manager
      if (salesManagerResponse.statusCode == 200) {
        print('Sales Manager login successful');
        return await _handleSuccessfulLogin(salesManagerResponse, 'sales_manager');
      }
      
      // Try manager
      if (managerResponse.statusCode == 200) {
        print('Manager login successful');
        return await _handleSuccessfulLogin(managerResponse, 'manager');
      }
      
      // Try salesperson
      if (salespersonResponse.statusCode == 200) {
        print('Salesperson login successful');
        return await _handleSuccessfulLogin(salespersonResponse, 'salesperson');
      }
      
      print('All login attempts failed. Processing error responses...');
      
      // If all failed, return the first error response
      final errorResponse = adminResponse.statusCode != 200 ? adminResponse :
                           salesManagerResponse.statusCode != 200 ? salesManagerResponse :
                           managerResponse.statusCode != 200 ? managerResponse :
                           salespersonResponse;
      
      print('Selected error response with status: ${errorResponse.statusCode}');
      
      // Handle specific error cases for login failures
      if (errorResponse.statusCode == 401) {
        print('Returning 401 error response');
        return ApiResponse(
          success: false,
          message: 'Incorrect email or password. Please try again.',
        );
      } else if (errorResponse.statusCode == 400) {
        print('Returning 400 error response');
        return ApiResponse(
          success: false,
          message: 'Invalid login data. Please check your email and password.',
        );
      } else if (errorResponse.statusCode == 404) {
        print('Returning 404 error response');
        return ApiResponse(
          success: false,
          message: 'Login service not found. Please contact support.',
        );
      } else if (errorResponse.statusCode >= 500) {
        print('Returning 500+ error response');
        return ApiResponse(
          success: false,
          message: 'Server error. Please try again later.',
        );
      }
      
      print('Processing generic error response');
      return _handleResponse(errorResponse);
      
    } catch (e) {
      print('Error during optimized login: $e');
      
      // Handle specific error types with user-friendly messages
      String errorMessage = 'An error occurred during login.';
      
      if (e.toString().toLowerCase().contains('timeout')) {
        errorMessage = 'Login timeout. Please check your internet connection and try again.';
      } else if (e.toString().toLowerCase().contains('network') || 
                 e.toString().toLowerCase().contains('connection') ||
                 e.toString().toLowerCase().contains('socket')) {
        errorMessage = 'Network error. Please check your internet connection and try again.';
      } else if (e.toString().toLowerCase().contains('stream') ||
                 e.toString().toLowerCase().contains('addstream')) {
        errorMessage = 'Incorrect email or password. Please try again.';
      } else if (e.toString().toLowerCase().contains('unauthorized') ||
                 e.toString().toLowerCase().contains('401')) {
        errorMessage = 'Incorrect email or password. Please try again.';
      }
      
      return ApiResponse(
        success: false,
        message: errorMessage,
      );
    }
  }
  
  // Helper method to handle successful login responses
  static Future<ApiResponse> _handleSuccessfulLogin(http.Response response, String userType) async {
    try {
      final result = _handleResponse(response);
      if (result.success && result.data != null) {
        final loginResult = LoginResult.fromJson(result.data);
        print('${userType.toUpperCase()} login successful');
        print('User type: ${loginResult.user.type}');
        print('User role: ${loginResult.user.role}');
        
        await _saveAuthData(loginResult);
        print('Auth data saved to secure storage');
        
        return ApiResponse(
          success: true,
          message: result.message,
          data: {
            'token': loginResult.token,
            'refreshToken': loginResult.refreshToken,
            'user': loginResult.user.toJson(),
            'userType': userType,
            'role': loginResult.user.role,
          },
        );
      }
      return result;
    } catch (e) {
      print('Error handling ${userType} login response: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to parse ${userType} login response',
      );
    }
  }

  // Legacy login function - now uses unified login
  static Future<ApiResponse> login(String email, String password) async {
    return await unifiedLogin(email, password);
  }

  // Admin-specific login (optional - same as unified but with explicit naming)
  static Future<ApiResponse> adminLogin(String email, String password) async {
    return await unifiedLogin(email, password);
  }

  // Sales Manager login (optional - same as unified but with explicit naming)
  static Future<ApiResponse> salesManagerLogin(String email, String password) async {
    return await unifiedLogin(email, password);
  }

  // Salesperson login (optional - same as unified but with explicit naming)
  static Future<ApiResponse> salespersonLogin(String email, String password) async {
    return await unifiedLogin(email, password);
  }

  // Forgot password function - works for admin only based on your backend
  static Future<ApiResponse> forgotPassword() async {
    try {
      final response = await _makeRequest(
        'post',
        '${baseUrl}${ApiConstants.forgotPassword}',
        headers: _headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Verify OTP and reset password
  static Future<ApiResponse> verifyOTPAndResetPassword(String otp, String newPassword) async {
    try {
      final response = await _makeRequest(
        'post',
        '${baseUrl}${ApiConstants.verifyOtpReset}',
        headers: _headers,
        body: json.encode({
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Get all users (admin only)
  static Future<ApiResponse> getAllUsers() async {
    try {
      final headers = await getAuthHeaders();
      final response = await _makeRequest(
        'get',
        '${baseUrl}${ApiConstants.allUsers}',
        headers: headers,
      );

      final result = _handleResponse(response);

      if (result.success && result.data != null) {
        final List<User> users = [];

        // Parse the users array from the response
        if (result.data is Map && result.data['users'] is List) {
          try {
            for (var userJson in result.data['users']) {
              if (userJson is Map<String, dynamic>) {
                users.add(User.fromJson(userJson));
              }
            }
          } catch (e) {
            print('Error parsing users: $e');
            return ApiResponse(
              success: false,
              message: 'Failed to parse user data: ${e.toString()}',
            );
          }
        }

        return ApiResponse(
          success: true,
          message: result.message,
          data: {
            'count': result.data['count'] ?? users.length,
            'users': users,
          },
        );
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to load users: ${e.toString()}',
      );
    }
  }

  // Get active users (admin only)
  static Future<ApiResponse> getActiveUsers() async {
    try {
      final headers = await getAuthHeaders();
      final response = await _makeRequest(
        'get',
        '${baseUrl}${ApiConstants.getActiveUsers}',
        headers: headers,
      );

      final result = _handleResponse(response);

      if (result.success && result.data != null) {
        final List<ActiveUser> activeUsers = [];

        // Parse the users array from the response
        if (result.data is Map && result.data['users'] is List) {
          for (var userJson in result.data['users']) {
            if (userJson is Map<String, dynamic>) {
              activeUsers.add(ActiveUser.fromJson(userJson));
            }
          }
        }

        return ApiResponse(
          success: true,
          message: result.message,
          data: {
            'count': result.data['count'] ?? activeUsers.length,
            'users': activeUsers,
          },
        );
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to load active users: ${e.toString()}',
      );
    }
  }

  // Get user status by ID
  static Future<ApiResponse> getUserStatus(String userId) async {
    try {
      final headers = await getAuthHeaders();
      final response = await _makeRequest(
        'get',
        '${baseUrl}${ApiConstants.getUserStatus}$userId',
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Sales Manager specific methods

  // Create sales manager (admin only)
  static Future<ApiResponse> createSalesManager({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required String status,
    String? createdBy,
    List<String>? rolesAccess,
    double? commissionPercent,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final Map<String, dynamic> body = {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': phoneNumber,
        'status': status,
        'createdBy': createdBy,
      };
      if (rolesAccess != null) {
        body['rolesAccess'] = rolesAccess;
      }
      if (commissionPercent != null) {
        body['commissionPercent'] = commissionPercent;
      }
      final response = await _makeRequest(
        'post',
        '${baseUrl}${ApiConstants.createSalesManager}',
        headers: headers,
        body: json.encode(body),
      );
      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Get all sales managers (admin only)
  static Future<ApiResponse> getAllSalesManagers() async {
    try {
      final headers = await getAuthHeaders();
      final response = await _makeRequest(
        'get',
        '${baseUrl}${ApiConstants.getAllSalesManagers}',
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Get sales manager by ID
  static Future<ApiResponse> getSalesManager(String salesManagerId) async {
    try {
      final headers = await getAuthHeaders();
      final response = await _makeRequest(
        'get',
        '${baseUrl}${ApiConstants.getSalesManager}$salesManagerId',
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Update sales manager
  static Future<ApiResponse> updateSalesManager({
    required String id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? image,
    String? territory,
    String? status,
    double? commissionPercent,
    List<String>? rolesAccess,
  }) async {
    final url = Uri.parse('$baseUrl${ApiConstants.updateSalesManager}$id');
    final Map<String, dynamic> body = {};
    if (fullName != null) body['fullName'] = fullName;
    if (email != null) body['email'] = email;
    if (phoneNumber != null) body['phoneNumber'] = phoneNumber;
    if (image != null) body['image'] = image;
    if (territory != null) body['territory'] = territory;
    if (status != null) body['status'] = status;
    if (commissionPercent != null) body['commissionPercent'] = commissionPercent;
    if (rolesAccess != null) body['rolesAccess'] = rolesAccess;
    try {
      final token = await getToken();
      final response = await _makeRequest(
        'put',
        '${baseUrl}${ApiConstants.updateSalesManager}$id',
        headers: {
          ..._headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return ApiResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? '',
        data: data['data'],
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // Delete sales manager
  static Future<ApiResponse> deleteSalesManager(String salesManagerId) async {
    try {
      final headers = await getAuthHeaders();
      final response = await _makeRequest(
        'delete',
        '${baseUrl}${ApiConstants.deleteSalesManager}$salesManagerId',
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Refresh token method (if you implement it in the backend)
  static Future<ApiResponse> refreshToken() async {
    try {
      final refreshToken = await _getRefreshToken();
      if (refreshToken == null) {
        return ApiResponse(
          success: false,
          message: 'No refresh token available',
        );
      }

      final response = await http.post(
        Uri.parse('${baseUrl}${ApiConstants.refreshToken}'),
        headers: _headers,
        body: json.encode({
          'refreshToken': refreshToken,
        }),
      );

      final result = _handleResponse(response);

      if (result.success && result.data != null) {
        // Update stored tokens
        await _setItem(_tokenKey, result.data['token']);
        if (result.data['refreshToken'] != null) {
          await _setItem(_refreshTokenKey, result.data['refreshToken']);
        }
        
        // Update user info if provided
        if (result.data['user'] != null) {
          await _setItem(_userInfoKey, json.encode(result.data['user']));
        }

        // Notify session manager about successful refresh
        final sessionManager = SessionManager();
        sessionManager.updateActivity();
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Create Manager (Admin creates Manager user)
  static Future<ApiResponse> createManager({
    required String fullName,
    required String email,
    required String password,
    // required List<String> rolesAccess,
  }) async {
    final url = Uri.parse('$baseUrl${ApiConstants.createManager}');
    final body = jsonEncode({
      'fullName': fullName,
      'email': email,
      'password': password,
      // 'rolesAccess': rolesAccess,
    });
    try {
      final token = await getToken();
      final response = await _makeRequest(
        'post',
        '${baseUrl}${ApiConstants.createManager}',
        headers: {
          ..._headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: body,
      );
      final data = jsonDecode(response.body);
      return ApiResponse(
        success: response.statusCode == 201,
        message: data['message'] ?? '',
        data: data['data'],
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  static Future<ApiResponse> getManagers() async {
    final url = Uri.parse('$baseUrl${ApiConstants.getManagers}');
    try {
      final token = await getToken();
      final response = await _makeRequest(
        'get',
        '${baseUrl}${ApiConstants.getManagers}',
        headers: {
          ..._headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      return ApiResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? '',
        data: data['data'],
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  static Future<ApiResponse> updateManager({
    required String id,
    required String fullName,
    required String email,
    // required List<String> rolesAccess,
    String? password,
  }) async {
    final url = Uri.parse('$baseUrl${ApiConstants.updateManager}$id');
    final body = {
      'fullName': fullName,
      'email': email,
      // 'rolesAccess': rolesAccess,
    };
    if (password != null && password.isNotEmpty) {
      body['password'] = password;
    }
    try {
      final token = await getToken();
      final response = await _makeRequest(
        'put',
        '${baseUrl}${ApiConstants.updateManager}$id',
        headers: {
          ..._headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      final data = jsonDecode(response.body);
      return ApiResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? '',
        data: data['data'],
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  static Future<ApiResponse> deleteManager(String id) async {
    final url = Uri.parse('$baseUrl${ApiConstants.deleteManager}$id');
    try {
      final token = await getToken();
      final response = await _makeRequest(
        'delete',
        '${baseUrl}${ApiConstants.deleteManager}$id',
        headers: {
          ..._headers,
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      return ApiResponse(
        success: response.statusCode == 200,
        message: data['message'] ?? '',
        data: data['data'],
      );
    } catch (e) {
      return ApiResponse(success: false, message: e.toString());
    }
  }

  // --- Manager Approvals: Pending, Approve, Deny ---

  static Future<List> getPendingCompanies() async {
    final headers = await getAuthHeaders();
    final response = await _makeRequest(
      'get',
      '${baseUrl}${ApiConstants.getPendingCompanies}',
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    }
    return [];
  }

  static Future<List> getPendingServiceProviders() async {
    final headers = await getAuthHeaders();
    final response = await _makeRequest(
      'get',
      '${baseUrl}${ApiConstants.getPendingServiceProviders}',
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    }
    return [];
  }

  static Future<List> getPendingWholesalers() async {
    final headers = await getAuthHeaders();
    final response = await _makeRequest(
      'get',
      '${baseUrl}${ApiConstants.getPendingWholesalers}',
      headers: headers,
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['data'] ?? [];
    }
    return [];
  }

  static Future<bool> approveCompany(String id) async {
    final headers = await getAuthHeaders();
    final response = await _makeRequest(
      'post',
      '${baseUrl}${ApiConstants.approveCompany}$id',
      headers: headers,
    );
    return response.statusCode == 200;
  }

  static Future<bool> approveServiceProvider(String id) async {
    final headers = await getAuthHeaders();
    final response = await _makeRequest(
      'post',
      '${baseUrl}${ApiConstants.approveServiceProvider}$id',
      headers: headers,
    );
    return response.statusCode == 200;
  }

  static Future<bool> approveWholesaler(String id) async {
    final headers = await getAuthHeaders();
    final response = await _makeRequest(
      'post',
      '${baseUrl}${ApiConstants.approveWholesaler}$id',
      headers: headers,
    );
    return response.statusCode == 200;
  }

  static Future<bool> denyCompany(String id) async {
    final headers = await getAuthHeaders();
    final response = await _makeRequest(
      'post',
      '${baseUrl}${ApiConstants.denyCompany}$id',
      headers: headers,
    );
    return response.statusCode == 200;
  }

  static Future<bool> denyServiceProvider(String id) async {
    final headers = await getAuthHeaders();
    final response = await _makeRequest(
      'post',
      '${baseUrl}${ApiConstants.denyServiceProvider}$id',
      headers: headers,
    );
    return response.statusCode == 200;
  }

  static Future<bool> denyWholesaler(String id) async {
    final headers = await getAuthHeaders();
    final response = await _makeRequest(
      'post',
      '${baseUrl}${ApiConstants.denyWholesaler}$id',
      headers: headers,
    );
    return response.statusCode == 200;
  }

  // Check if manager has financial_dashboard access role
  static Future<bool> hasFinancialDashboardAccess() async {
    try {
      final userInfo = await getUserInfo();
      if (userInfo == null) {
        print('No user info found');
        return false;
      }
      
      print('Checking financial dashboard access for user: ${userInfo.email}');
      print('User type: ${userInfo.type}');
      print('User role: ${userInfo.role}');
      
      // Check if the user is a manager
      if (userInfo.type == 'manager') {
        // Check if the role contains 'financial_dashboard'
        // This handles both string and array formats
        if (userInfo.role is String) {
          return userInfo.role.contains('financial_dashboard') || 
                 userInfo.role == 'financial_dashboard';
        } else if (userInfo.role is List) {
          return userInfo.role.contains('financial_dashboard');
        }
      }
      
      return false;
    } catch (e) {
      print('Error checking financial dashboard access: $e');
      return false;
    }
  }

  // Get all salespersons (admin only)
  static Future<ApiResponse> getAllSalespersons() async {
    try {
      final headers = await getAuthHeaders();
      final response = await _makeRequest(
        'get',
        '${baseUrl}${ApiConstants.getAllSalespersons}',
        headers: headers,
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to load salespersons: ${e.toString()}',
      );
    }
  }

  // Fetch all entities (users, companies, wholesalers, service providers) for admin
  static Future<ApiResponse> getAllEntities() async {
    try {
      final headers = await getAuthHeaders();
      final response = await _makeRequest(
        'get',
        '${baseUrl}${ApiConstants.getAllEntities}',
        headers: headers,
      );

      final result = _handleResponse(response);

      if (result.success && result.data != null) {
        return ApiResponse(
          success: true,
          message: result.message,
          data: result.data,
        );
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to load entities: ${e.toString()}',
      );
    }
  }

  // Get admin wallet information
  static Future<ApiResponse> getAdminWallet() async {
    try {
      final headers = await getAuthHeaders();
      final response = await _makeRequest(
        'get',
        '${baseUrl}${ApiConstants.getAdminWallet}',
        headers: headers,
      );

      final result = _handleResponse(response);

      if (result.success && result.data != null) {
        return ApiResponse(
          success: true,
          message: result.message,
          data: result.data,
        );
      }

      return result;
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Failed to load admin wallet: ${e.toString()}',
      );
    }
  }

  static String get secureBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl;
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'https://');
    }
    return 'https://$baseUrl';
  }

  // New method to validate email or phone existence
  static Future<bool> checkEmailOrPhoneExists(String? email, String? phone) async {
    try {
      final response = await _makeRequest(
        'post',
        '${baseUrl}${ApiConstants.checkEmailOrPhoneExists}',
        headers: _headers,
        body: json.encode({
          'email': email ?? '',
          'phone': phone ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final responseData = data['data'] as Map<String, dynamic>?;
        
        if (responseData != null) {
          // Check if any of the collections contain the email/phone
          final userExists = responseData['userExists'] ?? false;
          final companyExists = responseData['companyExists'] ?? false;
          final wholesalerExists = responseData['wholesalerExists'] ?? false;
          final serviceProviderExists = responseData['serviceProviderExists'] ?? false;
          
          // Return true if any collection contains the email/phone
          return userExists || companyExists || wholesalerExists || serviceProviderExists;
        }
        
        // Fallback to the old format
        return data['data']['exists'] ?? false;
      }
      return false;
    } catch (e) {
      print('Error checking email/phone existence: $e');
      return false;
    }
  }

  // New method to validate token
  static Future<ApiResponse> validateToken() async {
    try {
      final response = await _makeRequest(
        'get',
        '${baseUrl}${ApiConstants.validateToken}',
        headers: await getAuthHeaders(),
      );

      return _handleResponse(response);
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Public method to make authenticated requests
  static Future<http.Response> makeAuthenticatedRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    return await _makeRequest(method, url, headers: headers, body: body);
  }

  // Voucher management methods

  static Future<ApiResponse> createVoucher({
    required String name,
    required String description,
    required int points,
    required File imageFile,
  }) async {
    try {
      // Get auth headers
      final headers = await getAuthHeaders();
      
      // Create multipart request
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createVoucher}');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add form fields
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['points'] = points.toString();
      
      // Add image file
      final imageStream = http.ByteStream(imageFile.openRead());
      final imageLength = await imageFile.length();
      final multipartFile = http.MultipartFile(
        'image',
        imageStream,
        imageLength,
        filename: path.basename(imageFile.path),
      );
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);


      if (response.statusCode == 201) {
        // Check if response is HTML (error page)
       
        
        final responseData = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Voucher created successfully',
          data: responseData['data'],
        );
      } else {
        
        
        try {
          final responseData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to create voucher',
            data: responseData['data'],
          );
        } catch (jsonError) {
          return ApiResponse(
            success: false,
            message: 'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error creating voucher: $e');
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Web-compatible createVoucher method
  static Future<ApiResponse> createVoucherWeb({
    required String name,
    required String description,
    required int points,
    required Uint8List imageBytes,
    String? filename,
  }) async {
    try {
      // Get auth headers
      final headers = await getAuthHeaders();
      
      // Create multipart request
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createVoucher}');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add form fields
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['points'] = points.toString();
      
      // Add image file from bytes
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename ?? 'voucher_image.jpg',
      );
      request.files.add(multipartFile);
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2), // Increased timeout for image uploads
        onTimeout: () => throw Exception('Upload timeout: Please try again with a smaller image'),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Voucher created successfully',
          data: responseData['data'],
        );
      } else {
        try {
          final responseData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to create voucher',
            data: responseData['data'],
          );
        } catch (jsonError) {
          return ApiResponse(
            success: false,
            message: 'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error creating voucher: $e');
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  static Future<ApiResponse> getAllVouchers() async {
    try {
      final response = await _makeRequest(
        'GET',
        '${baseUrl}${ApiConstants.getAllVouchers}',
      );

      if (response.statusCode == 200) {
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          return ApiResponse(
            success: false,
            message: 'Voucher service is currently unavailable. Please try again later.',
          );
        }
        
        final responseData = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Vouchers retrieved successfully',
          data: responseData['data'],
        );
      } else {
        // Check if response is HTML (error page)
        if (response.body.trim().startsWith('<!DOCTYPE') || 
            response.body.trim().startsWith('<html')) {
          return ApiResponse(
            success: false,
            message: 'Voucher service is currently unavailable. Please try again later.',
          );
        }
        
        try {
          final responseData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to retrieve vouchers',
            data: responseData['data'],
          );
        } catch (jsonError) {
          return ApiResponse(
            success: false,
            message: 'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error retrieving vouchers: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to load vouchers. Please try again.',
      );
    }
  }

  static Future<ApiResponse> updateVoucher({
    required String voucherId,
    required String name,
    required String description,
    required int points,
    required String imageUrl,
  }) async {
    try {
      final voucherRequest = {
        'name': name,
        'description': description,
        'image': imageUrl,
        'points': points,
      };

      final response = await _makeRequest(
        'PUT',
        '${ApiConstants.updateVoucher}/$voucherId',
        body: jsonEncode(voucherRequest),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Voucher updated successfully',
          data: responseData['data'],
        );
      } else {
        try {
          final responseData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to update voucher',
            data: responseData['data'],
          );
        } catch (jsonError) {
          return ApiResponse(
            success: false,
            message: 'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error updating voucher: $e');
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  static Future<ApiResponse> updateVoucherWithImage({
    required String voucherId,
    required String name,
    required String description,
    required int points,
    required File imageFile,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateVoucher}/$voucherId');
      final request = http.MultipartRequest('PUT', uri);
      
      request.headers.addAll(headers);
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['points'] = points.toString();
      
      final multipartFile = http.MultipartFile(
        'image',
        http.ByteStream(imageFile.openRead()),
        await imageFile.length(),
        filename: path.basename(imageFile.path),
      );
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Voucher updated successfully',
          data: responseData['data'],
        );
      } else {
        try {
          final responseData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to update voucher',
            data: responseData['data'],
          );
        } catch (jsonError) {
          return ApiResponse(
            success: false,
            message: 'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error updating voucher: $e');
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Web-compatible updateVoucherWithImage method
  static Future<ApiResponse> updateVoucherWithImageWeb({
    required String voucherId,
    required String name,
    required String description,
    required int points,
    required Uint8List imageBytes,
    String? filename,
  }) async {
    try {
      final headers = await getAuthHeaders();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateVoucher}/$voucherId');
      final request = http.MultipartRequest('PUT', uri);
      
      request.headers.addAll(headers);
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['points'] = points.toString();
      
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename ?? 'voucher_image.jpg',
      );
      request.files.add(multipartFile);
      
      // Send request with timeout
      final streamedResponse = await request.send().timeout(
        const Duration(minutes: 2), // Increased timeout for image uploads
        onTimeout: () => throw Exception('Upload timeout: Please try again with a smaller image'),
      );
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Voucher updated successfully',
          data: responseData['data'],
        );
      } else {
        try {
          final responseData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to update voucher',
            data: responseData['data'],
          );
        } catch (jsonError) {
          return ApiResponse(
            success: false,
            message: 'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error updating voucher: $e');
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  static Future<ApiResponse> deleteVoucher(String voucherId) async {
    try {
      final response = await _makeRequest(
        'DELETE',
        '${baseUrl}${ApiConstants.deleteVoucher}/$voucherId',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Voucher deleted successfully',
          data: responseData['data'],
        );
      } else {
        try {
          final responseData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to delete voucher',
            data: responseData['data'],
          );
        } catch (jsonError) {
          return ApiResponse(
            success: false,
            message: 'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error deleting voucher: $e');
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  static Future<ApiResponse> toggleVoucherStatus(String voucherId) async {
    try {
      final response = await _makeRequest(
        'PUT',
        '${baseUrl}${ApiConstants.toggleVoucherStatus}/$voucherId/toggle-status',
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Voucher status updated successfully',
          data: responseData['data'],
        );
      } else {
        try {
          final responseData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to toggle voucher status',
            data: responseData['data'],
          );
        } catch (jsonError) {
          return ApiResponse(
            success: false,
            message: 'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error toggling voucher status: $e');
      return ApiResponse(
        success: false,
        message: 'Operation failed. Please try again.',
      );
    }
  }

  // Create user-type voucher with image upload
  static Future<ApiResponse> createUserTypeVoucherWithImage({
    required String name,
    required String description,
    required int points,
    required Uint8List imageBytes,
    required String targetUserType,
    String? filename,
  }) async {
    try {
      // Get auth headers
      final headers = await getAuthHeaders();
      
      // Create multipart request
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createUserTypeVoucher}');
      final request = http.MultipartRequest('POST', uri);
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add form fields
      request.fields['name'] = name;
      request.fields['description'] = description;
      request.fields['points'] = points.toString();
      request.fields['targetUserType'] = targetUserType;
      
      // Add image file
      final multipartFile = http.MultipartFile.fromBytes(
        'image',
        imageBytes,
        filename: filename ?? 'voucher_image.jpg',
      );
      request.files.add(multipartFile);
      
      // Send request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final responseData = json.decode(response.body);
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'Voucher created successfully',
          data: responseData['data'],
        );
      } else {
        final errorData = json.decode(response.body);
        return ApiResponse(
          success: false,
          message: errorData['message'] ?? 'Failed to create voucher',
        );
      }
    } catch (e) {
      return ApiResponse(
        success: false,
        message: 'Error creating voucher: $e',
      );
    }
  }

  // Create user-type voucher
  static Future<ApiResponse> createUserTypeVoucher({
    required String name,
    required String description,
    required int points,
    required String imageUrl,
    required String targetUserType,
  }) async {
    try {
      final token = await SessionManager().getToken();
      if (token == null) {
        return ApiResponse(
          success: false,
          message: 'Authentication required',
        );
      }

      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.createUserTypeVoucher}');
      
      final requestBody = {
        'name': name,
        'description': description,
        'points': points,
        'image': imageUrl,
        'targetUserType': targetUserType,
      };

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 201) {
        final responseData = jsonDecode(response.body);
        return ApiResponse(
          success: true,
          message: responseData['message'] ?? 'User-type voucher created successfully',
          data: responseData['data'],
        );
      } else {
        try {
          final responseData = jsonDecode(response.body);
          return ApiResponse(
            success: false,
            message: responseData['message'] ?? 'Failed to create user-type voucher',
            data: responseData['data'],
          );
        } catch (jsonError) {
          return ApiResponse(
            success: false,
            message: 'Server error: ${response.statusCode} - ${response.body}',
          );
        }
      }
    } catch (e) {
      print('Error creating user-type voucher: $e');
      return ApiResponse(
        success: false,
        message: 'Failed to create user-type voucher. Please try again.',
      );
    }
  }


}