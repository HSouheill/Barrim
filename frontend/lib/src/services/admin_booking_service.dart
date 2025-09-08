import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/booking_model.dart';
import '../utils/auth_manager.dart';
import '../utils/secure_storage.dart';
import 'api_constant.dart';

class AdminBookingService {
  final String baseUrl;
  final SecureStorage _secureStorage = SecureStorage();
  final AuthManager _authManager = AuthManager();

  AdminBookingService({required this.baseUrl});

  String get secureBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl;
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'https://');
    }
    return 'https://$baseUrl';
  }

  Future<Map<String, String>> _getHeaders() async {
    final token = await _secureStorage.getToken();
    return {
      'Content-Type': 'application/json',
      'Authorization': token != null ? 'Bearer $token' : '',
    };
  }

  // Get all bookings for admin with pagination and filtering
  Future<Map<String, dynamic>> getAllBookingsForAdmin({
    int page = 1,
    int limit = 20,
    String? serviceProviderId,
    String? status,
    String? userId,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };

      if (serviceProviderId != null && serviceProviderId.isNotEmpty) {
        queryParams['serviceProviderId'] = serviceProviderId;
      }
      if (status != null && status.isNotEmpty) {
        queryParams['status'] = status;
      }
      if (userId != null && userId.isNotEmpty) {
        queryParams['userId'] = userId;
      }

      final uri = Uri.parse('$secureBaseUrl${ApiConstants.getAllBookingsForAdmin}')
          .replace(queryParameters: queryParams);

      final headers = await _getHeaders();
      print('Making request to: $uri');
      print('Headers: $headers');

      final response = await http.get(
        uri,
        headers: headers,
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final bookingsData = responseData['data'];
        
        // Handle both enriched and simple booking data
        List<Booking> bookings;
        if (bookingsData['bookings'] is List) {
          final bookingsList = bookingsData['bookings'] as List;
          
          if (bookingsList.isNotEmpty && bookingsList.first is Map<String, dynamic>) {
            final firstBooking = bookingsList.first as Map<String, dynamic>;
            
            // Check if it's enriched data (has nested objects)
            if (firstBooking.containsKey('booking') && firstBooking.containsKey('user')) {
              // Enriched data structure
              bookings = bookingsList.map((enrichedBooking) {
                final bookingData = enrichedBooking['booking'] as Map<String, dynamic>;
                final userData = enrichedBooking['user'] as Map<String, dynamic>;
                final serviceProviderData = enrichedBooking['serviceProvider'] as Map<String, dynamic>;
                
                // Merge the data for the Booking.fromJson method
                final bookingJson = Map<String, dynamic>.from(bookingData);
                bookingJson['userName'] = userData['fullName'];
                bookingJson['serviceProviderName'] = serviceProviderData['fullName'];
                
                return Booking.fromJson(bookingJson);
              }).toList();
            } else {
              // Simple data structure
              bookings = bookingsList.map((json) => Booking.fromJson(json)).toList();
            }
          } else {
            bookings = [];
          }
        } else {
          bookings = [];
        }

        return {
          'success': true,
          'message': responseData['message'],
          'data': {
            'bookings': bookings,
            'pagination': bookingsData['pagination'],
          },
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
          'message': responseData['message'] ?? 'Failed to fetch bookings',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error fetching bookings: $e',
      };
    }
  }

  // Delete a booking
  Future<Map<String, dynamic>> deleteBooking(String bookingId) async {
    try {
      final uri = Uri.parse('$secureBaseUrl${ApiConstants.deleteBooking}/$bookingId');

      final response = await http.delete(
        uri,
        headers: await _getHeaders(),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': responseData['message'],
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
          'message': responseData['message'] ?? 'Failed to delete booking',
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Error deleting booking: $e',
      };
    }
  }
}
