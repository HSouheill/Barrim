import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sponsorship.dart';
import '../utils/api_response.dart';
import '../utils/secure_storage.dart';
import 'api_constant.dart';

class SponsorshipApiService {
  final String _baseUrl = ApiConstants.baseUrl;
  final SecureStorage _secureStorage = SecureStorage();

  // Get headers with authentication
  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Create a new service provider sponsorship
  Future<ApiResponse<Sponsorship>> createServiceProviderSponsorship(SponsorshipRequest request) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.createServiceProviderSponsorship}'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

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
      final response = await http.post(
        Uri.parse('$_baseUrl${ApiConstants.createCompanyWholesalerSponsorship}'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

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
      final response = await http.get(
        uri,
        headers: headers,
      );

      final responseData = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        final sponsorshipList = SponsorshipListResponse.fromJson(responseData);
        return ApiResponse<SponsorshipListResponse>.completed(sponsorshipList);
      } else {
        return ApiResponse<SponsorshipListResponse>.error(responseData['message'] ?? 'Failed to retrieve sponsorships');
      }
    } catch (e) {
      return ApiResponse<SponsorshipListResponse>.error('Error retrieving sponsorships: $e');
    }
  }

  // Get a specific sponsorship by ID
  Future<ApiResponse<Sponsorship>> getSponsorship(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$_baseUrl${ApiConstants.getSponsorship}$id'),
        headers: headers,
      );

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
      final response = await http.put(
        Uri.parse('$_baseUrl${ApiConstants.updateSponsorship}$id'),
        headers: headers,
        body: jsonEncode(request.toJson()),
      );

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
      final response = await http.delete(
        Uri.parse('$_baseUrl${ApiConstants.deleteSponsorship}$id'),
        headers: headers,
      );

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
