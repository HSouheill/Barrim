import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/sales_manager.dart';
import '../utils/auth_manager.dart';
import '../utils/secure_storage.dart';
import '../models/admin_model.dart';
import '../models/service_provider_model.dart';
import 'api_services.dart';

class AdminService {
  final String baseUrl;
  final SecureStorage _secureStorage = SecureStorage();
  final AuthManager _authManager = AuthManager();

  AdminService({required this.baseUrl});

  String get secureBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl;
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'https://');
    }
    return 'https://$baseUrl';
  }

  Future<http.Response> _makeRequest(
    String method,
    String url, {
    Map<String, String>? headers,
    dynamic body,
  }) async {
    final uri = Uri.parse(url);
    switch (method.toLowerCase()) {
      case 'get':
        return await http.get(uri, headers: headers);
      case 'post':
        return await http.post(uri, headers: headers, body: body);
      case 'put':
        return await http.put(uri, headers: headers, body: body);
      case 'delete':
        return await http.delete(uri, headers: headers, body: body);
      default:
        throw UnsupportedError('HTTP method not supported: $method');
    }
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Logout
  Future<void> logout() async {
    await _secureStorage.clearAll();
    await AuthManager.logout();
  }

  // Get Active Users
  Future<Map<String, dynamic>> getActiveUsers() async {
    final response = await _makeRequest(
      'get',
      '$secureBaseUrl/api/admin/users',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to fetch active users',
      };
    }
  }

  // Create Sales Manager
  Future<Map<String, dynamic>> createSalesManager(
      SalesManager salesManager) async {
    final response = await _makeRequest(
      'post',
      '$secureBaseUrl/api/admin/sales-managers',
      headers: await _getHeaders(),
      body: jsonEncode(salesManager.toJson()),
    );

    final responseData = jsonDecode(response.body);

    return {
      'success': response.statusCode == 201 || response.statusCode == 200,
      'message': responseData['message'],
      'data': responseData['data'],
    };
  }

  // Get All Sales Managers
  Future<Map<String, dynamic>> getAllSalesManagers() async {
    final response = await _makeRequest(
      'get',
      '$secureBaseUrl/api/admin/sales-managers',
      headers: await _getHeaders(),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to fetch sales managers',
      };
    }
  }

  // Get Sales Manager by ID with salespersons and metrics
  Future<Map<String, dynamic>> getSalesManager(String id) async {
    final response = await _makeRequest(
      'get',
      '$secureBaseUrl/api/admin/sales-managers/$id',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'], // Return the full response data
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to fetch sales manager',
      };
    }
  }

  // Update Sales Manager
  Future<Map<String, dynamic>> updateSalesManager(String id,
      SalesManager salesManager) async {
    final response = await _makeRequest(
      'put',
      '$secureBaseUrl/api/admin/sales-managers/$id',
      headers: await _getHeaders(),
      body: jsonEncode(salesManager.toJson()),
    );

    final responseData = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': responseData['message'],
    };
  }

  // Delete Sales Manager
  Future<Map<String, dynamic>> deleteSalesManager(String id) async {
    final response = await _makeRequest(
      'delete',
      '$secureBaseUrl/api/admin/sales-managers/$id',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': responseData['message'],
    };
  }

  // Get User Status
  Future<Map<String, dynamic>> getUserStatus(String userId) async {
    final response = await _makeRequest(
      'get',
      '$secureBaseUrl/api/admin/users/$userId/status',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to fetch user status',
      };
    }
  }

  // Admin Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    final response = await _makeRequest(
      'get',
      '$secureBaseUrl/api/admin/dashboard/stats',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to fetch dashboard stats',
      };
    }
  }

  // Fetch all service providers
  Future<List<ServiceProvider>> getAllServiceProviders() async {
    final response = await _makeRequest(
      'get',
      '$secureBaseUrl/api/service-providers/all',
      headers: await _getHeaders(),
    );
    final responseData = jsonDecode(response.body);
    if (response.statusCode == 200 && responseData['data'] != null) {
      final serviceProviders = <ServiceProvider>[];
      final dataList = responseData['data'] as List? ?? [];
      for (var e in dataList) {
        if (e != null && e is Map<String, dynamic>) {
          try {
            serviceProviders.add(ServiceProvider.fromJson(e));
          } catch (error) {
            print('Error parsing service provider: $error');
          }
        }
      }
      return serviceProviders;
    } else {
      throw Exception(responseData['message'] ?? 'Failed to fetch service providers');
    }
  }

  // Delete Entity (User, Company, Wholesaler, ServiceProvider)
  Future<Map<String, dynamic>> deleteEntity(String entityType, String entityId) async {
    final response = await _makeRequest(
      'delete',
      '$secureBaseUrl/api/admin/entities/$entityType/$entityId',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': responseData['message'] ?? 'Failed to delete $entityType',
      'statusCode': response.statusCode,
    };
  }

  // Delete User (for backward compatibility)
  Future<Map<String, dynamic>> deleteUser(String userId) async {
    return await deleteEntity('user', userId);
  }

  /// Toggle the status of a company branch (admin action)
   Future<Map<String, dynamic>> toggleCompanyBranchStatus({
    required String companyId,
    required String branchId,
    required String status,
  }) async {
    final url = '$secureBaseUrl/api/admin/toggle-status/company/$companyId/branch/$branchId';

    final response = await _makeRequest(
      'put',
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      return {'success': true, 'data': jsonDecode(response.body)};
    } else {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': response.body
      };
    }
  }

  /// Toggle the status of a service provider (admin action)
  Future<Map<String, dynamic>> toggleServiceProviderStatus({
    required String serviceProviderId,
    required String status,
  }) async {
    final url = '$secureBaseUrl/api/admin/service-providers/$serviceProviderId/toggle-status';
    
    final response = await _makeRequest(
      'put',
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );

    if (response.statusCode == 200) {
      final responseData = jsonDecode(response.body);
      return {'success': true, 'data': responseData};
    } else {
      return {
        'success': false,
        'statusCode': response.statusCode,
        'message': response.body
      };
    }
  }

  // Create Salesperson (Admin only)
  Future<Map<String, dynamic>> createSalesperson(Map<String, dynamic> salespersonData) async {
    final response = await _makeRequest(
      'post',
      '$secureBaseUrl/api/admin/salespersons',
      headers: await _getHeaders(),
      body: jsonEncode(salespersonData),
    );

    final responseData = jsonDecode(response.body);

    return {
      'success': response.statusCode == 201 || response.statusCode == 200,
      'message': responseData['message'],
      'data': responseData['data'],
    };
  }

  // Get All Salespersons (Admin only)
  Future<Map<String, dynamic>> GetAdminSalespersons() async {
    final response = await _makeRequest(
      'get',
      '$secureBaseUrl/api/admin/salespersons',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to fetch salespersons',
      };
    }
  }

  // Delete Salesperson (Admin only)
  Future<Map<String, dynamic>> deleteSalesperson(String salespersonId) async {
    final response = await _makeRequest(
      'delete',
      '$secureBaseUrl/api/admin/salespersons/$salespersonId',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': responseData['message'] ?? 'Failed to delete salesperson',
    };
  }

  // Update Salesperson (Admin only)
  Future<Map<String, dynamic>> updateSalesperson(String salespersonId, Map<String, dynamic> salespersonData) async {
    final response = await _makeRequest(
      'put',
      '$secureBaseUrl/api/admin/salespersons/$salespersonId',
      headers: await _getHeaders(),
      body: jsonEncode(salespersonData),
    );

    final responseData = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': responseData['message'] ?? 'Failed to update salesperson',
    };
  }

  // Get Pending Requests from Admin Salespersons
  Future<Map<String, dynamic>> getPendingRequestsFromAdminSalespersons() async {
    final response = await _makeRequest(
      'get',
      '$secureBaseUrl/api/admin/pending-requests',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to fetch pending requests',
      };
    }
  }

  // Process Pending Request (approve/reject)
  Future<Map<String, dynamic>> processPendingRequest({
    required String requestType,
    required String requestId,
    required String action,
  }) async {
    // Map action to the correct endpoint
    String endpoint;
    if (action.toLowerCase() == 'approve') {
      endpoint = '$secureBaseUrl/api/admin/pending-requests/approve';
    } else if (action.toLowerCase() == 'reject') {
      endpoint = '$secureBaseUrl/api/admin/pending-requests/reject';
    } else {
      return {
        'success': false,
        'message': 'Invalid action. Must be "approve" or "reject"',
      };
    }

    final body = {
      'requestType': requestType,
      'requestId': requestId,
    };

    final response = await _makeRequest(
      'post',
      endpoint,
      headers: await _getHeaders(),
      body: jsonEncode(body),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to process request',
      };
    }
  }

  // Delete Company Branch
  Future<Map<String, dynamic>> deleteCompanyBranch({
    required String companyId,
    required String branchId,
  }) async {
    final url = '$secureBaseUrl/api/admin/company/$companyId/branch/$branchId';

    final response = await _makeRequest(
      'delete',
      url,
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': responseData['message'] ?? 'Failed to delete branch',
      'statusCode': response.statusCode,
    };
  }

  // Get All Wholesaler Branches
  Future<Map<String, dynamic>> getAllWholesalerBranches() async {
    final response = await _makeRequest(
      'get',
      '$secureBaseUrl/api/admin/wholesalers/branches',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200) {
      return {
        'success': true,
        'message': responseData['message'],
        'data': responseData['data'],
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to fetch wholesaler branches',
      };
    }
  }

  // Delete Wholesaler Branch
  Future<Map<String, dynamic>> deleteWholesalerBranch({
    required String wholesalerId,
    required String branchId,
  }) async {
    final url = '$secureBaseUrl/api/admin/wholesaler/$wholesalerId/branch/$branchId';

    final response = await _makeRequest(
      'delete',
      url,
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': responseData['message'] ?? 'Failed to delete wholesaler branch',
      'statusCode': response.statusCode,
    };
  }

  // Toggle Wholesaler Branch Status
  Future<Map<String, dynamic>> toggleWholesalerBranchStatus({
    required String wholesalerId,
    required String branchId,
    required String status,
  }) async {
    final url = '$secureBaseUrl/api/admin/toggle-status/wholesaler/$wholesalerId/branch/$branchId';

    final response = await _makeRequest(
      'put',
      url,
      headers: await _getHeaders(),
      body: jsonEncode({'status': status}),
    );

    final responseData = jsonDecode(response.body);

    return {
      'success': response.statusCode == 200,
      'message': responseData['message'] ?? 'Failed to update wholesaler branch status',
      'statusCode': response.statusCode,
    };
  }

  // Get Whish Payment Details
  Future<Map<String, dynamic>> getWhishPaymentDetails(String externalId) async {
    final response = await _makeRequest(
      'get',
      '$secureBaseUrl/api/admin/whish-payment/$externalId',
      headers: await _getHeaders(),
    );

    final responseData = jsonDecode(response.body);

    if (response.statusCode == 200 || response.statusCode == 404) {
      return {
        'success': response.statusCode == 200,
        'message': responseData['message'] ?? 'Payment details retrieved',
        'data': responseData['data'],
        'statusCode': response.statusCode,
      };
    } else {
      return {
        'success': false,
        'message': responseData['message'] ?? 'Failed to fetch payment details',
        'statusCode': response.statusCode,
      };
    }
  }

}