// services/subscription_api_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:admin_dashboard/src/services/api_services.dart' as api;
import 'package:http/http.dart' as http;
import '../models/subscription.dart';
import '../utils/secure_storage.dart';
import '../utils/api_response.dart';

class SubscriptionApiService {
  static const String baseUrl = api.ApiService.baseUrl; 
  final SecureStorage _secureStorage = SecureStorage();

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API response and convert to ApiResponse
  ApiResponse<T> _handleResponse<T>(
      http.Response response,
      T Function(Map<String, dynamic>)? fromJson,
      ) {
    try {
      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (fromJson != null && responseData['data'] != null) {
          return ApiResponse.completed(fromJson(responseData));
        } else {
          return ApiResponse.completed(responseData as T);
        }
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Unknown error occurred'
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }

  // Handle list response
  ApiResponse<List<T>> _handleListResponse<T>(
      http.Response response,
      T Function(Map<String, dynamic>) fromJson,
      ) {
    try {
      final responseData = json.decode(response.body);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data = responseData;

        // Try to get the data list from a 'data' key if response is a map
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          data = responseData['data'];
        }

        // If data is null, return an empty list
        if (data == null) {
          return ApiResponse.completed(<T>[]);
        }

        // If data is a Map (not a List), return an empty list
        if (data is Map) {
          return ApiResponse.completed(<T>[]);
        }

        // If data is a List, process it
        if (data is List) {
          final List<T> items = data
              .where((item) => item is Map<String, dynamic>)
              .map((item) => fromJson(item as Map<String, dynamic>))
              .toList();
          return ApiResponse.completed(items);
        } else {
          return ApiResponse.completed(<T>[]);
        }
      } else {
        return ApiResponse.error(
            responseData['message'] ?? 'Unknown error occurred'
        );
      }
    } catch (e) {
      return ApiResponse.error('Failed to parse response: $e');
    }
  }

  // ============ ADMIN SUBSCRIPTION PLAN MANAGEMENT ============

  /// Get all subscription plans
  Future<ApiResponse<List<SubscriptionPlan>>> getAllSubscriptionPlans() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/subscription-plans'),
        headers: headers,
      );

      final apiResponse = _handleListResponse(response, SubscriptionPlan.fromJson);
      return apiResponse;
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to get subscription plans: $e');
    }
  }

  /// Get specific subscription plan by ID
  Future<ApiResponse<SubscriptionPlan>> getSubscriptionPlan(String planId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscriptions/plans/$planId'),
        headers: headers,
      );

      return _handleResponse(
        response,
            (data) => SubscriptionPlan.fromJson(data['data']),
      );
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to get subscription plan: $e');
    }
  }

  /// Create new subscription plan (Admin only)
  Future<ApiResponse<SubscriptionPlan>> createSubscriptionPlan(
      CreateSubscriptionPlanRequest plan,
      ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/subscription-plans'),
        headers: headers,
        body: json.encode(plan.toJson()),
      );
      
      print('Raw API Response: ${response.body}');
      
      // Handle both array and object responses
      final dynamic responseData = json.decode(response.body);
      if (responseData is List) {
        // If response is an array, take the first item
        if (responseData.isNotEmpty) {
          return ApiResponse.completed(SubscriptionPlan.fromJson(responseData[0]));
        }
        return ApiResponse.error('Empty response array');
      } else if (responseData is Map<String, dynamic>) {
        // If response is an object
        return ApiResponse.completed(SubscriptionPlan.fromJson(responseData));
      }
      
      return ApiResponse.error('Invalid response format');
    } catch (e, stackTrace) {
      print('API Error: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse.error(e.toString());
    }
  }

  /// Update subscription plan (Admin only)
  Future<ApiResponse<bool>> updateSubscriptionPlan(
      String planId,
      CreateSubscriptionPlanRequest request,
      ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/subscription-plans/$planId'),
        headers: headers,
        body: json.encode(request.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Update failed');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to update subscription plan: $e');
    }
  }

  /// Delete subscription plan (Admin only)
  Future<ApiResponse<bool>> deleteSubscriptionPlan(String planId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/admin/subscription-plans/$planId'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Delete failed');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to delete subscription plan: $e');
    }
  }

  // ============ SUBSCRIPTION REQUEST MANAGEMENT ============

  /// Get pending subscription requests (Admin only)
  Future<ApiResponse<List<SubscriptionRequest>>> getPendingSubscriptionRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/subscription/pending'),
        headers: headers,
      );

      return _handleListResponse(response, SubscriptionRequest.fromJson);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to get pending requests: $e');
    }
  }

  /// Process subscription request - approve or reject (Admin only)
  Future<ApiResponse<bool>> processSubscriptionRequest(
      String requestId,
      SubscriptionApprovalRequest approvalRequest,
      ) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/subscription-requests/$requestId/process'),
        headers: headers,
        body: json.encode(approvalRequest.toJson()),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Process failed');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to process subscription request: $e');
    }
  }

  /// Approve subscription request
  Future<ApiResponse<bool>> approveSubscriptionRequest(
      String requestId, {
        String? adminNote,
      }) async {
    final approvalRequest = SubscriptionApprovalRequest(
      status: 'approved',
      adminNote: adminNote,
    );
    return processSubscriptionRequest(requestId, approvalRequest);
  }

  /// Reject subscription request
  Future<ApiResponse<bool>> rejectSubscriptionRequest(
      String requestId, {
        String? adminNote,
      }) async {
    final approvalRequest = SubscriptionApprovalRequest(
      status: 'rejected',
      adminNote: adminNote,
    );
    return processSubscriptionRequest(requestId, approvalRequest);
  }

  /// Process company subscription request (Admin only, PUT method)
  Future<ApiResponse<bool>> processCompanySubscriptionRequest({
    required String requestId,
    required String status, // 'approved' or 'rejected'
    String? adminNote,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // The backend expects a request body with status and optional adminNote
      final requestBody = {
        'status': status,
        if (adminNote != null) 'adminNote': adminNote,
      };
      
      print('DEBUG: Company subscription request body: $requestBody');
      print('DEBUG: Company subscription request URL: $baseUrl/api/admin/company/subscription/requests/$requestId/process');
      
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/company/subscription/requests/$requestId/process'),
        headers: headers,
        body: json.encode(requestBody),
      );
      
      print('DEBUG: Company subscription response status code: ${response.statusCode}');
      print('DEBUG: Company subscription response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Process failed');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to process company subscription request: $e');
    }
  }

  /// Process wholesaler subscription request (Admin only, POST method)
  Future<ApiResponse<bool>> processWholesalerSubscriptionRequest({
    required String requestId,
    required String status, // 'approved' or 'rejected'
    String? adminNote,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // The backend expects a request body with status and optional adminNote
      final requestBody = {
        'status': status,
        if (adminNote != null) 'adminNote': adminNote,
      };
      
      print('DEBUG: Wholesaler request body: $requestBody');
      print('DEBUG: Wholesaler request URL: $baseUrl/api/admin/wholesaler/subscription/process/$requestId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/wholesaler/subscription/process/$requestId'),
        headers: headers,
        body: json.encode(requestBody),
      );
      
      print('DEBUG: Wholesaler response status code: ${response.statusCode}');
      print('DEBUG: Wholesaler response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Process failed');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to process wholesaler subscription request: $e');
    }
  }

  /// Process service provider subscription request (Admin only, POST method)
  Future<ApiResponse<bool>> processServiceProviderSubscriptionRequest({
    required String requestId,
    required String status, // 'approved' or 'rejected'
    String? adminNote,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // The backend expects a request body with status and optional adminNote
      final requestBody = {
        'status': status,
        if (adminNote != null) 'adminNote': adminNote,
      };
      
      print('DEBUG: Service provider request body: $requestBody');
      print('DEBUG: Service provider request URL: $baseUrl/api/admin/service-provider/subscription/process/$requestId');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/service-provider/subscription/process/$requestId'),
        headers: headers,
        body: json.encode(requestBody),
      );
      
      print('DEBUG: Service provider response status code: ${response.statusCode}');
      print('DEBUG: Service provider response body: ${response.body}');
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Process failed');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to process service provider subscription request: $e');
    }
  }

  /// Process branch subscription request (Admin only, POST method)
  /// [maxRetries] specifies how many times to retry on transient failures
  Future<ApiResponse<bool>> processBranchSubscriptionRequest({
    required String requestId,
    required String status, // 'approved' or 'rejected'
    String? adminNote,
    int maxRetries = 2,
  }) async {
    int attempt = 0;
    
    while (attempt <= maxRetries) {
      attempt++;
      
      try {
        // Validate status
        if (status.toLowerCase() != 'approved' && status.toLowerCase() != 'rejected') {
          return ApiResponse.error('Invalid status. Must be either "approved" or "rejected"');
        }

        final headers = await _getHeaders();
        
        // Ensure we have a valid token
        if (!headers.containsKey('Authorization')) {
          return ApiResponse.error('Authentication required. Please log in again.');
        }
        
        // The backend expects a request body with status and optional adminNote
        final requestBody = {
          'status': status.toLowerCase(), // Ensure lowercase
          if (adminNote != null && adminNote.isNotEmpty) 'adminNote': adminNote,
        };
        
        print('=== PROCESS BRANCH SUBSCRIPTION REQUEST (Attempt $attempt of ${maxRetries + 1}) ===');
        print('Request ID: $requestId');
        print('Endpoint: $baseUrl/api/admin/company/branch-subscription/requests/$requestId/process');
        print('Headers: ${headers.map((key, value) => MapEntry(key, key == 'Authorization' ? 'Bearer ***' : value))}');
        print('Request body: $requestBody');
        
        final stopwatch = Stopwatch()..start();
        final response = await http.post(
          Uri.parse('$baseUrl/api/admin/company/branch-subscription/requests/$requestId/process'),
          headers: {
            ...headers,
            'Content-Type': 'application/json',
          },
          body: json.encode(requestBody),
        );
        stopwatch.stop();
        
        print('=== RESPONSE ===');
        print('Status code: ${response.statusCode}');
        print('Response time: ${stopwatch.elapsedMilliseconds}ms');
        print('Response body: ${response.body}');
        
        try {
          final responseData = json.decode(response.body);
          
          if (response.statusCode >= 200 && response.statusCode < 300) {
            return ApiResponse.completed(true);
          } else {
            // Handle specific error cases
            final errorMessage = responseData['message']?.toString() ?? 
                               responseData['error']?.toString() ?? 
                               'Failed to process request (Status: ${response.statusCode})';
            
            // If we get a 500 with branch details error, it might be a race condition
            if (response.statusCode == 500 && 
                errorMessage.toLowerCase().contains('failed to get branch details') &&
                attempt <= maxRetries) {
              print('Branch details not found, retrying... (${attempt + 1}/$maxRetries)');
              await Future.delayed(Duration(seconds: 1 * attempt)); // Exponential backoff
              continue;
            }
            
            return ApiResponse.error(errorMessage);
          }
        } catch (e) {
          print('Failed to parse server response: $e');
          if (attempt <= maxRetries) {
            await Future.delayed(Duration(seconds: 1 * attempt));
            continue;
          }
          return ApiResponse.error('Failed to parse server response: $e');
        }
      } on SocketException {
        if (attempt <= maxRetries) {
          print('Network error, retrying... (${attempt + 1}/$maxRetries)');
          await Future.delayed(Duration(seconds: 1 * attempt));
          continue;
        }
        return ApiResponse.error('No internet connection. Please check your network and try again.');
      } catch (e, stackTrace) {
        print('=== ERROR DETAILS ===');
        print('Error: $e');
        print('Stack trace: $stackTrace');
        
        if (attempt <= maxRetries) {
          print('Error occurred, retrying... (${attempt + 1}/$maxRetries)');
          await Future.delayed(Duration(seconds: 1 * attempt));
          continue;
        }
        
        return ApiResponse.error(
          'Failed to process branch subscription request: ${e.toString()}' +
          (maxRetries > 0 ? ' (after $attempt attempts)' : '')
        );
      }
    }
    
    return ApiResponse.error('Failed to process request after $maxRetries attempts');
  }

  /// Get pending service provider subscription requests (Admin only)
  Future<ApiResponse<List<SubscriptionRequest>>> getPendingServiceProviderSubscriptionRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/service-provider/subscription/pending'),
        headers: headers,
      );

      return _handleListResponse(response, SubscriptionRequest.fromJson);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to get pending service provider requests: $e');
    }
  }



  /// Get pending branch subscription requests (Admin only)
  Future<ApiResponse<List<SubscriptionRequest>>> getPendingBranchSubscriptionRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/company/branch-subscription/requests/pending'),
        headers: headers,
      );

      return _handleListResponse(response, SubscriptionRequest.fromJson);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to get pending branch subscription requests: $e');
    }
  }

  /// Get enriched pending branch subscription requests with plan, company, and branch details (Admin only)
  Future<ApiResponse<List<EnrichedBranchSubscriptionRequest>>> getEnrichedPendingBranchSubscriptionRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/company/branch-subscription/requests/pending'),
        headers: headers,
      );

      return _handleEnrichedBranchSubscriptionResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to get enriched pending branch subscription requests: $e');
    }
  }

  // Handle enriched branch subscription response
  ApiResponse<List<EnrichedBranchSubscriptionRequest>> _handleEnrichedBranchSubscriptionResponse(http.Response response) {
    try {
      print('=== PARSING ENRICHED BRANCH SUBSCRIPTION RESPONSE ===');
      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final responseData = json.decode(response.body);
      print('Decoded response data: $responseData');

      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Extract the branchRequests array from the response data
        final data = responseData['data'];
        print('Data field: $data');
        if (data == null) {
          print('Data is null, returning empty list');
          return ApiResponse.completed(<EnrichedBranchSubscriptionRequest>[]);
        }

        final branchRequests = data['branchRequests'];
        print('Branch requests field: $branchRequests');
        print('Branch requests type: ${branchRequests.runtimeType}');
        if (branchRequests == null || branchRequests is! List) {
          print('Branch requests is null or not a list, returning empty list');
          return ApiResponse.completed(<EnrichedBranchSubscriptionRequest>[]);
        }

        print('Processing ${branchRequests.length} branch requests...');
        
        // Convert each item to EnrichedBranchSubscriptionRequest
        final List<EnrichedBranchSubscriptionRequest> items = [];
        for (int i = 0; i < branchRequests.length; i++) {
          final item = branchRequests[i];
          print('Processing item $i: $item');
          
          if (item is Map<String, dynamic>) {
            try {
              final enrichedRequest = EnrichedBranchSubscriptionRequest.fromJson(item);
              items.add(enrichedRequest);
              print('Successfully parsed item $i: ID=${enrichedRequest.id}, Business=${enrichedRequest.businessName}, Branch=${enrichedRequest.branchName}');
            } catch (e) {
              print('Error parsing item $i: $e');
              print('Item data: $item');
            }
          } else {
            print('Item $i is not a Map<String, dynamic>: ${item.runtimeType}');
          }
        }
        
        print('Successfully parsed ${items.length} enriched branch subscription requests');
        return ApiResponse.completed(items);
      } else {
        print('HTTP error: ${response.statusCode}');
        return ApiResponse.error(
            responseData['message'] ?? 'Unknown error occurred'
        );
      }
    } catch (e) {
      print('Exception in _handleEnrichedBranchSubscriptionResponse: $e');
      print('Stack trace: ${StackTrace.current}');
      return ApiResponse.error('Failed to parse enriched branch subscription response: $e');
    }
  }

  /// Get pending wholesaler subscription requests (Admin only)
  Future<ApiResponse<List<SubscriptionRequest>>> getPendingWholesalerSubscriptionRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/wholesaler/subscription/pending'),
        headers: headers,
      );

      return _handleListResponse(response, SubscriptionRequest.fromJson);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to get pending wholesaler subscription requests: $e');
    }
  }

  /// Get enriched pending wholesaler subscription requests with wholesaler and plan details (Admin only)
  Future<ApiResponse<List<EnrichedWholesalerSubscriptionRequest>>> getEnrichedPendingWholesalerSubscriptionRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/wholesaler/subscription/pending'),
        headers: headers,
      );

      return _handleEnrichedWholesalerSubscriptionResponse(response);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to get enriched pending wholesaler subscription requests: $e');
    }
  }

  // Handle enriched wholesaler subscription response
  ApiResponse<List<EnrichedWholesalerSubscriptionRequest>> _handleEnrichedWholesalerSubscriptionResponse(http.Response response) {
    try {
      print('=== PARSING ENRICHED WHOLESALER SUBSCRIPTION RESPONSE ===');
      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');
      
      final responseData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        dynamic data = responseData;
        
        // Try to get the data list from a 'data' key if response is a map
        if (responseData is Map<String, dynamic> && responseData.containsKey('data')) {
          data = responseData['data'];
        }
        
        // If data is null, return an empty list
        if (data == null) {
          print('Data is null, returning empty list');
          return ApiResponse.completed(<EnrichedWholesalerSubscriptionRequest>[]);
        }
        
        // If data is a Map (not a List), return an empty list
        if (data is Map) {
          print('Data is a Map, returning empty list');
          return ApiResponse.completed(<EnrichedWholesalerSubscriptionRequest>[]);
        }
        
        // If data is a List, process it
        if (data is List) {
          print('Processing ${data.length} enriched wholesaler subscription requests');
          final List<EnrichedWholesalerSubscriptionRequest> items = data
              .where((item) => item is Map<String, dynamic>)
              .map((item) => EnrichedWholesalerSubscriptionRequest.fromJson(item as Map<String, dynamic>))
              .toList();
          print('Successfully parsed ${items.length} enriched wholesaler subscription requests');
          return ApiResponse.completed(items);
        } else {
          print('Data is not a List, returning empty list');
          return ApiResponse.completed(<EnrichedWholesalerSubscriptionRequest>[]);
        }
      } else {
        final errorMessage = responseData['message'] ?? 'Unknown error occurred';
        print('Error response: $errorMessage');
        return ApiResponse.error(errorMessage);
      }
    } catch (e) {
      print('Error parsing enriched wholesaler subscription response: $e');
      return ApiResponse.error('Failed to parse enriched wholesaler subscription response: $e');
    }
  }

  /// Approve company subscription (Admin only)
  Future<ApiResponse<bool>> approveCompanySubscription(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/company-subscription/$id/approve'),
        headers: headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Failed to approve company subscription');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to approve company subscription: $e');
    }
  }

  /// Reject company subscription (Admin only)
  Future<ApiResponse<bool>> rejectCompanySubscription(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/api/admin/company-subscription/$id/reject'),
        headers: headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Failed to reject company subscription');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to reject company subscription: $e');
    }
  }

  /// Approve service provider subscription (Admin only)
  Future<ApiResponse<bool>> approveServiceProviderSubscription(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/service-provider/subscription/$id/approve'),
        headers: headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Failed to approve service provider subscription');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to approve service provider subscription: $e');
    }
  }

  /// Reject service provider subscription (Admin only)
  Future<ApiResponse<bool>> rejectServiceProviderSubscription(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/service-provider/subscription/$id/reject'),
        headers: headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Failed to reject service provider subscription');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to reject service provider subscription: $e');
    }
  }

  /// Approve wholesaler subscription (Admin only)
  Future<ApiResponse<bool>> approveWholesalerSubscription(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/wholesaler-subscription/$id/approve'),
        headers: headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Failed to approve wholesaler subscription');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to approve wholesaler subscription: $e');
    }
  }

  /// Reject wholesaler subscription (Admin only)
  Future<ApiResponse<bool>> rejectWholesalerSubscription(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/wholesaler-subscription/$id/reject'),
        headers: headers,
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Failed to reject wholesaler subscription');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to reject wholesaler subscription: $e');
    }
  }

  // ============ COMPANY SUBSCRIPTION OPERATIONS ============

  /// Create subscription request (Company side)
  Future<ApiResponse<SubscriptionRequest>> createSubscriptionRequest(String planId, {String? branchId}) async {
    try {
      final headers = await _getHeaders();
      
      // Use the new branch subscription request endpoint
      final endpoint = branchId != null 
          ? '$baseUrl/api/companies/subscription/$branchId/request'
          : '$baseUrl/api/subscriptions/request';
      
      final response = await http.post(
        Uri.parse(endpoint),
        headers: headers,
        body: json.encode({
          'planId': planId,
          if (branchId != null) 'branchId': branchId,
        }),
      );

      return _handleResponse(
        response,
        (data) => SubscriptionRequest.fromJson(data['data']),
      );
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to create subscription request: $e');
    }
  }

  /// Create branch subscription request (Company side)
  Future<ApiResponse<SubscriptionRequest>> createBranchSubscriptionRequest(String planId, String branchId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/companies/subscription/$branchId/request'),
        headers: headers,
        body: json.encode({'planId': planId}),
      );

      return _handleResponse(
        response,
        (data) => SubscriptionRequest.fromJson(data['data']),
      );
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to create branch subscription request: $e');
    }
  }

  /// Get current subscription for authenticated company
  Future<ApiResponse<CompanySubscription?>> getCurrentSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscriptions/current'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseData = json.decode(response.body);
        if (responseData['data'] != null) {
          return ApiResponse.completed(
              CompanySubscription.fromJson(responseData['data'])
          );
        } else {
          return ApiResponse.completed(null);
        }
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Failed to get current subscription');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to get current subscription: $e');
    }
  }

  /// Get subscription remaining time
  Future<ApiResponse<Map<String, dynamic>>> getSubscriptionRemainingTime() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/subscriptions/remaining-time'),
        headers: headers,
      );

      return _handleResponse(response, (data) => data['data']);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to get remaining time: $e');
    }
  }

  /// Cancel subscription
  Future<ApiResponse<bool>> cancelSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/subscriptions/cancel'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Cancel failed');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to cancel subscription: $e');
    }
  }

  /// Pause subscription (Not implemented in backend yet)
  Future<ApiResponse<bool>> pauseSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/subscriptions/pause'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Pause failed');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to pause subscription: $e');
    }
  }

  /// Renew subscription (Not implemented in backend yet)
  Future<ApiResponse<bool>> renewSubscription() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/api/subscriptions/renew'),
        headers: headers,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.completed(true);
      } else {
        final responseData = json.decode(response.body);
        return ApiResponse.error(responseData['message'] ?? 'Renew failed');
      }
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to renew subscription: $e');
    }
  }

  // ============ UTILITY METHODS ============

  // ============ WHOLESALER BRANCH SUBSCRIPTION REQUESTS ============

  /// Get pending wholesaler branch subscription requests
  Future<ApiResponse<List<EnrichedWholesalerBranchSubscriptionRequest>>> getPendingWholesalerBranchSubscriptionRequests() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/admin/wholesaler/branch-subscription/requests/pending'),
        headers: headers,
      );

      return _handleListResponse(
        response,
        EnrichedWholesalerBranchSubscriptionRequest.fromJson,
      );
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to fetch pending wholesaler branch subscription requests: $e');
    }
  }

  /// Approve wholesaler branch subscription request
  Future<ApiResponse<Map<String, dynamic>>> approveWholesalerBranchSubscriptionRequest({
    required String requestId,
    String? adminNote,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'status': 'approved',
        if (adminNote != null) 'adminNote': adminNote,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/wholesaler-branch-subscription/request/$requestId/approve'),
        headers: headers,
        body: json.encode(body),
      );

      return _handleResponse(response, (json) => json);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to approve wholesaler branch subscription request: $e');
    }
  }

  /// Reject wholesaler branch subscription request
  Future<ApiResponse<Map<String, dynamic>>> rejectWholesalerBranchSubscriptionRequest({
    required String requestId,
    required String adminNote,
  }) async {
    try {
      final headers = await _getHeaders();
      final body = {
        'status': 'rejected',
        'adminNote': adminNote,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/api/admin/wholesaler-branch-subscription/request/$requestId/reject'),
        headers: headers,
        body: json.encode(body),
      );

      return _handleResponse(response, (json) => json);
    } on SocketException {
      return ApiResponse.error('No internet connection');
    } catch (e) {
      return ApiResponse.error('Failed to reject wholesaler branch subscription request: $e');
    }
  }

  /// Process wholesaler branch subscription request (approve or reject)
  Future<ApiResponse<Map<String, dynamic>>> processWholesalerBranchSubscriptionRequest({
    required String requestId,
    required String status,
    String? adminNote,
  }) async {
    if (status == 'approved') {
      return approveWholesalerBranchSubscriptionRequest(
        requestId: requestId,
        adminNote: adminNote,
      );
    } else if (status == 'rejected') {
      if (adminNote == null || adminNote.isEmpty) {
        return ApiResponse.error('Admin note is required when rejecting a request');
      }
      return rejectWholesalerBranchSubscriptionRequest(
        requestId: requestId,
        adminNote: adminNote,
      );
    } else {
      return ApiResponse.error('Invalid status. Must be "approved" or "rejected"');
    }
  }

  // ============ UTILITY METHODS ============

  /// Check if user has access to admin features
  Future<bool> isAdmin() async {
    final role = await _secureStorage.getRole();
    return role == 'admin';
  }

  /// Get subscription types
  List<String> getSubscriptionTypes() {
    return ['company', 'wholesaler', 'service_provider'];
  }

  /// Get valid durations
  List<int> getValidDurations() {
    return [1, 6, 12]; // Monthly, 6 Months, Yearly
  }

  /// Format duration text
  String formatDuration(int duration) {
    switch (duration) {
      case 1:
        return 'Monthly';
      case 6:
        return '6 Months';
      case 12:
        return 'Yearly';
      default:
        return '$duration Months';
    }
  }

  /// Format price
  String formatPrice(double price) {
    return '\$${price.toStringAsFixed(2)}';
  }
}