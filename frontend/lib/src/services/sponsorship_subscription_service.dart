import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sponsorship.dart';
import '../utils/api_response.dart';
import '../utils/secure_storage.dart';
import 'api_constant.dart';

class SponsorshipSubscriptionApiService {
  final SecureStorage _secureStorage = SecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  // Get pending sponsorship subscription requests
  Future<ApiResponse<SponsorshipSubscriptionListResponse>> getPendingSponsorshipSubscriptionRequests({
    int page = 1,
    int limit = 10,
    String? entityType,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (entityType != null && entityType.isNotEmpty) {
        queryParams['entityType'] = entityType;
      }

      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.getPendingSponsorshipSubscriptionRequests)
          .replace(queryParameters: queryParams);

      print('DEBUG: Fetching pending sponsorship requests from: $uri');
      
      final response = await http.get(uri, headers: headers);
      final responseData = json.decode(response.body);

      print('DEBUG: Response status code: ${response.statusCode}');
      print('DEBUG: Raw response data: $responseData');

      if (response.statusCode == 200) {
        final data = SponsorshipSubscriptionListResponse.fromJson(responseData);
        print('DEBUG: Parsed ${data.requests.length} requests');
        if (data.requests.isNotEmpty) {
          print('DEBUG: First request ID: ${data.requests.first.id}');
          print('DEBUG: First request raw data: ${data.requests.first.toJson()}');
        }
        return ApiResponse<SponsorshipSubscriptionListResponse>.completed(data);
      } else {
        return ApiResponse<SponsorshipSubscriptionListResponse>.error(
          responseData['message'] ?? 'Failed to load pending requests',
        );
      }
    } catch (e) {
      print('DEBUG: Exception in getPendingSponsorshipSubscriptionRequests: $e');
      return ApiResponse<SponsorshipSubscriptionListResponse>.error('Exception: $e');
    }
  }

  // Process sponsorship subscription request (approve/reject)
  Future<ApiResponse<Map<String, dynamic>>> processSponsorshipSubscriptionRequest(
    String requestId,
    SponsorshipSubscriptionApprovalRequest approvalRequest,
  ) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.processSponsorshipSubscriptionRequest}/$requestId/process');

      print('DEBUG: Processing sponsorship request');
      print('DEBUG: Request ID: $requestId');
      print('DEBUG: Approval request: ${approvalRequest.toJson()}');
      print('DEBUG: URI: $uri');

      final response = await http.post(
        uri,
        headers: headers,
        body: json.encode(approvalRequest.toJson()),
      );

      print('DEBUG: Process response status: ${response.statusCode}');
      print('DEBUG: Process response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ApiResponse<Map<String, dynamic>>.completed(responseData);
      } else {
        return ApiResponse<Map<String, dynamic>>.error(
          responseData['message'] ?? 'Failed to process request',
        );
      }
    } catch (e) {
      print('DEBUG: Exception in processSponsorshipSubscriptionRequest: $e');
      return ApiResponse<Map<String, dynamic>>.error('Exception: $e');
    }
  }

  // Get active sponsorship subscriptions
  Future<ApiResponse<SponsorshipSubscriptionListResponse>> getActiveSponsorshipSubscriptions({
    int page = 1,
    int limit = 10,
    String? entityType,
  }) async {
    try {
      final headers = await _getHeaders();
      
      // Build query parameters
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (entityType != null && entityType.isNotEmpty) {
        queryParams['entityType'] = entityType;
      }

      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.getActiveSponsorshipSubscriptions)
          .replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);
      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        final data = SponsorshipSubscriptionListResponse.fromJson(responseData);
        return ApiResponse<SponsorshipSubscriptionListResponse>.completed(data);
      } else {
        return ApiResponse<SponsorshipSubscriptionListResponse>.error(
          responseData['message'] ?? 'Failed to load active subscriptions',
        );
      }
    } catch (e) {
      return ApiResponse<SponsorshipSubscriptionListResponse>.error('Exception: $e');
    }
  }
}
