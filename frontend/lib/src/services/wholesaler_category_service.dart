import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/wholesaler_category.dart';
import '../utils/secure_storage.dart';
import 'api_constant.dart';

class WholesalerCategoryService {
  final SecureStorage _secureStorage = SecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _getFormDataHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

  // Get all wholesaler categories
  Future<WholesalerCategoryListResponse> getAllWholesalerCategories() async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.getAllWholesalerCategories);
      final response = await http.get(uri);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return WholesalerCategoryListResponse.fromJson(responseData);
      } else {
        return WholesalerCategoryListResponse(
          categories: [],
          message: responseData['message'] ?? 'Failed to load wholesaler categories',
          status: response.statusCode,
        );
      }
    } catch (e) {
      return WholesalerCategoryListResponse(
        categories: [],
        message: 'Exception: $e',
        status: 500,
      );
    }
  }

  // Get wholesaler category by ID
  Future<WholesalerCategoryResponse> getWholesalerCategory(String id) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getWholesalerCategory}/$id');
      final response = await http.get(uri);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return WholesalerCategoryResponse.fromJson(responseData);
      } else {
        return WholesalerCategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to load wholesaler category',
          status: response.statusCode,
        );
      }
    } catch (e) {
      return WholesalerCategoryResponse(
        category: null,
        message: 'Exception: $e',
        status: 500,
      );
    }
  }

  // Create new wholesaler category
  Future<WholesalerCategoryResponse> createWholesalerCategory(WholesalerCategory category) async {
    try {
      final headers = await _getFormDataHeaders();
      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.createWholesalerCategory);

      // Create form data
      final categoryData = {
        'name': category.name,
        if (category.subcategories.isNotEmpty) 'subcategories': category.subcategories.join(','),
      };

      // Convert to form data format
      final formDataBody = categoryData.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');

      // Set content type to form data
      final formDataHeaders = Map<String, String>.from(headers);
      formDataHeaders['Content-Type'] = 'application/x-www-form-urlencoded';

      final response = await http.post(
        uri,
        headers: formDataHeaders,
        body: formDataBody,
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return WholesalerCategoryResponse.fromJson(responseData);
      } else {
        return WholesalerCategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to create wholesaler category',
          status: response.statusCode,
        );
      }
    } catch (e) {
      return WholesalerCategoryResponse(
        category: null,
        message: 'Exception: $e',
        status: 500,
      );
    }
  }

  // Update existing wholesaler category
  Future<WholesalerCategoryResponse> updateWholesalerCategory(String id, Map<String, dynamic> updateData) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateWholesalerCategory}/$id');

      final response = await http.put(
        uri,
        headers: headers,
        body: json.encode(updateData),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return WholesalerCategoryResponse.fromJson(responseData);
      } else {
        return WholesalerCategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to update wholesaler category',
          status: response.statusCode,
        );
      }
    } catch (e) {
      return WholesalerCategoryResponse(
        category: null,
        message: 'Exception: $e',
        status: 500,
      );
    }
  }

  // Delete wholesaler category
  Future<WholesalerCategoryResponse> deleteWholesalerCategory(String id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteWholesalerCategory}/$id');

      final response = await http.delete(uri, headers: headers);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return WholesalerCategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Wholesaler category deleted successfully',
          status: response.statusCode,
        );
      } else {
        return WholesalerCategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to delete wholesaler category',
          status: response.statusCode,
        );
      }
    } catch (e) {
      return WholesalerCategoryResponse(
        category: null,
        message: 'Exception: $e',
        status: 500,
      );
    }
  }
}
