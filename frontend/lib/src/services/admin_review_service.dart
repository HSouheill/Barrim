import 'dart:convert';
import 'api_constant.dart';
import 'api_services.dart';

class AdminReviewService {
  final String baseUrl;

  AdminReviewService({required this.baseUrl});

  String get secureBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl;
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'https://');
    }
    return 'https://$baseUrl';
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

      print('Making review request to: $uri');

      final response = await ApiService.makeAuthenticatedRequest(
        'get',
        uri.toString(),
      );

      print('Review response status: ${response.statusCode}');
      print('Review response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final reviewsData = responseData['data'];
        final enrichedReviews = reviewsData['reviews'] as List;
        
        // Convert enriched reviews to JSON format for UI consumption
        final reviewsJson = enrichedReviews.map((enrichedReview) {
          final reviewData = enrichedReview['review'] as Map<String, dynamic>;
          final userData = enrichedReview['user'] as Map<String, dynamic>;
          final serviceProviderData = enrichedReview['serviceProvider'] as Map<String, dynamic>;
          
          // Merge the data for the Review.fromJson method
          final reviewJson = Map<String, dynamic>.from(reviewData);
          reviewJson['userName'] = userData['fullName'];
          reviewJson['serviceProviderName'] = serviceProviderData['fullName'];
          
          return reviewJson;
        }).toList();

        return {
          'success': true,
          'message': responseData['message'],
          'data': {
            'reviews': reviewsJson,
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

      final response = await ApiService.makeAuthenticatedRequest(
        'delete',
        uri.toString(),
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
