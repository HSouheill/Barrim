import 'dart:convert';
import 'api_constant.dart';
import 'api_services.dart';

class AdminBookingService {
  final String baseUrl;

  AdminBookingService({required this.baseUrl});

  String get secureBaseUrl {
    if (baseUrl.startsWith('https://')) {
      return baseUrl;
    } else if (baseUrl.startsWith('http://')) {
      return baseUrl.replaceFirst('http://', 'https://');
    }
    return 'https://$baseUrl';
  }


  // Get all bookings for admin with pagination and filtering
  Future<Map<String, dynamic>> getAllBookingsForAdmin({
    int page = 1,
    int limit = 20,
    String? serviceProviderId,
    String? status,
    String? userId,
    String? date,
    String? isEmergency,
    String? dateRangeStart,
    String? dateRangeEnd,
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
      if (date != null && date.isNotEmpty) {
        queryParams['date'] = date;
      }
      if (isEmergency != null && isEmergency.isNotEmpty) {
        queryParams['isEmergency'] = isEmergency;
      }
      if (dateRangeStart != null && dateRangeStart.isNotEmpty) {
        queryParams['dateRangeStart'] = dateRangeStart;
      }
      if (dateRangeEnd != null && dateRangeEnd.isNotEmpty) {
        queryParams['dateRangeEnd'] = dateRangeEnd;
      }

      final uri = Uri.parse('$secureBaseUrl${ApiConstants.getAllBookingsForAdmin}')
          .replace(queryParameters: queryParams);

      print('Making request to: $uri');

      final response = await ApiService.makeAuthenticatedRequest(
        'get',
        uri.toString(),
      );

      print('Response status: ${response.statusCode}');
      print('Response body: ${response.body}');

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final bookingsData = responseData['data'];
        
        // Handle both enriched and simple booking data - return JSON for UI consumption
        List<Map<String, dynamic>> bookingsJson;
        if (bookingsData['bookings'] is List) {
          final bookingsList = bookingsData['bookings'] as List;
          
          if (bookingsList.isNotEmpty && bookingsList.first is Map<String, dynamic>) {
            final firstBooking = bookingsList.first as Map<String, dynamic>;
            
            // Check if it's enriched data (has nested objects)
            if (firstBooking.containsKey('booking') && firstBooking.containsKey('user')) {
              // Enriched data structure
              bookingsJson = bookingsList.map((enrichedBooking) {
                final bookingData = enrichedBooking['booking'] as Map<String, dynamic>;
                final userData = enrichedBooking['user'] as Map<String, dynamic>;
                final serviceProviderData = enrichedBooking['serviceProvider'] as Map<String, dynamic>;
                
                // Merge the data for the Booking.fromJson method
                final bookingJson = Map<String, dynamic>.from(bookingData);
                bookingJson['userName'] = userData['fullName'];
                bookingJson['serviceProviderName'] = serviceProviderData['fullName'];
                
                return bookingJson;
              }).toList();
            } else {
              // Simple data structure
              bookingsJson = bookingsList.map((json) => json as Map<String, dynamic>).toList();
            }
          } else {
            bookingsJson = [];
          }
        } else {
          bookingsJson = [];
        }

        return {
          'success': true,
          'message': responseData['message'],
          'data': {
            'bookings': bookingsJson,
            'pagination': bookingsData['pagination'],
            'statistics': bookingsData['statistics'],
            'filters': bookingsData['filters'],
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

      final response = await ApiService.makeAuthenticatedRequest(
        'delete',
        uri.toString(),
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
