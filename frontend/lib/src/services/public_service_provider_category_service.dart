import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/service_provider_category.dart';
import 'api_constant.dart';

class PublicServiceProviderCategoryService {
  // Get all service provider categories (public endpoint - no auth required)
  Future<ServiceProviderCategoryListResponse> getAllServiceProviderCategories() async {
    try {
      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.getAllServiceProviderCategories);
      final response = await http.get(uri);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ServiceProviderCategoryListResponse.fromJson(responseData);
      } else {
        return ServiceProviderCategoryListResponse(
          categories: [],
          message: responseData['message'] ?? 'Failed to load service provider categories',
          status: response.statusCode,
        );
      }
    } catch (e) {
      return ServiceProviderCategoryListResponse(
        categories: [],
        message: 'Exception: $e',
        status: 500,
      );
    }
  }

  // Get service provider category by ID (public endpoint - no auth required)
  Future<ServiceProviderCategoryResponse> getServiceProviderCategory(String id) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getServiceProviderCategory}/$id');
      final response = await http.get(uri);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ServiceProviderCategoryResponse.fromJson(responseData);
      } else {
        return ServiceProviderCategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to load service provider category',
          status: response.statusCode,
        );
      }
    } catch (e) {
      return ServiceProviderCategoryResponse(
        category: null,
        message: 'Exception: $e',
        status: 500,
      );
    }
  }

  // Get service provider categories for dropdown/selection (public endpoint)
  Future<List<ServiceProviderCategory>> getCategoriesForSelection() async {
    try {
      final response = await getAllServiceProviderCategories();
      if (response.status == 200) {
        return response.categories;
      }
      return [];
    } catch (e) {
      print('Error getting categories for selection: $e');
      return [];
    }
  }

  // Get category names for simple text display (public endpoint)
  Future<List<String>> getCategoryNames() async {
    try {
      final categories = await getCategoriesForSelection();
      return categories.map((cat) => cat.name).toList();
    } catch (e) {
      print('Error getting category names: $e');
      return [];
    }
  }
}
