import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sponsorship.dart';
import '../utils/api_response.dart';
import 'api_services.dart' hide ApiResponse;
import 'api_constant.dart';

class SponsorshipApiService {
  final String _baseUrl = ApiService.baseUrl;

  // Get headers with authentication using ApiService for consistency
  Future<Map<String, String>> _getHeaders() async {
    return await ApiService.getAuthHeaders();
  }

  // Create a new service provider sponsorship
  Future<ApiResponse<Sponsorship>> createServiceProviderSponsorship(SponsorshipRequest request) async {
    try {
      final headers = await _getHeaders();
      
      // Check if token is available
      if (!headers.containsKey('Authorization')) {
        return ApiResponse<Sponsorship>.error('Authentication required. Please log in again.');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.createServiceProviderSponsorship}'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      // Handle 401 Unauthorized errors
      if (response.statusCode == 401) {
        final responseData = jsonDecode(response.body);
        return ApiResponse<Sponsorship>.error(
          responseData['message'] ?? 'Authentication failed. Please log in again.',
        );
      }

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        final sponsorship = Sponsorship.fromJson(responseData['sponsorship']);
        return ApiResponse<Sponsorship>.completed(sponsorship);
      } else {
        return ApiResponse<Sponsorship>.error(responseData['message'] ?? 'Failed to create service provider sponsorship');
      }
    } catch (e) {
      return ApiResponse<Sponsorship>.error('Error creating service provider sponsorship: $e');
    }
  }

  // Create a new company/wholesaler sponsorship
  Future<ApiResponse<Sponsorship>> createCompanyWholesalerSponsorship(SponsorshipRequest request) async {
    try {
      final headers = await _getHeaders();
      
      // Check if token is available
      if (!headers.containsKey('Authorization')) {
        return ApiResponse<Sponsorship>.error('Authentication required. Please log in again.');
      }
      
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.createCompanyWholesalerSponsorship}'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      // Handle 401 Unauthorized errors
      if (response.statusCode == 401) {
        final responseData = jsonDecode(response.body);
        return ApiResponse<Sponsorship>.error(
          responseData['message'] ?? 'Authentication failed. Please log in again.',
        );
      }

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 201) {
        final sponsorship = Sponsorship.fromJson(responseData['sponsorship']);
        return ApiResponse<Sponsorship>.completed(sponsorship);
      } else {
        return ApiResponse<Sponsorship>.error(responseData['message'] ?? 'Failed to create company/wholesaler sponsorship');
      }
    } catch (e) {
      return ApiResponse<Sponsorship>.error('Error creating company/wholesaler sponsorship: $e');
    }
  }

  // Get all sponsorships with optional filtering
  Future<ApiResponse<SponsorshipListResponse>> getSponsorships({
    String? isActive,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      
      if (isActive != null) {
        queryParams['isActive'] = isActive;
      }

      final uri = Uri.parse('$_baseUrl${ApiConstants.getSponsorships}').replace(queryParameters: queryParams);
      
      final headers = await _getHeaders();
      
      print('=== SPONSORSHIP SERVICE: GET SPONSORSHIPS ===');
      print('URL: $uri');
      print('Headers: $headers');
      print('Authorization header present: ${headers.containsKey('Authorization')}');
      
      // Check if token is available
      if (!headers.containsKey('Authorization')) {
        print('ERROR: No Authorization header found');
        return ApiResponse<SponsorshipListResponse>.error('Authentication required. Please log in again.');
      }
      
      final response = await http.get(
        uri,
        headers: headers,
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      // Handle 401 Unauthorized errors
      if (response.statusCode == 401) {
        try {
          final responseData = jsonDecode(response.body);
          print('401 Error - Response data: $responseData');
          return ApiResponse<SponsorshipListResponse>.error(
            responseData['message'] ?? 'Authentication failed. Please log in again.',
          );
        } catch (e) {
          print('Error parsing 401 response: $e');
          return ApiResponse<SponsorshipListResponse>.error('Authentication failed. Please log in again.');
        }
      }

      // Handle other error status codes
      if (response.statusCode != 200) {
        try {
          final responseData = jsonDecode(response.body);
          print('Error response (${response.statusCode}): $responseData');
          return ApiResponse<SponsorshipListResponse>.error(
            responseData['message'] ?? 'Failed to retrieve sponsorships (Status: ${response.statusCode})',
          );
        } catch (e) {
          print('Error parsing error response: $e');
          return ApiResponse<SponsorshipListResponse>.error(
            'Failed to retrieve sponsorships (Status: ${response.statusCode})',
          );
        }
      }

      final responseData = jsonDecode(response.body);
      print('Success - Parsing response data');
      
      final sponsorshipList = SponsorshipListResponse.fromJson(responseData);
      return ApiResponse<SponsorshipListResponse>.completed(sponsorshipList);
    } catch (e, stackTrace) {
      print('Exception in getSponsorships: $e');
      print('Stack trace: $stackTrace');
      return ApiResponse<SponsorshipListResponse>.error('Error retrieving sponsorships: $e');
    }
  }

  // Get a specific sponsorship by ID
  Future<ApiResponse<Sponsorship>> getSponsorship(String id) async {
    try {
      final headers = await _getHeaders();
      
      // Check if token is available
      if (!headers.containsKey('Authorization')) {
        return ApiResponse<Sponsorship>.error('Authentication required. Please log in again.');
      }
      
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.getSponsorship}$id'),
        headers: headers,
      );

      // Handle 401 Unauthorized errors
      if (response.statusCode == 401) {
        final responseData = jsonDecode(response.body);
        return ApiResponse<Sponsorship>.error(
          responseData['message'] ?? 'Authentication failed. Please log in again.',
        );
      }

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final sponsorship = Sponsorship.fromJson(responseData['sponsorship']);
        return ApiResponse<Sponsorship>.completed(sponsorship);
      } else {
        return ApiResponse<Sponsorship>.error(responseData['message'] ?? 'Failed to retrieve sponsorship');
      }
    } catch (e) {
      return ApiResponse<Sponsorship>.error('Error retrieving sponsorship: $e');
    }
  }

  // Update an existing sponsorship
  Future<ApiResponse<void>> updateSponsorship(String id, SponsorshipUpdateRequest request) async {
    try {
      final headers = await _getHeaders();
      
      // Check if token is available
      if (!headers.containsKey('Authorization')) {
        return ApiResponse<void>.error('Authentication required. Please log in again.');
      }
      
      final response = await http.put(
        Uri.parse('$_baseUrl${ApiConstants.updateSponsorship}$id'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

      // Handle 401 Unauthorized errors
      if (response.statusCode == 401) {
        final responseData = jsonDecode(response.body);
        return ApiResponse<void>.error(
          responseData['message'] ?? 'Authentication failed. Please log in again.',
        );
      }

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse<void>.completed(null);
      } else {
        return ApiResponse<void>.error(responseData['message'] ?? 'Failed to update sponsorship');
      }
    } catch (e) {
      return ApiResponse<void>.error('Error updating sponsorship: $e');
    }
  }

  // Delete a sponsorship
  Future<ApiResponse<void>> deleteSponsorship(String id) async {
    try {
      final headers = await _getHeaders();
      
      // Check if token is available
      if (!headers.containsKey('Authorization')) {
        return ApiResponse<void>.error('Authentication required. Please log in again.');
      }
      
      final response = await http.delete(
        Uri.parse('$_baseUrl${ApiConstants.deleteSponsorship}$id'),
        headers: headers,
      );

      // Handle 401 Unauthorized errors
      if (response.statusCode == 401) {
        final responseData = jsonDecode(response.body);
        return ApiResponse<void>.error(
          responseData['message'] ?? 'Authentication failed. Please log in again.',
        );
      }

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        return ApiResponse<void>.completed(null);
      } else {
        return ApiResponse<void>.error(responseData['message'] ?? 'Failed to delete sponsorship');
      }
    } catch (e) {
      return ApiResponse<void>.error('Error deleting sponsorship: $e');
    }
  }


}
