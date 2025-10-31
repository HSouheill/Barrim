import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/service_provider_category.dart';
import '../utils/secure_storage.dart';
import 'api_constant.dart';

class ServiceProviderCategoryService {
  final SecureStorage _secureStorage = SecureStorage();

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token',
    };
  }

  Future<Map<String, String>> _getMultipartHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Authorization': 'Bearer $token',
    };
  }

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

  // Create new service provider category (admin only)
  Future<ServiceProviderCategoryResponse> createServiceProviderCategory(
    String name, {
    File? imageFile,
  }) async {
    try {
      final headers = await _getMultipartHeaders();
      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.createServiceProviderCategory);

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      print('Create Service Provider Category Request Headers: ${request.headers}');
      print('Create Service Provider Category Request URI: $uri');

      // Add category name
      request.fields['name'] = name;

      // Add image file if provided
      if (imageFile != null) {
        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();
        
        final multipartFile = http.MultipartFile(
          'image',
          fileStream,
          fileLength,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'), // Adjust based on file type
        );
        
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Create Service Provider Category Response Status: ${response.statusCode}');
      print('Create Service Provider Category Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return ServiceProviderCategoryResponse.fromJson(responseData);
      } else {
        return ServiceProviderCategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to create service provider category',
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

  // Update existing service provider category (admin only)
  Future<ServiceProviderCategoryResponse> updateServiceProviderCategory(
    String id,
    Map<String, dynamic> updateData, {
    File? imageFile,
  }) async {
    try {
      final headers = await _getMultipartHeaders();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateServiceProviderCategory}/$id');

      // Create multipart request for PUT with image
      final request = http.MultipartRequest('PUT', uri);
      request.headers.addAll(headers);

      print('Update Service Provider Category Request Headers: ${request.headers}');
      print('Update Service Provider Category Request URI: $uri');
      print('Update Service Provider Category Request Data: $updateData');

      // Add text fields
      if (updateData['name'] != null) {
        request.fields['name'] = updateData['name'];
      }

      // Add image file if provided
      if (imageFile != null) {
        final fileStream = http.ByteStream(imageFile.openRead());
        final fileLength = await imageFile.length();
        
        final multipartFile = http.MultipartFile(
          'image',
          fileStream,
          fileLength,
          filename: imageFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'), // Adjust based on file type
        );
        
        request.files.add(multipartFile);
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Update Service Provider Category Response Status: ${response.statusCode}');
      print('Update Service Provider Category Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ServiceProviderCategoryResponse.fromJson(responseData);
      } else {
        return ServiceProviderCategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to update service provider category',
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

  // Delete service provider category (admin only)
  Future<ServiceProviderCategoryResponse> deleteServiceProviderCategory(String id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteServiceProviderCategory}/$id');

      final response = await http.delete(uri, headers: headers);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return ServiceProviderCategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Service provider category deleted successfully',
          status: response.statusCode,
        );
      } else {
        return ServiceProviderCategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to delete service provider category',
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
}
