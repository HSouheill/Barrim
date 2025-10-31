import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' as foundation;
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/category.dart';
import '../utils/secure_storage.dart';
import 'api_constant.dart';

class CategoryApiService {
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

  // Get all categories (admin endpoint)
  Future<CategoryListResponse> getAllCategories() async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.getAllCategories);
      
      print('=== getAllCategories Debug Info ===');
      print('Request URI: $uri');
      print('Request Headers: $headers');
      
      final response = await http.get(uri, headers: headers);

      print('Response Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Raw Response Body: ${response.body}');

      final responseData = json.decode(response.body);
      print('Parsed Response Data: $responseData');

      if (response.statusCode == 200) {
        final result = CategoryListResponse.fromJson(responseData);
        print('=== Parsed CategoryListResponse ===');
        print('Status: ${result.status}');
        print('Message: ${result.message}');
        print('Categories Count: ${result.categories.length}');
        for (int i = 0; i < result.categories.length; i++) {
          final category = result.categories[i];
          print('Category $i:');
          print('  ID: ${category.id}');
          print('  Name: ${category.name}');
          print('  Description: ${category.description}');
          print('  Subcategories: ${category.subcategories}');
          print('  Logo: ${category.logo}');
          print('  Background Color: ${category.backgroundColor}');
          print('  Created At: ${category.createdAt}');
          print('  Updated At: ${category.updatedAt}');
        }
        print('=== End Debug Info ===');
        return result;
      } else {
        print('Error Response: Status ${response.statusCode}, Message: ${responseData['message'] ?? 'No message'}');
        final errorResult = CategoryListResponse(
          categories: [],
          message: responseData['message'] ?? 'Failed to load categories',
          status: response.statusCode,
        );
        print('=== Error CategoryListResponse ===');
        print('Status: ${errorResult.status}');
        print('Message: ${errorResult.message}');
        print('Categories Count: ${errorResult.categories.length}');
        print('=== End Debug Info ===');
        return errorResult;
      }
    } catch (e) {
      print('Exception in getAllCategories: $e');
      final exceptionResult = CategoryListResponse(
        categories: [],
        message: 'Exception: $e',
        status: 500,
      );
      print('=== Exception CategoryListResponse ===');
      print('Status: ${exceptionResult.status}');
      print('Message: ${exceptionResult.message}');
      print('Categories Count: ${exceptionResult.categories.length}');
      print('=== End Debug Info ===');
      return exceptionResult;
    }
  }

  // Get category by ID (admin endpoint)
  Future<CategoryResponse> getCategory(String id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getCategory}/$id');
      final response = await http.get(uri, headers: headers);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return CategoryResponse.fromJson(responseData);
      } else {
        return CategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to load categories',
          status: response.statusCode,
        );
      }
    } catch (e) {
      return CategoryResponse(
        category: null,
        message: 'Exception: $e',
        status: 500,
      );
    }
  }

    // Create new category (admin only) - NO logo upload during creation
  Future<CategoryResponse> createCategory(Category category) async {
    try {
      final headers = await _getHeaders(); // Use form data headers for category creation
      final uri = Uri.parse(ApiConstants.baseUrl + ApiConstants.createCategory);

      print('Create Category Request Headers: ${headers}');
      print('Create Category Request URI: $uri');
      print('Base URL: ${ApiConstants.baseUrl}');
      print('Create Category Endpoint: ${ApiConstants.createCategory}');

      // Create category without logo - logo will be uploaded separately
      final categoryData = {
        'name': category.name,
        if (category.subcategories.isNotEmpty) 'subcategories': category.subcategories.join(','), // Send as comma-separated string for form data
        if (category.description != null && category.description!.isNotEmpty) 'description': category.description!,
        if (category.backgroundColor.isNotEmpty) 'color': category.backgroundColor, // Send color field to backend
      };

      // Validate that name is not empty before sending
      if (category.name.trim().isEmpty) {
        print('ERROR: Category name is empty!');
        return CategoryResponse(
          category: null,
          message: 'Category name cannot be empty',
          status: 400,
        );
      }

      print('Category data being sent: $categoryData');
      print('Category name value: "${category.name}"');
      print('Category name length: ${category.name.length}');
      print('Category name is empty: ${category.name.isEmpty}');
      print('Category name trimmed: "${category.name.trim()}"');

      // Convert to form data format
      final formDataBody = categoryData.entries
          .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
          .join('&');
      
      print('Form data body: $formDataBody');

      // Set content type to form data
      final formDataHeaders = Map<String, String>.from(headers);
      formDataHeaders['Content-Type'] = 'application/x-www-form-urlencoded';
      print('Form data headers: $formDataHeaders');

      final response = await http.post(
        uri,
        headers: formDataHeaders,
        body: formDataBody,
      );

      print('Sending request...');
      print('Create Category Response Status: ${response.statusCode}');
      print('Create Category Response Body: ${response.body}');
      print('Response headers: ${response.headers}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        return CategoryResponse.fromJson(responseData);
      } else {
        return CategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to create category',
          status: response.statusCode,
        );
      }
    } catch (e) {
      print('Exception in createCategory: $e');
      return CategoryResponse(
        category: null,
        message: 'Exception: $e',
        status: 500,
      );
    }
  }

  // Update existing category (admin only)
  Future<CategoryResponse> updateCategory(String id, Map<String, dynamic> updateData, {dynamic logoFile}) async {
    try {
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.updateCategory}/$id');

      // If a logo file is provided, use multipart/form-data in a single request
      if (logoFile != null) {
        final authHeaders = await _getMultipartHeaders();
        final request = http.MultipartRequest('PUT', uri);
        request.headers.addAll(authHeaders);

        // Map frontend fields to backend form fields
        final backendUpdateData = Map<String, dynamic>.from(updateData);
        if (backendUpdateData.containsKey('backgroundColor')) {
          backendUpdateData['color'] = backendUpdateData.remove('backgroundColor');
        }
        // Encode subcategories list as comma-separated
        if (backendUpdateData['subcategories'] is List) {
          backendUpdateData['subcategories'] = (backendUpdateData['subcategories'] as List)
              .where((e) => e != null)
              .map((e) => e.toString().trim())
              .where((e) => e.isNotEmpty)
              .join(',');
        }
        backendUpdateData.remove('logo');

        backendUpdateData.forEach((key, value) {
          if (value != null) request.fields[key] = value.toString();
        });

        // Prepare multipart file (supports File and XFile)
        String fileName;
        int fileLength;
        Stream<List<int>> fileStream;

        if (foundation.kIsWeb && logoFile is XFile) {
          fileName = logoFile.name.isEmpty ? 'image.jpg' : logoFile.name;
          fileLength = await logoFile.length();
          fileStream = logoFile.openRead();
        } else if (logoFile is File) {
          fileName = logoFile.path.split('/').last;
          fileLength = await logoFile.length();
          fileStream = logoFile.openRead();
        } else {
          throw Exception('Unsupported file type for update: ${logoFile.runtimeType}');
        }

        // Infer mime from extension
        final extension = fileName.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg';
        if (extension == 'png') mimeType = 'image/png';
        else if (extension == 'gif') mimeType = 'image/gif';
        else if (extension == 'webp') mimeType = 'image/webp';
        else if (extension == 'svg') mimeType = 'image/svg+xml';

        final multipartFile = http.MultipartFile(
          'logo',
          http.ByteStream(fileStream),
          fileLength,
          filename: fileName,
          contentType: MediaType.parse(mimeType),
        );
        request.files.add(multipartFile);

        final streamed = await request.send();
        final response = await http.Response.fromStream(streamed);
        final responseData = json.decode(response.body);
        print('Update Category (multipart) Status: ${response.statusCode}');
        print('Update Category (multipart) Body: ${response.body}');

        if (response.statusCode == 200) {
          return CategoryResponse.fromJson(responseData);
        }
        return CategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to update category',
          status: response.statusCode,
        );
      }

      // Otherwise, fallback to JSON update
      final backendUpdateData = Map<String, dynamic>.from(updateData);
      if (backendUpdateData.containsKey('backgroundColor')) {
        backendUpdateData['color'] = backendUpdateData.remove('backgroundColor');
      }
      final headers = await _getHeaders();
      print('Update Category Request URI: $uri');
      final response = await http.put(uri, headers: headers, body: json.encode(backendUpdateData));
      print('Update Category Response Status: ${response.statusCode}');
      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        return CategoryResponse.fromJson(responseData);
      }
      return CategoryResponse(
        category: null,
        message: responseData['message'] ?? 'Failed to update category',
        status: response.statusCode,
      );
    } catch (e) {
      return CategoryResponse(
        category: null,
        message: 'Exception: $e',
        status: 500,
      );
    }
  }

  // Delete category (admin only)
  Future<CategoryResponse> deleteCategory(String id) async {
    try {
      final headers = await _getHeaders();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.deleteCategory}/$id');

      final response = await http.delete(uri, headers: headers);

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return CategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Category deleted successfully',
          status: response.statusCode,
        );
      } else {
        return CategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to delete category',
          status: response.statusCode,
        );
      }
    } catch (e) {
      return CategoryResponse(
        category: null,
        message: 'Exception: $e',
        status: 500,
      );
    }
  }

  // Upload category logo (admin only) - using dedicated endpoint
  Future<CategoryResponse> uploadCategoryLogo(String id, dynamic logoFile) async {
    try {
      final headers = await _getMultipartHeaders();
      final uri = Uri.parse('${ApiConstants.baseUrl}${ApiConstants.uploadCategoryLogo}/$id/logo');

      print('Upload Logo Request Headers: ${headers}');
      print('Upload Logo Request URI: $uri');

      // Create multipart request
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(headers);

      // Validate and add the logo file
      try {
        String fileName;
        int fileLength;
        Stream<List<int>> fileStream;
        List<int>? overrideBytes; // optional override payload
        String? overrideFileName;
        String? overrideMimeType;
        
        if (foundation.kIsWeb && logoFile is XFile) {
          // Web environment - handle XFile
          fileName = logoFile.name;
          if (fileName.isEmpty) {
            fileName = 'image.jpg';
          }
          fileLength = await logoFile.length();
          fileStream = logoFile.openRead();
          // No client-side conversion; rely on backend content-type validation
        } else if (logoFile is File) {
          // Mobile environment - handle File
          fileName = logoFile.path.split('/').last;
          fileLength = await logoFile.length();
          fileStream = logoFile.openRead();
          // No client-side conversion; rely on backend content-type validation
        } else {
          throw Exception('Unsupported file type: ${logoFile.runtimeType}');
        }
        
        // Validate file size (max 5MB)
        if (fileLength > 5 * 1024 * 1024) {
          throw Exception('File size exceeds 5MB limit');
        }
        
        // Determine content type based on file extension
        final extension = (overrideFileName ?? fileName).split('.').last.toLowerCase();
        String mimeType = overrideMimeType ?? 'image/jpeg';
        if (overrideMimeType == null) {
          if (extension == 'png') mimeType = 'image/png';
          else if (extension == 'gif') mimeType = 'image/gif';
          else if (extension == 'webp') mimeType = 'image/webp';
          else if (extension == 'svg') mimeType = 'image/svg+xml';
        }
        
        // Validate file extension
        if (!['jpg', 'jpeg', 'png', 'gif', 'webp', 'svg'].contains(extension)) {
          throw Exception('Invalid image format. Supported: JPG, PNG, GIF, WebP, SVG');
        }
        
        // Create multipart file
        final multipartFile = overrideBytes != null
            ? http.MultipartFile.fromBytes(
                'logo',
                overrideBytes,
                filename: overrideFileName ?? 'image.png',
                contentType: MediaType.parse(mimeType),
              )
            : http.MultipartFile(
                'logo',
                http.ByteStream(fileStream),
                fileLength,
                filename: fileName,
                contentType: MediaType.parse(mimeType),
              );
        
        request.files.add(multipartFile);
        print('Logo file added: ${(overrideFileName ?? fileName)}, size: $fileLength, type: $mimeType');
        
      } catch (e) {
        print('Error preparing logo file: $e');
        throw Exception('Failed to prepare logo file: $e');
      }

      print('Sending logo upload request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Logo Upload Response Status: ${response.statusCode}');
      print('Logo Upload Response Body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return CategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Logo uploaded successfully',
          status: response.statusCode,
        );
      } else {
        return CategoryResponse(
          category: null,
          message: responseData['message'] ?? 'Failed to upload logo',
          status: response.statusCode,
        );
      }
    } catch (e) {
      return CategoryResponse(
        category: null,
        message: 'Exception: $e',
        status: 500,
      );
    }
  }
}
