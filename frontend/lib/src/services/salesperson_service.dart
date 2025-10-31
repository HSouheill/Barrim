import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../utils/secure_storage.dart';
import '../models/salesperson_model.dart';
import '../models/company_model.dart';
import '../models/withdrawal_model.dart';
import 'api_constant.dart';
import 'app_exception.dart';
import 'api_services.dart';

class SalespersonService {
  final String baseUrl;
  final ApiService _apiService = ApiService();

  SalespersonService({required this.baseUrl});

  // Add secure base URL getter
  String get secureBaseUrl {
    String url = baseUrl.trim();
    if (url.startsWith('https://')) {
      return url;
    }
    // Remove http:// if present
    url = url.replaceFirst(RegExp(r'^http://'), '');
    // Remove any leading/trailing slashes
    url = url.replaceAll(RegExp(r'^/+|/+$'), '');
    return 'https://$url';
  }

  // Helper method to ensure HTTPS URLs
  String _ensureHttps(String url) {
    if (url.startsWith('https://')) {
      return url;
    }
    return url.replaceFirst(RegExp(r'^(http://|)'), 'https://');
  }

  // Helper method to make secure HTTP requests
  Future<http.Response> _makeSecureRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$secureBaseUrl$endpoint');
    final requestHeaders = headers ?? await _getHeaders();

    switch (method.toLowerCase()) {
      case 'get':
        return await http.get(uri, headers: requestHeaders);
      case 'post':
        return await http.post(uri, headers: requestHeaders, body: body);
      case 'put':
        return await http.put(uri, headers: requestHeaders, body: body);
      case 'delete':
        return await http.delete(uri, headers: requestHeaders, body: body);
      default:
        throw UnsupportedError('HTTP method not supported: $method');
    }
  }

  // Get auth token from secure storage
  Future<String?> _getToken() async {
    return await ApiService.getToken();
  }

  Future<Map<String, String>> _getHeaders() async {
    try {
      final token = await _getToken();
      if (token == null) {
        print('No token found in _getHeaders');
        throw Exception('No authentication token found');
      }

      // Debug logging
      print('=== API REQUEST HEADERS ===');
      print('Token: ${token.substring(0, 20)}...');

      final userInfo = await ApiService.getUserInfo();
      if (userInfo != null) {
        print('User Type: ${userInfo.type}');
        print('User Role: ${userInfo.role}');
        print('User Email: ${userInfo.email}');
      } else {
        print('No user info found');
      }

      return {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
        'User-Type': userInfo?.type ?? '',
        'User-Role': userInfo?.role ?? '',
      };
    } catch (e) {
      print('Error in _getHeaders: $e');
      rethrow;
    }
  }

  // Handle API errors
  void _handleError(http.Response response) {
    switch (response.statusCode) {
      case 400:
        throw BadRequestException(response.body);
      case 401:
      case 403:
        throw UnauthorizedException(response.body);
      case 404:
        throw NotFoundException(response.body);
      case 500:
      default:
        throw FetchDataException('Error occurred with status: ${response.statusCode}');
    }
  }

  // Salesperson login
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _makeSecureRequest(
        'post',
        '/api/admin/login',
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Handle specific login error cases
        if (response.statusCode == 401) {
          throw Exception('Incorrect email or password. Please try again.');
        } else if (response.statusCode == 400) {
          throw Exception('Invalid login data. Please check your email and password.');
        } else if (response.statusCode >= 500) {
          throw Exception('Server error. Please try again later.');
        } else {
          _handleError(response);
        }
      }
    } catch (e) {
      // Re-throw with user-friendly message if it's already formatted
      if (e.toString().contains('Incorrect email or password') ||
          e.toString().contains('Invalid login data') ||
          e.toString().contains('Server error')) {
        rethrow;
      }
      
      // Handle other exceptions with user-friendly messages
      if (e.toString().toLowerCase().contains('stream') ||
          e.toString().toLowerCase().contains('addstream')) {
        throw Exception('Incorrect email or password. Please try again.');
      } else if (e.toString().toLowerCase().contains('network') ||
                 e.toString().toLowerCase().contains('connection')) {
        throw Exception('Network error. Please check your internet connection.');
      } else if (e.toString().toLowerCase().contains('timeout')) {
        throw Exception('Login timeout. Please try again.');
      }
      
      rethrow;
    }
    throw Exception('Unknown error occurred during login');
  }

  // Create a new company
  Future<Company> createCompany({
    required String businessName,
    required String category,
    String? subcategory,
    String email = '',
    required String phone,
    required String password,
    required String contactPerson,
    required String contactPhone,
    required String country,
    required String district,
    required String city,
    required String governorate,
    double? lat,
    double? lng,
    File? logoFile,
  }) async {
    try {
      final fields = {
        'businessName': businessName.trim(),
        'category': category.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'contactPerson': contactPerson.trim(),
        'contactPhone': contactPhone.trim(),
        'country': country.trim(),
        'district': district.trim(),
        'city': city.trim(),
        'governorate': governorate.trim(),
        'userType': 'company',
      };

      // Add subcategory if provided
      if (subcategory != null && subcategory.isNotEmpty) {
        fields['subcategory'] = subcategory.trim();
      }

      // Add lat and lng if provided
      if (lat != null) {
        fields['lat'] = lat.toString();
      }
      if (lng != null) {
        fields['lng'] = lng.toString();
      }

      // Validate required fields (email is optional)
      for (final entry in fields.entries) {
        if (entry.value.isEmpty && !entry.key.startsWith('lat') && entry.key != 'email') {
          throw Exception('${entry.key} is required');
        }
      }

      final request = await _createSecureMultipartRequest(
        'POST',
        '/api/sales-person/companies',
        fields,
        file: logoFile,
        fileField: 'logo',
      );

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseData);
        if (jsonResponse['data'] != null) {
          return Company.fromJson(jsonResponse['data']);
        }
        throw Exception('Invalid response format: missing data field');
      } else if (response.statusCode == 409) {
        final errorResponse = jsonDecode(responseData);
        throw Exception(errorResponse['message'] ?? 'Email or phone number already exists');
      }
      throw Exception('Failed to create company: ${response.statusCode}');
    } catch (e) {
      if (e is SocketException) {
        throw Exception('Network error: Please check your internet connection');
      } else if (e is TimeoutException) {
        throw Exception('Request timeout: Please try again');
      }
      rethrow;
    }
  }

  // Helper method to create multipart request
  Future<http.MultipartRequest> _createSecureMultipartRequest(
    String method,
    String endpoint,
    Map<String, String> fields, {
    File? file,
    String? fileField,
  }) async {
    final uri = Uri.parse('$secureBaseUrl$endpoint');
    final request = http.MultipartRequest(method, uri);

    // Add headers
    request.headers.addAll(await _getHeaders());

    // Add fields
    request.fields.addAll(fields);

    // Add file if provided
    if (file != null && fileField != null) {
      final fileStream = http.ByteStream(file.openRead());
      final length = await file.length();
      final multipartFile = http.MultipartFile(
        fileField,
        fileStream,
        length,
        filename: file.path.split('/').last,
        contentType: MediaType('image', 'jpeg'),
      );
      request.files.add(multipartFile);
    }

    return request;
  }

  // Get all companies created by the salesperson
  Future<List<Company>> getCompanies() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-person/companies'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> companiesData = jsonResponse['data'] ?? [];
        final companies = <Company>[];
        for (var data in companiesData) {
          if (data != null && data is Map<String, dynamic>) {
            try {
              companies.add(Company.fromJson(data));
            } catch (error) {
              print('Error parsing company: $error');
            }
          }
        }
        return companies;
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching companies');
  }

  // Get raw companies data from API (includes contactPerson and contactPhone)
  Future<List<Map<String, dynamic>>> getRawCompanies() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-person/companies'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> companiesData = jsonResponse['data'] ?? [];
        return companiesData.cast<Map<String, dynamic>>();
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching raw companies data');
  }

  // Get a specific company
  Future<Company> getCompany(String companyId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-person/companies/$companyId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return Company.fromJson(jsonResponse['data']);
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching company');
  }

  // Update a company
  Future<void> updateCompany({
    required String companyId,
    required String businessName,
    required String category,
    required String phone,
    required String contactPhone,
    required String country,
    required String district,
    required String city,
    required String governorate,
    File? logoFile,
  }) async {
    try {
      final headers = await _getHeaders();
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/sales-person/companies/$companyId'),
      );

      // Add headers
      request.headers.addAll(headers);

      // Add text fields
      request.fields['businessName'] = businessName;
      request.fields['category'] = category;
      request.fields['phone'] = phone;
      request.fields['contactPhone'] = contactPhone;
      request.fields['country'] = country;
      request.fields['district'] = district;
      request.fields['city'] = city;
      request.fields['governorate'] = governorate;

      // Add logo file if provided
      if (logoFile != null) {
        final fileStream = http.ByteStream(logoFile.openRead());
        final length = await logoFile.length();
        final multipartFile = http.MultipartFile(
          'logo',
          fileStream,
          length,
          filename: logoFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        _handleError(http.Response(responseData, response.statusCode));
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete a company
  Future<void> deleteCompany(String companyId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/sales-person/companies/$companyId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create a new wholesaler
  Future<Company> createWholesaler({
    required String businessName,
    required String category,
    String? subcategory,
    String email = '',
    required String phone,
    required String password,
    required String contactPerson,
    required String contactPhone,
    required String country,
    required String district,
    required String city,
    required String governorate,
    double? lat,
    double? lng,
    File? logoFile,
  }) async {
    try {
      final headers = await _getHeaders();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/sales-person/wholesalers'),
      );

      // Add headers
      request.headers.addAll(headers);

      // Add text fields
      request.fields['businessName'] = businessName;
      request.fields['category'] = category;
      if (subcategory != null && subcategory.isNotEmpty) {
        request.fields['subcategory'] = subcategory;
      }
      request.fields['email'] = email;
      request.fields['phone'] = phone;
      request.fields['password'] = password;
      request.fields['contactPerson'] = contactPerson;
      request.fields['contactPhone'] = contactPhone;
      request.fields['country'] = country;
      request.fields['district'] = district;
      request.fields['city'] = city;
      request.fields['governorate'] = governorate;
      request.fields['userType'] = 'wholesaler';

      // Add lat and lng if provided
      if (lat != null) {
        request.fields['lat'] = lat.toString();
      }
      if (lng != null) {
        request.fields['lng'] = lng.toString();
      }

      // Add logo file if provided
      if (logoFile != null) {
        try {
          final fileStream = http.ByteStream(logoFile.openRead());
          final length = await logoFile.length();
          final multipartFile = http.MultipartFile(
            'logo',
            fileStream,
            length,
            filename: logoFile.path.split('/').last,
            contentType: MediaType('image', 'jpeg'),
          );
          request.files.add(multipartFile);
        } catch (e) {
           print('Error adding logo file: $e');
        }
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseData);
        return Company.fromJson(jsonResponse['data']);
      } else if (response.statusCode == 409) {
        // Handle duplicate key error
        final errorResponse = jsonDecode(responseData);
        throw Exception(errorResponse['message'] ?? 'Email or phone number already exists');
      } else {
        _handleError(http.Response(responseData, response.statusCode));
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while creating wholesaler');
  }

  // Get all wholesalers created by the salesperson
  Future<List<Company>> getWholesalers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-person/wholesalers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> wholesalersData = jsonResponse['data'] ?? [];
        final wholesalers = <Company>[];
        for (var data in wholesalersData) {
          if (data != null && data is Map<String, dynamic>) {
            try {
              wholesalers.add(Company.fromJson(data));
            } catch (error) {
              print('Error parsing wholesaler: $error');
            }
          }
        }
        return wholesalers;
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching wholesalers');
  }

  // Get raw wholesalers data from API (includes contactPerson and contactPhone)
  Future<List<Map<String, dynamic>>> getRawWholesalers() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-person/wholesalers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final List<dynamic> wholesalersData = jsonResponse['data'] ?? [];
        return wholesalersData.cast<Map<String, dynamic>>();
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching raw wholesalers data');
  }

  // Get a specific wholesaler
  Future<Company> getWholesaler(String wholesalerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-person/wholesalers/$wholesalerId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        return Company.fromJson(jsonResponse['data']);
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching wholesaler');
  }

  // Update a wholesaler
  Future<void> updateWholesaler({
    required String wholesalerId,
    required String businessName,
    required String category,
    required String phone,
    required String contactPhone,
    required String country,
    required String district,
    required String city,
    required String governorate,
    File? logoFile,
  }) async {
    try {
      final headers = await _getHeaders();
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/sales-person/wholesalers/$wholesalerId'),
      );

      // Add headers
      request.headers.addAll(headers);

      // Add text fields
      request.fields['businessName'] = businessName;
      request.fields['category'] = category;
      request.fields['phone'] = phone;
      request.fields['contactPhone'] = contactPhone;
      request.fields['country'] = country;
      request.fields['district'] = district;
      request.fields['city'] = city;
      request.fields['governorate'] = governorate;

      // Add logo file if provided
      if (logoFile != null) {
        final fileStream = http.ByteStream(logoFile.openRead());
        final length = await logoFile.length();
        final multipartFile = http.MultipartFile(
          'logo',
          fileStream,
          length,
          filename: logoFile.path.split('/').last,
          contentType: MediaType('image', 'jpeg'),
        );
        request.files.add(multipartFile);
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode != 200) {
        _handleError(http.Response(responseData, response.statusCode));
      }
    } catch (e) {
      rethrow;
    }
  }

  // Delete a wholesaler
  Future<void> deleteWholesaler(String wholesalerId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/api/sales-person/wholesalers/$wholesalerId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
  }

  // Create a new service provider
  Future<Company> createServiceProvider({
    required String businessName,
    required String category,
    String email = '',
    required String phone,
    required String password,
    required String contactPerson,
    required String contactPhone,
    required String country,
    required String district,
    required String city,
    required String governorate,
    double? lat,
    double? lng,
    File? logoFile,
  }) async {
    try {
      final headers = await _getHeaders();
      print('Creating service provider with headers: $headers');

      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/sales-person/service-providers'),
      );

      // Add headers
      request.headers.addAll(headers);

      // Add text fields with validation
      final fields = {
        'businessName': businessName.trim(),
        'category': category.trim(),
        'email': email.trim(),
        'phone': phone.trim(),
        'password': password,
        'contactPerson': contactPerson.trim(),
        'contactPhone': contactPhone.trim(),
        'country': country.trim(),
        'district': district.trim(),
        'city': city.trim(),
        'governorate': governorate.trim(),
        'userType': 'serviceProvider',
      };

      // Add lat and lng if provided
      if (lat != null) {
        fields['lat'] = lat.toString();
      }
      if (lng != null) {
        fields['lng'] = lng.toString();
      }

      print('Request fields: $fields');

      // Validate required fields (email is optional)
      for (final entry in fields.entries) {
        if (entry.value.isEmpty && !entry.key.startsWith('lat') && entry.key != 'email') {
          throw Exception('${entry.key} is required');
        }
        request.fields[entry.key] = entry.value;
      }

      // Add logo file if provided
      if (logoFile != null) {
        try {
          final fileStream = http.ByteStream(logoFile.openRead());
          final length = await logoFile.length();
          final multipartFile = http.MultipartFile(
            'logo',
            fileStream,
            length,
            filename: logoFile.path.split('/').last,
            contentType: MediaType('image', 'jpeg'),
          );
          request.files.add(multipartFile);
        } catch (e) {
          print('Error adding logo file: $e');
        }
      }

      print('Sending request to: ${request.url}');
      print('Request fields: ${request.fields}');

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      print('Response status: ${response.statusCode}');
      print('Response data: $responseData');

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(responseData);
        if (jsonResponse['data'] != null) {
          return Company.fromJson(jsonResponse['data']);
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else if (response.statusCode == 409) {
        // Handle duplicate key error
        final errorResponse = jsonDecode(responseData);
        throw Exception(errorResponse['message'] ?? 'Email or phone number already exists');
      } else {
        // Parse error response
        try {
          final errorResponse = jsonDecode(responseData);
          throw Exception(errorResponse['message'] ?? 'Unknown error occurred');
        } catch (e) {
          print('Error parsing response: $e');
          print('Raw response data: $responseData');
          throw Exception('Server error: ${response.statusCode} - $responseData');
        }
      }
    } on SocketException {
      throw Exception('Network error: Please check your internet connection');
    } on TimeoutException {
      throw Exception('Request timeout: Please try again');
    } catch (e) {
      print('Error in createServiceProvider: $e');
      if (e.toString().contains('Exception:')) {
        rethrow;
      }
      throw Exception('Failed to create service provider: ${e.toString()}');
    }
  }

  // Get all service providers created by the salesperson
  Future<List<Map<String, dynamic>>> getServiceProviders() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-person/service-providers'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          return (jsonResponse['data'] as List)
              .map((json) => json as Map<String, dynamic>)
              .toList();
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching service providers');
  }

  // Get referral data for the logged-in salesperson
  Future<Map<String, dynamic>> getReferralData() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-person/referral/data'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          return jsonResponse['data'] as Map<String, dynamic>;
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching referral data');
  }

  // Get commission summary for the logged-in user
  Future<Map<String, dynamic>> getCommissionSummary() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/commission/summary'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          
          final result = {
            'totalCommission': (data['totalCommission'] ?? 0).toDouble(),
            'totalWithdrawn': (data['totalWithdrawn'] ?? 0).toDouble(),
            'availableBalance': (data['availableBalance'] ?? 0).toDouble(),
          };
          
          return result;
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching commission summary');
  }

  // Request commission withdrawal
  Future<Map<String, dynamic>> requestCommissionWithdrawal(double amount) async {
    try {
      final headers = await _getHeaders();
      
      // Validate amount
      if (amount <= 0) {
        throw Exception('Invalid withdrawal amount');
      }
      
      final requestBody = {
        'amount': amount,
        'requestedAt': DateTime.now().toIso8601String(),
      };
      
      print('Requesting withdrawal: $requestBody');
      
      final response = await http.post(
        Uri.parse('$baseUrl/api/commission/withdraw'),
        headers: headers,
        body: jsonEncode(requestBody),
      );
      
      print('Withdrawal response status: ${response.statusCode}');
      print('Withdrawal response body: ${response.body}');
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        
        // Handle different response formats
        String? withdrawalId;
        String status = 'pending';
        
        if (jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          withdrawalId = data['withdrawalId'] ?? data['id'] ?? data['withdrawal_id'];
          status = data['status'] ?? 'pending';
        }
        
        // Return success response with additional details
        return {
          'success': true,
          'message': jsonResponse['message'] ?? 'Withdrawal request submitted successfully',
          'withdrawalId': withdrawalId,
          'amount': amount,
          'status': status,
          'requestedAt': DateTime.now().toIso8601String(),
          'responseData': jsonResponse, // Include full response for debugging
        };
      } else {
        final jsonResponse = jsonDecode(response.body);
        final errorMessage = jsonResponse['message'] ?? 
                           jsonResponse['error'] ?? 
                           'Failed to request withdrawal (Status: ${response.statusCode})';
        throw Exception(errorMessage);
      }
    } catch (e) {
      print('Withdrawal request error: $e');
      rethrow;
    }
  }

  // Get commission and withdrawal history for the logged-in user
  Future<Map<String, dynamic>> getCommissionAndWithdrawalHistory() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/api/sales-person/commission-withdrawal-history'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        
        if (jsonResponse['data'] != null) {
          final data = jsonResponse['data'];
          
          // Parse commissions
          List<Commission> commissions = [];
          if (data['commissions'] != null) {
            commissions = (data['commissions'] as List)
                .map((item) => Commission.fromJson(item))
                .toList();
          }
          
          // Parse withdrawals
          List<Withdrawal> withdrawals = [];
          if (data['withdrawals'] != null) {
            withdrawals = (data['withdrawals'] as List)
                .map((item) => Withdrawal.fromJson(item))
                .toList();
          }
          
          return {
            'commissions': commissions,
            'withdrawals': withdrawals,
          };
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching commission/withdrawal history');
  }

  Future<Map<String, dynamic>> checkEmailOrPhoneExistsDetailed(String? email, String? phone) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$secureBaseUrl/api/auth/check-exists'),
        headers: headers,
        body: jsonEncode({
          'email': email ?? '',
          'phone': phone ?? '',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final responseData = data['data'] as Map<String, dynamic>?;
        
        if (responseData != null) {
          return {
            'userExists': responseData['userExists'] ?? false,
            'companyExists': responseData['companyExists'] ?? false,
            'wholesalerExists': responseData['wholesalerExists'] ?? false,
            'serviceProviderExists': responseData['serviceProviderExists'] ?? false,
            'exists': responseData['exists'] ?? false,
          };
        }
        
        // Fallback to the old format
        return {
          'userExists': false,
          'companyExists': false,
          'wholesalerExists': false,
          'serviceProviderExists': false,
          'exists': data['data']['exists'] ?? false,
        };
      }
      return {
        'userExists': false,
        'companyExists': false,
        'wholesalerExists': false,
        'serviceProviderExists': false,
        'exists': false,
      };
    } catch (e) {
      print('Error checking email/phone existence: $e');
      return {
        'userExists': false,
        'companyExists': false,
        'wholesalerExists': false,
        'serviceProviderExists': false,
        'exists': false,
      };
    }
  }

  Future<bool> checkEmailOrPhoneExists(String? email, String? phone) async {
    // Call the static method from ApiService
    return await ApiService.checkEmailOrPhoneExists(email, phone);
  }

  // Create a new salesperson
  Future<Salesperson> createSalesperson({
    required String fullName,
    required String email,
    required String password,
    required String phoneNumber,
    required double commissionPercent,
    String? region,
    String? salesManagerId,
  }) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$secureBaseUrl/api/admin/salespersons'),
        headers: headers,
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'phoneNumber': phoneNumber,
          'commissionPercent': commissionPercent,
          'region': region,
          'salesManagerId': salesManagerId,
        }),
      );

      if (response.statusCode == 201) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          return Salesperson.fromJson(jsonResponse['data']);
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while creating salesperson');
  }

  // Get all salespersons
  Future<List<Salesperson>> GetAdminSalespersons() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$secureBaseUrl/api/admin/salespersons'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          final List<dynamic> data = jsonResponse['data'];
          return data.map((item) => Salesperson.fromJson(item)).toList();
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching salespersons');
  }

  // Get salesperson by ID
  Future<Salesperson> getSalespersonById(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$secureBaseUrl/api/admin/salespersons/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          return Salesperson.fromJson(jsonResponse['data']);
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while fetching salesperson');
  }

  // Update salesperson
  Future<Salesperson> updateSalesperson(String id, Map<String, dynamic> updateData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$secureBaseUrl/api/admin/salespersons/$id'),
        headers: headers,
        body: jsonEncode(updateData),
      );

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        if (jsonResponse['data'] != null) {
          return Salesperson.fromJson(jsonResponse['data']);
        } else {
          throw Exception('Invalid response format: missing data field');
        }
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while updating salesperson');
  }

  // Delete salesperson
  Future<bool> deleteSalesperson(String id) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$secureBaseUrl/api/admin/salespersons/$id'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        _handleError(response);
      }
    } catch (e) {
      rethrow;
    }
    throw Exception('Unknown error occurred while deleting salesperson');
  }
}

