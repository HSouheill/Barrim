import 'dart:convert';
import 'package:http/http.dart' as http;
import 'api_services.dart';

class BusinessManagementService {
  static const String _baseUrl = '${ApiService.baseUrl}/api/admin';

  // Get all pending branch subscription requests (with optional pagination)
  static Future<Map<String, dynamic>> getPendingBranchRequests({int page = 1, int limit = 10}) async {
    final headers = await ApiService.getAuthHeaders();
    final uri = Uri.parse('$_baseUrl/company/branch-subscription/requests/pending?page=$page&limit=$limit');
    final response = await http.get(uri, headers: headers);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // Get a specific branch subscription request by ID
  static Future<Map<String, dynamic>> getBranchRequest(String id) async {
    final headers = await ApiService.getAuthHeaders();
    final uri = Uri.parse('$_baseUrl/company/branch-subscription/requests/$id');
    final response = await http.get(uri, headers: headers);
    return json.decode(response.body) as Map<String, dynamic>;
  }

  // Process a branch subscription request (approve or reject)
  static Future<Map<String, dynamic>> processBranchRequest({
    required String id,
    required String status, // 'approved' or 'rejected'
    String? adminNote,
  }) async {
    final headers = await ApiService.getAuthHeaders();
    final uri = Uri.parse('$_baseUrl/company/branch-subscription/requests/$id/process');
    final body = json.encode({
      'status': status,
      if (adminNote != null) 'adminNote': adminNote,
    });
    final response = await http.post(uri, headers: headers, body: body);
    return json.decode(response.body) as Map<String, dynamic>;
  }
}
