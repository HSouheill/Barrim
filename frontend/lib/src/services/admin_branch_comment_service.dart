import 'dart:convert';
import 'api_constant.dart';
import 'api_services.dart';

class AdminBranchCommentService {
  final String baseUrl;

  AdminBranchCommentService({required this.baseUrl});

  String get secureBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl;
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'https://');
    }
    return 'https://$baseUrl';
  }

  // Get all branch comments for admin with pagination and filtering
  Future<Map<String, dynamic>> getAllBranchCommentsForAdmin({
    int page = 1,
    int limit = 20,
    String? branchType, // "company", "wholesaler", or null for all
    String? hasReply, // "true", "false", or null for all
    int? rating, // 1-5 or null for all
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (branchType != null && branchType.isNotEmpty) {
        queryParams['branchType'] = branchType;
      }
      if (hasReply != null && hasReply.isNotEmpty) {
        queryParams['hasReply'] = hasReply;
      }
      if (rating != null) {
        queryParams['rating'] = rating.toString();
      }

      final uri = Uri.parse('$secureBaseUrl${ApiConstants.getAllBranchCommentsForAdmin}')
          .replace(queryParameters: queryParams);

      print('Making branch comments request to: $uri');

      final response = await ApiService.makeAuthenticatedRequest(
        'get',
        uri.toString(),
      );

      print('Branch comments response status: ${response.statusCode}');
      print('Branch comments response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final commentsData = responseData['data'];
        
        // Return the enriched structure as-is so UI can access all details
        return {
          'success': true,
          'message': responseData['message'],
          'data': commentsData, // Pass through enriched comments structure
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
          'message': responseData['message'] ?? 'Failed to fetch branch comments',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching branch comments: $e',
      };
    }
  }

  // Delete a branch comment
  Future<Map<String, dynamic>> deleteBranchComment(String commentId) async {
    try {
      final uri = Uri.parse('$secureBaseUrl${ApiConstants.deleteBranchComment}/$commentId');

      final response = await ApiService.makeAuthenticatedRequest(
        'delete',
        uri.toString(),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
          'data': responseData['data'],
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
      } else if (response.statusCode == 404) {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Comment not found',
          'statusCode': response.statusCode,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to delete branch comment',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting branch comment: $e',
      };
    }
  }
}

