import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/withdrawal_model.dart';
import '../utils/auth_manager.dart';
import '../utils/secure_storage.dart';

class WithdrawalService {
  final String baseUrl;
  final SecureStorage _secureStorage = SecureStorage();
  final AuthManager _authManager = AuthManager();

  WithdrawalService({required this.baseUrl});

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

  // Get pending withdrawal requests
  Future<Map<String, dynamic>> getPendingWithdrawalRequests() async {
    try {
      final response = await _makeRequest(
        'get',
        '$secureBaseUrl/api/admin/withdrawals/pending',
        headers: await _getHeaders(),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        List<EnrichedWithdrawal> withdrawals = [];
        if (responseData['data'] != null) {
          withdrawals = (responseData['data'] as List)
              .map((item) => EnrichedWithdrawal.fromJson(item))
              .toList();
        }

        return {
          'success': true,
          'message': responseData['message'] ?? 'Pending withdrawal requests retrieved successfully',
          'data': withdrawals,
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to retrieve withdrawal requests',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Approve withdrawal request
  Future<Map<String, dynamic>> approveWithdrawalRequest(
    String withdrawalId,
    String adminNote,
  ) async {
    try {
      final approvalRequest = WithdrawalApprovalRequest(adminNote: adminNote);
      
      final response = await _makeRequest(
        'post',
        '$secureBaseUrl/api/admin/withdrawals/$withdrawalId/approve',
        headers: await _getHeaders(),
        body: jsonEncode(approvalRequest.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Withdrawal request approved successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to approve withdrawal request',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }

  // Reject withdrawal request
  Future<Map<String, dynamic>> rejectWithdrawalRequest(
    String withdrawalId,
    String adminNote,
  ) async {
    try {
      final rejectionRequest = WithdrawalRejectionRequest(adminNote: adminNote);
      
      final response = await _makeRequest(
        'post',
        '$secureBaseUrl/api/admin/withdrawals/$withdrawalId/reject',
        headers: await _getHeaders(),
        body: jsonEncode(rejectionRequest.toJson()),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'] ?? 'Withdrawal request rejected successfully',
          'data': responseData['data'],
        };
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Failed to reject withdrawal request',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error: ${e.toString()}',
      };
    }
  }
}
