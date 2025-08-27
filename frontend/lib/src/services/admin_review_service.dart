import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/review_model.dart';
import '../utils/auth_manager.dart';
import '../utils/secure_storage.dart';
import 'api_constant.dart';

class AdminReviewService {
  final String baseUrl;
  final SecureStorage _secureStorage = SecureStorage();
  final AuthManager _authManager = AuthManager();

  AdminReviewService({required this.baseUrl});

  String get secureBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl;
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'https://');
    }
    return 'https://$baseUrl';
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Get all reviews for admin with pagination and filtering
  Future<Map<String, dynamic>> getAllReviewsForAdmin({
    int page = 1,
    int limit = 20,
    String? serviceProviderId,
    int? rating,
    bool? verified,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (serviceProviderId != null && serviceProviderId.isNotEmpty) {
        queryParams['serviceProviderId'] = serviceProviderId;
      }
      if (rating != null) {
        queryParams['rating'] = rating.toString();
      }
      if (verified != null) {
        queryParams['verified'] = verified.toString();
      }

      final uri = Uri.parse('$secureBaseUrl${ApiConstants.getAllReviewsForAdmin}')
          .replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: await _getHeaders(),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final reviewsData = responseData['data'];
        final reviews = (reviewsData['reviews'] as List)
            .map((json) => Review.fromJson(json))
            .toList();

        return {
          'success': true,
          'message': responseData['message'],
          'data': {
            'reviews': reviews,
            'pagination': reviewsData['pagination'],
          },
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to fetch reviews',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching reviews: $e',
      };
    }
  }

  // Delete a review
  Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    try {
      final uri = Uri.parse('$secureBaseUrl${ApiConstants.deleteReview}/$reviewId');

      final response = await http.delete(
        uri,
        headers: await _getHeaders(),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete review',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting review: $e',
      };
    }
  }
}
