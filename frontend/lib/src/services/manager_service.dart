import 'dart:convert';
import 'package:admin_dashboard/src/services/api_services.dart';
import 'package:http/http.dart' as http;
import '../utils/auth_manager.dart';

class ManagerService {
  // Replace static baseUrl with getter that ensures HTTPS
  static String get secureBaseUrl {
    String url = ApiService.baseUrl.trim();
    if (url.startsWith('https://')) {
      return url;
    }
    // Remove http:// if present
    url = url.replaceFirst(RegExp(r'^http://'), '');
    // Remove any leading/trailing slashes
    url = url.replaceAll(RegExp(r'^/+|/+$'), '');
    return 'https://$url';
  }

  static Future<Map<String, String>> _getAuthHeaders() async {
    return await AuthManager.getAuthHeaders();
  }

  // Helper method to make HTTP requests with HTTPS
  static Future<http.Response> _makeSecureRequest(
    String method,
    String endpoint, {
    Map<String, String>? headers,
    Object? body,
  }) async {
    final uri = Uri.parse('$secureBaseUrl$endpoint');
    final requestHeaders = headers ?? await _getAuthHeaders();

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

  static Future<List<dynamic>> getPendingCompanySubscriptionRequests() async {
    try {
      final response = await _makeSecureRequest(
        'get',
        '/api/admin/company-subscription/requests/pending',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception(
            'Failed to load pending company subscription requests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<dynamic>> getPendingServiceProviderSubscriptionRequests() async {
    try {
      final response = await _makeSecureRequest(
        'get',
        '/api/admin/service-provider-subscription/requests/pending',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception(
            'Failed to load pending service provider subscription requests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  static Future<List<dynamic>> getPendingWholesalerSubscriptionRequests() async {
    try {
      final response = await _makeSecureRequest(
        'get',
        '/api/admin/wholesaler-subscription/requests/pending',
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception(
            'Failed to load pending wholesaler subscription requests: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Approve methods
  static Future<bool> approveCompanySubscription(String id) async {
    try {
      final response = await _makeSecureRequest(
        'post',
        '/api/admin/company-subscription/$id/approve',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> approveServiceProviderSubscription(String id) async {
    try {
      final response = await _makeSecureRequest(
        'post',
        '/api/admin/service-provider-subscription/$id/approve',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> approveWholesalerSubscription(String id) async {
    try {
      final response = await _makeSecureRequest(
        'post',
        '/api/admin/wholesaler-subscription/$id/approve',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Reject methods
  static Future<bool> rejectCompanySubscription(String id) async {
    try {
      final response = await _makeSecureRequest(
        'post',
        '/api/admin/company-subscription/$id/reject',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> rejectServiceProviderSubscription(String id) async {
    try {
      final response = await _makeSecureRequest(
        'post',
        '/api/admin/service-provider-subscription/$id/reject',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> rejectWholesalerSubscription(String id) async {
    try {
      final response = await _makeSecureRequest(
        'post',
        '/api/admin/wholesaler-subscription/$id/reject',
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Fetch all entities (companies, service providers, wholesalers, users)
  static Future<Map<String, dynamic>> getCreatedUsers() async {
    try {
      // Fetch companies
      final companiesResponse = await _makeSecureRequest(
        'get',
        '/api/user/companies',
      );

      List<dynamic> companies = [];
      if (companiesResponse.statusCode == 200) {
        final companiesData = json.decode(companiesResponse.body);
        companies = (companiesData['data'] as List? ?? [])
            .where((e) => e != null && e is Map<String, dynamic>)
            .map((e) => {'company': e, 'branches': e['branches'] ?? []})
            .toList();
      }

      // Fetch service providers
      final serviceProvidersResponse = await _makeSecureRequest(
        'get',
        '/api/service-providers/all',
      );

      List<dynamic> serviceProviders = [];
      if (serviceProvidersResponse.statusCode == 200) {
        final serviceProvidersData = json.decode(serviceProvidersResponse.body);
        serviceProviders = (serviceProvidersData['data'] as List? ?? [])
            .where((e) => e != null && e is Map<String, dynamic>)
            .map((e) => {'serviceProvider': e})
            .toList();
      }

      // Fetch wholesalers
      final wholesalersResponse = await _makeSecureRequest(
        'get',
        '/api/wholesalers',
      );

      List<dynamic> wholesalers = [];
      if (wholesalersResponse.statusCode == 200) {
        final wholesalersData = json.decode(wholesalersResponse.body);
        wholesalers = (wholesalersData['data'] as List? ?? [])
            .where((e) => e != null && e is Map<String, dynamic>)
            .map((e) => {'wholesaler': e})
            .toList();
      }

      return {
        'userName': 'Admin',
        'companies': companies,
        'serviceProviders': serviceProviders,
        'wholesalers': wholesalers,
        'users': [],
      };
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Fetch companies with locations
  static Future<List<dynamic>> getCompanies() async {
    try {
      final response = await http.get(
        Uri.parse('$secureBaseUrl/api/user/companies'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final companiesList = data['data'] as List? ?? [];
        return companiesList;
      } else {
        throw Exception('Failed to fetch companies: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching companies: $e');
      throw Exception('Network error: $e');
    }
  }

  // Fetch all service providers
  static Future<List<dynamic>> getServiceProviders() async {
    try {
      final response = await http.get(
        Uri.parse('$secureBaseUrl/api/service-providers/all'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final serviceProvidersList = data['data'] as List? ?? [];
        return serviceProvidersList;
      } else {
        throw Exception('Failed to fetch service providers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching service providers: $e');
      throw Exception('Network error: $e');
    }
  }

  // Fetch all wholesalers
  static Future<List<dynamic>> getWholesalers() async {
    try {
      final response = await http.get(
        Uri.parse('$secureBaseUrl/api/wholesalers'),
        headers: await _getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final wholesalersList = data['data'] as List? ?? [];
        return wholesalersList;
      } else {
        throw Exception('Failed to fetch wholesalers: ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching wholesalers: $e');
      throw Exception('Network error: $e');
    }
  }
}
