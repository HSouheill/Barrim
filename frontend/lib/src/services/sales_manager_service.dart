import 'dart:convert';
import 'dart:io';
import 'package:admin_dashboard/src/services/api_services.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

import '../models/sales_manager.dart';
import '../models/salesperson_model.dart';
import '../screens/business_management/business_management.dart' as business;
import '../utils/secure_storage.dart';

enum Status { initial, loading, completed, error }

class ApiResponse<T> {
  final Status status;
  final String message;
  final T? data;

  ApiResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory ApiResponse.completed(T data) {
    return ApiResponse(
      status: Status.completed,
      message: 'Success',
      data: data,
    );
  }

  factory ApiResponse.error(String message) {
    return ApiResponse(
      status: Status.error,
      message: message,
    );
  }
}

class SalesManagerService {
  // Replace static baseUrl with secure base URL getter
  static String get secureBaseUrl {
    String url = ApiService.baseUrl.trim();
    if (url.startsWith('https://')) {
      return url;
    }
    // Remove http:// if present
    url = url.replaceFirst(RegExp(r'^http://'), '');
    // Remove any leading/trailing slashes
    url = url.replaceAll(RegExp(r'^/+|/+$'), '');
    return 'https://$url';
  }

  static const String baseUrl = ApiService.baseUrl; 
  static final SecureStorage _secureStorage = SecureStorage();

  // Private constructor
  SalesManagerService._();

  // Singleton instance
  static final SalesManagerService _instance = SalesManagerService._();
  static SalesManagerService get instance => _instance;

  // Get auth headers with token
  Future<Map<String, String>> _getAuthHeaders() async {
    final token = await _secureStorage.getToken();
    final role = await _secureStorage.getRole();
    
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
      'User-Type': 'sales_manager',
      'User-Role': role ?? 'sales_manager',
    };
  }

  // Helper method to ensure HTTPS URLs
  static String _ensureHttps(String url) {
    if (url.startsWith('https://')) {
      return url;
    }
    return url.replaceFirst(RegExp(r'^(http://|)'), 'https://');
  }

  // Helper method to make secure HTTP requests
  Future<http.Response> _makeSecureRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('${SalesManagerService.secureBaseUrl}$endpoint');
    final requestHeaders = headers ?? await _getAuthHeaders();

    switch (method.toLowerCase()) {
      case 'get':
        return await http.get(uri, headers: requestHeaders);
      case 'post':
        return await http.post(uri, headers: requestHeaders, body: body);
      case 'put':
        return await http.put(uri, headers: requestHeaders, body: body);
      case 'delete':
        return await http.delete(uri, headers: requestHeaders, body: body);
      default:
        throw UnsupportedError('HTTP method not supported: $method');
    }
  }

  // Login Sales Manager
  Future<ApiResponse<Map<String, dynamic>>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _makeSecureRequest(
        'post',
        '/api/admin/login',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Store authentication data
        final data = responseData['data'];
        if (data != null) {
          final token = data['token'];
          final user = data['user'];

          if (token != null) {
            await _secureStorage.setToken(token);
          }

          if (user != null && user['email'] != null) {
            await _secureStorage.setEmail(user['email']);
            await _secureStorage.setRole('sales_manager');
          }
        }

        return ApiResponse.completed(responseData);
      } else {
        // Handle specific login error cases with user-friendly messages
        String errorMessage = responseData['message'] ?? 'Login failed';
        
        if (response.statusCode == 401) {
          errorMessage = 'Incorrect email or password. Please try again.';
        } else if (response.statusCode == 400) {
          errorMessage = 'Invalid login data. Please check your email and password.';
        } else if (response.statusCode >= 500) {
          errorMessage = 'Server error. Please try again later.';
        }
        
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      debugPrint('Login error: $e');
      
      // Handle specific exception types with user-friendly messages
      String errorMessage = 'Network error occurred';
      
      if (e.toString().toLowerCase().contains('stream') ||
          e.toString().toLowerCase().contains('addstream')) {
        errorMessage = 'Incorrect email or password. Please try again.';
      } else if (e.toString().toLowerCase().contains('timeout')) {
        errorMessage = 'Login timeout. Please try again.';
      } else if (e.toString().toLowerCase().contains('unauthorized') ||
                 e.toString().toLowerCase().contains('401')) {
        errorMessage = 'Incorrect email or password. Please try again.';
      }
      
      return ApiResponse.error(errorMessage);
    }
  }

  // Forgot Password
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String phone,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sales-manager/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to send OTP'
        );
      }
    } catch (e) {
      debugPrint('Forgot password error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Reset Password
  Future<ApiResponse<String>> resetPassword({
    required String phone,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sales-manager/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phone': phone,
          'otp': otp,
          'newPassword': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message']);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to reset password'
        );
      }
    } catch (e) {
      debugPrint('Reset password error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Create Salesperson
  Future<ApiResponse<Salesperson>> createSalesperson({
    required Salesperson salesperson,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/sales-manager/salespersons'),
        headers: headers,
        body: jsonEncode(salesperson.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 201) {
        final salespersonData = Salesperson.fromJson(responseData['data']);
        return ApiResponse.completed(salespersonData);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to create salesperson'
        );
      }
    } catch (e) {
      debugPrint('Create salesperson error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Get All Salespersons
  Future<ApiResponse<List<Salesperson>>> GetAdminSalespersons() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-manager/salespersons'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> salespersonsJson = responseData['data'] ?? [];
        final salespersons = <Salesperson>[];
        for (var json in salespersonsJson) {
          if (json != null && json is Map<String, dynamic>) {
            try {
              salespersons.add(Salesperson.fromJson(json));
            } catch (error) {
              debugPrint('Error parsing salesperson: $error');
            }
          }
        }
        return ApiResponse.completed(salespersons);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to fetch salespersons'
        );
      }
    } catch (e) {
      debugPrint('Get all salespersons error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Get Salesperson by ID
  Future<ApiResponse<Salesperson>> getSalesperson(String salespersonId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-manager/salespersons/$salespersonId'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final salesperson = Salesperson.fromJson(responseData['data']);
        return ApiResponse.completed(salesperson);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Salesperson not found'
        );
      }
    } catch (e) {
      debugPrint('Get salesperson error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Update Salesperson
  // Update Salesperson
  Future<ApiResponse<String>> updateSalesperson({
    required String salespersonId,
    required Salesperson salesperson,
  }) async {
    try {
      final headers = await _getAuthHeaders();

      // Use the specific update JSON method
      final requestBody = salesperson.toUpdateJson();

      // Log the request for debugging
      print('Update request URL: $baseUrl/api/sales-manager/salespersons/$salespersonId');
      print('Update request headers: $headers');
      print('Update request body: ${jsonEncode(requestBody)}');

      final response = await http.put(
        Uri.parse('$baseUrl/api/sales-manager/salespersons/$salespersonId'),
        headers: headers,
        body: jsonEncode(requestBody),
      );

      print('Update response status: ${response.statusCode}');
      print('Update response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message']);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to update salesperson'
        );
      }
    } catch (e) {
      debugPrint('Update salesperson error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Delete Salesperson
  Future<ApiResponse<String>> deleteSalesperson(String salespersonId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/sales-manager/salespersons/$salespersonId'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message']);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to delete salesperson'
        );
      }
    } catch (e) {
      debugPrint('Delete salesperson error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Get Current Sales Manager Profile
  Future<ApiResponse<SalesManager>> getCurrentProfile() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final salesManager = SalesManager.fromJson(responseData['data']);
        return ApiResponse.completed(salesManager);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to fetch profile'
        );
      }
    } catch (e) {
      debugPrint('Get profile error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Update Sales Manager Profile
  Future<ApiResponse<String>> updateProfile({
    required SalesManager salesManager,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: headers,
        body: jsonEncode(salesManager.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message']);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to update profile'
        );
      }
    } catch (e) {
      debugPrint('Update profile error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Logout
  Future<ApiResponse<String>> logout() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/logout'),
        headers: headers,
      );

      // Clear local storage regardless of response
      await _secureStorage.clearAll();

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return ApiResponse.completed(responseData['message'] ?? 'Logged out successfully');
      } else {
        return ApiResponse.completed('Logged out successfully');
      }
    } catch (e) {
      // Clear local storage even if network call fails
      await _secureStorage.clearAll();
      debugPrint('Logout error: $e');
      return ApiResponse.completed('Logged out successfully');
    }
  }

  // Check if user is authenticated
  Future<bool> isAuthenticated() async {
    try {
      final token = await _secureStorage.getToken();
      final role = await _secureStorage.getRole();

      if (token == null || role != 'sales_manager') {
        return false;
      }

      // Optionally verify token with server
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/profile'),
        headers: headers,
      );

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Authentication check error: $e');
      return false;
    }
  }

  // Upload Profile Image
  Future<ApiResponse<String>> uploadProfileImage(File imageFile) async {
    try {
      final headers = await _getAuthHeaders();
      headers.remove('Content-Type'); // Remove content-type for multipart

      final uri = Uri.parse('$secureBaseUrl/api/upload-profile-photo');
      final request = http.MultipartRequest('POST', uri);

      request.headers.addAll(headers);
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['data']['imageUrl']);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to upload image'
        );
      }
    } catch (e) {
      debugPrint('Upload image error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Get Salesperson Statistics
  Future<ApiResponse<Map<String, dynamic>>> getSalespersonStatistics() async {
    try {
      final salespersonsResponse = await GetAdminSalespersons();

      if (salespersonsResponse.status == Status.completed) {
        final salespersons = salespersonsResponse.data!;

        final stats = {
          'total': salespersons.length,
          'active': salespersons.where((s) => s.status == 'active').length,
          'inactive': salespersons.where((s) => s.status == 'inactive').length,
          'recentlyAdded': salespersons.where((s) {
            if (s.createdAt == null) return false;
            final now = DateTime.now();
            final weekAgo = now.subtract(const Duration(days: 7));
            return s.createdAt!.isAfter(weekAgo);
          }).length,
        };

        return ApiResponse.completed(stats);
      } else {
        return ApiResponse.error(salespersonsResponse.message ?? 'Failed to get statistics');
      }
    } catch (e) {
      debugPrint('Get statistics error: $e');
      return ApiResponse.error('Failed to calculate statistics');
    }
  }

  // Search Salespersons
  Future<ApiResponse<List<Salesperson>>> searchSalespersons({
    String? query,
    String? status,
    String? territory,
  }) async {
    try {
      final allSalespersonsResponse = await GetAdminSalespersons();

      if (allSalespersonsResponse.status == Status.completed) {
        var salespersons = allSalespersonsResponse.data!;

        // Apply filters
        if (query != null && query.isNotEmpty) {
          salespersons = salespersons.where((s) {
            return s.fullName.toLowerCase().contains(query.toLowerCase()) ||
                s.email.toLowerCase().contains(query.toLowerCase()) ||
                s.phoneNumber.contains(query);
          }).toList();
        }

        if (status != null && status.isNotEmpty) {
          salespersons = salespersons.where((s) => s.status == status).toList();
        }

        return ApiResponse.completed(salespersons);
      } else {
        return ApiResponse.error(allSalespersonsResponse.message ?? 'Failed to search salespersons');
      }
    } catch (e) {
      debugPrint('Search salespersons error: $e');
      return ApiResponse.error('Failed to search salespersons');
    }
  }

  // Change Password
  Future<ApiResponse<String>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/users/change-password'),
        headers: headers,
        body: jsonEncode({
          'currentPassword': currentPassword,
          'newPassword': newPassword,
        }),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message']);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to change password'
        );
      }
    } catch (e) {
      debugPrint('Change password error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Get User Data
  Future<ApiResponse<Map<String, dynamic>>> getUserData() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/get-user-data'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['data']);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to fetch user data'
        );
      }
    } catch (e) {
      debugPrint('Get user data error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Add this function to the SalesManagerService class

// Get Salespersons Created by Current Sales Manager
  Future<ApiResponse<List<Salesperson>>> getSalespersonsByCreator() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-manager/salespersons/by-creator'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List<dynamic> salespersonsJson = responseData['data'] ?? [];
        final salespersons = <Salesperson>[];
        for (var json in salespersonsJson) {
          if (json != null && json is Map<String, dynamic>) {
            try {
              salespersons.add(Salesperson.fromJson(json));
            } catch (error) {
              debugPrint('Error parsing salesperson: $error');
            }
          }
        }
        return ApiResponse.completed(salespersons);
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Failed to fetch salespersons by creator'
        );
      }
    } catch (e) {
      debugPrint('Get salespersons by creator error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Pending Company Requests
  Future<ApiResponse<List<dynamic>>> getPendingCompanies() async {
    try {
      final response = await _makeSecureRequest(
        'get',
        '/api/sales-manager/pending-companies',
      );
      
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        // If responseData is a map and contains 'data', use it; else, use responseData directly if it's a list
        List<dynamic> data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          data = responseData['data'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          data = [];
        }
        return ApiResponse.completed(data);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to fetch pending companies');
      }
    } catch (e) {
      debugPrint('Get pending companies error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }
  Future<ApiResponse<String>> approvePendingCompany(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/sales-manager/pending-companies/$id/approve'),
        headers: headers,
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message'] ?? 'Company request approved');
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to approve company');
      }
    } catch (e) {
      debugPrint('Approve pending company error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }
  Future<ApiResponse<String>> rejectPendingCompany(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/sales-manager/pending-companies/$id/reject'),
        headers: headers,
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message'] ?? 'Company request rejected');
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to reject company');
      }
    } catch (e) {
      debugPrint('Reject pending company error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Pending Wholesaler Requests
  Future<ApiResponse<List<dynamic>>> getPendingWholesalers() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-manager/pending-wholesalers'),
        headers: headers,
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        List<dynamic> data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          data = responseData['data'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          data = [];
        }
        return ApiResponse.completed(data);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to fetch pending wholesalers');
      }
    } catch (e) {
      debugPrint('Get pending wholesalers error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }
  Future<ApiResponse<String>> approvePendingWholesaler(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/sales-manager/pending-wholesalers/$id/approve'),
        headers: headers,
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message'] ?? 'Wholesaler request approved');
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to approve wholesaler');
      }
    } catch (e) {
      debugPrint('Approve pending wholesaler error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }
  Future<ApiResponse<String>> rejectPendingWholesaler(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/sales-manager/pending-wholesalers/$id/reject'),
        headers: headers,
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message'] ?? 'Wholesaler request rejected');
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to reject wholesaler');
      }
    } catch (e) {
      debugPrint('Reject pending wholesaler error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Pending Service Provider Requests
  Future<ApiResponse<List<dynamic>>> getPendingServiceProviders() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-manager/pending-service-providers'),
        headers: headers,
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        List<dynamic> data;
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          data = responseData['data'] ?? [];
        } else if (responseData is List) {
          data = responseData;
        } else {
          data = [];
        }
        return ApiResponse.completed(data);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to fetch pending service providers');
      }
    } catch (e) {
      debugPrint('Get pending service providers error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }
  Future<ApiResponse<String>> approvePendingServiceProvider(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/sales-manager/pending-service-providers/$id/approve'),
        headers: headers,
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message'] ?? 'Service provider request approved');
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to approve service provider');
      }
    } catch (e) {
      debugPrint('Approve pending service provider error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }
  Future<ApiResponse<String>> rejectPendingServiceProvider(String id) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/sales-manager/pending-service-providers/$id/reject'),
        headers: headers,
      );
      final responseData = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return ApiResponse.completed(responseData['message'] ?? 'Service provider request rejected');
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to reject service provider');
      }
    } catch (e) {
      debugPrint('Reject pending service provider error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Get commission summary for the logged-in sales manager
  Future<ApiResponse<Map<String, dynamic>>> getCommissionSummary() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/commission/summary'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['data'] != null) {
          final data = responseData['data'];
          return ApiResponse.completed({
            'totalCommission': (data['totalCommission'] ?? 0).toDouble(),
            'totalWithdrawn': (data['totalWithdrawn'] ?? 0).toDouble(),
            'availableBalance': (data['availableBalance'] ?? 0).toDouble(),
          });
        } else {
          return ApiResponse.error('Invalid response format: missing data field');
        }
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to fetch commission summary');
      }
    } catch (e) {
      debugPrint('Get commission summary error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Request commission withdrawal
  Future<ApiResponse<String>> requestCommissionWithdrawal(double amount) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/commission/withdraw'),
        headers: headers,
        body: jsonEncode({'amount': amount}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse.completed('Withdrawal request submitted successfully');
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to request withdrawal');
      }
    } catch (e) {
      debugPrint('Request commission withdrawal error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Get commission and withdrawal history for the logged-in sales manager
  Future<ApiResponse<Map<String, dynamic>>> getCommissionAndWithdrawalHistory() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-manager/commission-withdrawal-history'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (responseData['data'] != null) {
          return ApiResponse.completed({
            'commissions': responseData['data']['commissions'] ?? [],
            'withdrawals': responseData['data']['withdrawals'] ?? [],
          });
        } else {
          return ApiResponse.error('Invalid response format: missing data field');
        }
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to fetch commission history');
      }
    } catch (e) {
      debugPrint('Get commission history error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }

  // Get total commission balance
  Future<ApiResponse<double>> getTotalCommissionBalance() async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/commission/balance'),
        headers: headers,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final balance = (responseData['data'] ?? 0).toDouble();
        return ApiResponse.completed(balance);
      } else {
        return ApiResponse.error(responseData['message'] ?? 'Failed to fetch commission balance');
      }
    } catch (e) {
      debugPrint('Get commission balance error: $e');
      return ApiResponse.error('Network error occurred');
    }
  }
}