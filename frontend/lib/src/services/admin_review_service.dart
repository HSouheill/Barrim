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

      final headers = await _getHeaders();
      print('Making review request to: $uri');
      print('Review headers: $headers');

      final response = await http.get(
        uri,
        headers: headers,
      );

      print('Review response status: ${response.statusCode}');
      print('Review response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final reviewsData = responseData['data'];
        final enrichedReviews = reviewsData['reviews'] as List;
        
        // Convert enriched reviews to Review objects
        final reviews = enrichedReviews.map((enrichedReview) {
          final reviewData = enrichedReview['review'] as Map<String, dynamic>;
          final userData = enrichedReview['user'] as Map<String, dynamic>;
          final serviceProviderData = enrichedReview['serviceProvider'] as Map<String, dynamic>;
          
          // Merge the data for the Review.fromJson method
          final reviewJson = Map<String, dynamic>.from(reviewData);
          reviewJson['userName'] = userData['fullName'];
          reviewJson['serviceProviderName'] = serviceProviderData['fullName'];
          
          return Review.fromJson(reviewJson);
        }).toList();

        return {
          'success': true,
          'message': responseData['message'],
          'data': {
            'reviews': reviews,
            'pagination': reviewsData['pagination'],
          },
        };
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Access denied: Admin privileges required',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized: Please log in',
          'statusCode': response.statusCode,
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
      } else if (response.statusCode == 403) {
        return {
          'success': false,
          'message': 'Access denied: Admin privileges required',
          'statusCode': response.statusCode,
        };
      } else if (response.statusCode == 401) {
        return {
          'success': false,
          'message': 'Unauthorized: Please log in',
          'statusCode': response.statusCode,
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
