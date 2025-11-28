import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review_model.dart';
import '../models/booking_model.dart';
import '../models/branch_comment_model.dart';
import '../services/admin_review_service.dart';
import '../services/admin_booking_service.dart';
import '../services/admin_branch_comment_service.dart';
import '../services/api_constant.dart';
import '../components/header.dart';
import '../components/sidebar.dart';
import '../screens/homepage/homepage.dart';
import '../utils/secure_storage.dart';

class BookingsAndReviewsScreen extends StatefulWidget {
  const BookingsAndReviewsScreen({Key? key}) : super(key: key);

  @override
  State<BookingsAndReviewsScreen> createState() => _BookingsAndReviewsScreenState();
}

class _BookingsAndReviewsScreenState extends State<BookingsAndReviewsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AdminReviewService _reviewService;
  late AdminBookingService _bookingService;
  late AdminBranchCommentService _branchCommentService;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Reviews state
  List<Review> _reviews = [];
  bool _isLoadingReviews = false;
  int _currentReviewPage = 1;
  int _totalReviewPages = 1;
  int _totalReviewCount = 0;
  final int _reviewLimit = 20;

  // Bookings state
  List<Booking> _bookings = [];
  bool _isLoadingBookings = false;
  int _currentBookingPage = 1;
  int _totalBookingPages = 1;
  int _totalBookingCount = 0;
  final int _bookingLimit = 20;
  Map<String, dynamic>? _bookingStatistics;

  // Branch Comments state
  List<BranchComment> _branchComments = [];
  bool _isLoadingComments = false;
  int _currentCommentPage = 1;
  int _totalCommentPages = 1;
  int _totalCommentCount = 0;
  final int _commentLimit = 20;
  Map<String, dynamic>? _commentStatistics;

  // Filter states
  String? _selectedServiceProviderId;
  int? _selectedRating;
  bool? _selectedVerified;
  String? _selectedBookingStatus;
  String? _selectedBookingUserId;
  String? _selectedBookingDate;
  String? _selectedIsEmergency;
  String? _selectedDateRangeStart;
  String? _selectedDateRangeEnd;
  String? _selectedBranchType; // "company", "wholesaler", or null for all
  String? _selectedCommentHasReply; // "true", "false", or null for all
  int? _selectedCommentRating;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _reviewService = AdminReviewService(baseUrl: ApiConstants.baseUrl);
    _bookingService = AdminBookingService(baseUrl: ApiConstants.baseUrl);
    _branchCommentService = AdminBranchCommentService(baseUrl: ApiConstants.baseUrl);
    
    _checkAuthenticationAndLoad();
  }

  Future<void> _checkAuthenticationAndLoad() async {
    final secureStorage = SecureStorage();
    final token = await secureStorage.getToken();
    
    if (token == null || token.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please log in to access this feature'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Login',
            textColor: Colors.white,
            onPressed: () {
              // TODO: Navigate to login screen
              print('Navigate to login screen');
            },
          ),
        ),
      );
      return;
    }
    
    _loadReviews();
    _loadBookings();
    _loadBranchComments();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadReviews() async {
    if (_isLoadingReviews) return;
    
    setState(() {
      _isLoadingReviews = true;
    });

    try {
      final result = await _reviewService.getAllReviewsForAdmin(
        page: _currentReviewPage,
        limit: _reviewLimit,
        serviceProviderId: _selectedServiceProviderId,
        rating: _selectedRating,
        verified: _selectedVerified,
      );

      if (result['success']) {
        final data = result['data'];
        setState(() {
          _reviews = (data['reviews'] as List<dynamic>?)
                  ?.map((enrichedReview) {
                    if (enrichedReview == null) return null;
                    
                    // Extract the actual review object from the enriched structure
                    final reviewData = enrichedReview['review'] as Map<String, dynamic>?;
                    if (reviewData == null) return null;
                    
                    // Extract user information
                    final userData = enrichedReview['user'] as Map<String, dynamic>?;
                    final userName = userData?['fullName'] as String?;
                    final userEmail = userData?['email'] as String?;
                    final userPhone = userData?['phone'] as String?;
                    
                    // Extract service provider information
                    final serviceProviderData = enrichedReview['serviceProvider'] as Map<String, dynamic>?;
                    final serviceProviderName = serviceProviderData?['name'] as String? ?? 
                                               serviceProviderData?['fullName'] as String?;
                    final serviceProviderEmail = serviceProviderData?['email'] as String?;
                    final serviceProviderPhone = serviceProviderData?['phone'] as String?;
                    
                    // Extract branch names
                    final companyBranchName = enrichedReview['companyBranchName'] as String?;
                    final wholesalerBranchName = enrichedReview['wholesalerBranchName'] as String?;
                    
                    // Create review object with enriched data
                    final review = Review.fromJson(reviewData);
                    
                    // Update review with enriched information
                    return review.copyWith(
                      userName: userName,
                      serviceProviderName: serviceProviderName,
                      userEmail: userEmail,
                      userPhone: userPhone,
                      serviceProviderEmail: serviceProviderEmail,
                      serviceProviderPhone: serviceProviderPhone,
                      companyBranchName: companyBranchName,
                      wholesalerBranchName: wholesalerBranchName,
                    );
                  })
                  .whereType<Review>()
                  .toList() ??
              [];
          final pagination = data['pagination'] as Map<String, dynamic>?;
          _totalReviewPages = pagination?['totalPages'] as int? ?? 1;
          _totalReviewCount = pagination?['totalCount'] as int? ?? 0;
        });
      } else {
        final message = result['message'];
        final statusCode = result['statusCode'];
        
        if (statusCode == 403) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Access denied: Admin privileges required'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Login as Admin',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Navigate to admin login
                  print('Navigate to admin login');
                },
              ),
            ),
          );
        } else if (statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please log in to access this feature'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Navigate to login screen
                  print('Navigate to login screen');
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading reviews: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading reviews: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }

  Future<void> _loadBookings() async {
    if (_isLoadingBookings) return;
    
    setState(() {
      _isLoadingBookings = true;
    });

    try {
      final result = await _bookingService.getAllBookingsForAdmin(
        page: _currentBookingPage,
        limit: _bookingLimit,
        serviceProviderId: _selectedServiceProviderId,
        status: _selectedBookingStatus,
        userId: _selectedBookingUserId,
        date: _selectedBookingDate,
        isEmergency: _selectedIsEmergency,
        dateRangeStart: _selectedDateRangeStart,
        dateRangeEnd: _selectedDateRangeEnd,
      );

      if (result['success']) {
        final data = result['data'];
        print('Bookings data structure: ${data.keys}');
        print('Bookings count from data: ${(data['bookings'] as List<dynamic>?)?.length ?? 0}');
        setState(() {
          final bookingsList = <Booking>[];
          final rawBookings = data['bookings'] as List<dynamic>? ?? [];
          print('Raw bookings list length: ${rawBookings.length}');
          
          for (var bookingItem in rawBookings) {
            try {
              if (bookingItem == null) continue;
              
              // The service already flattens the enriched structure, so bookingItem is already the merged booking data
              final bookingData = bookingItem is Map 
                  ? Map<String, dynamic>.from(bookingItem)
                  : null;
              
              if (bookingData == null || bookingData.isEmpty) {
                print('Warning: booking data is null or empty');
                continue;
              }
              
              // Convert ObjectID fields to strings if needed
              final processedBookingData = Map<String, dynamic>.from(bookingData);
              
              // Helper to convert ObjectID to string
              String _convertObjectId(dynamic value) {
                if (value == null) return '';
                if (value is String) return value;
                if (value is Map) {
                  return value['\$oid']?.toString() ?? value['_id']?.toString() ?? value.toString();
                }
                return value.toString();
              }
              
              // Handle id field - backend uses 'id' not '_id'
              if (processedBookingData.containsKey('id') && !processedBookingData.containsKey('_id')) {
                processedBookingData['_id'] = _convertObjectId(processedBookingData['id']);
              } else if (processedBookingData.containsKey('_id')) {
                processedBookingData['_id'] = _convertObjectId(processedBookingData['_id']);
              }
              
              // Convert other ID fields
              if (processedBookingData.containsKey('userId')) {
                processedBookingData['userId'] = _convertObjectId(processedBookingData['userId']);
              }
              if (processedBookingData.containsKey('serviceProviderId')) {
                processedBookingData['serviceProviderId'] = _convertObjectId(processedBookingData['serviceProviderId']);
              }
              if (processedBookingData.containsKey('serviceId')) {
                processedBookingData['serviceId'] = _convertObjectId(processedBookingData['serviceId']);
              }
              
              // Handle missing fields - backend might not send all fields
              if (!processedBookingData.containsKey('serviceId')) {
                processedBookingData['serviceId'] = ''; // Default empty string
              }
              if (!processedBookingData.containsKey('amount')) {
                processedBookingData['amount'] = 0.0; // Default to 0
              }
              // Backend uses 'details' instead of 'notes'
              if (processedBookingData.containsKey('details') && !processedBookingData.containsKey('notes')) {
                processedBookingData['notes'] = processedBookingData['details'];
              }
              
              // Extract user and service provider names (already merged by service)
              final userName = processedBookingData['userName'] as String?;
              final serviceProviderName = processedBookingData['serviceProviderName'] as String?;
              
              // Create booking object with enriched data
              final booking = Booking.fromJson(processedBookingData);
              
              // Update booking with user and service provider names (already in processedBookingData, but ensure they're set)
              bookingsList.add(booking.copyWith(
                userName: userName,
                serviceProviderName: serviceProviderName,
              ));
            } catch (e, stackTrace) {
              print('Error parsing booking: $e');
              print('Stack trace: $stackTrace');
              print('Booking data: $bookingItem');
              // Continue to next booking instead of failing completely
              continue;
            }
          }
          
          print('Successfully parsed ${bookingsList.length} bookings out of ${rawBookings.length} total');
          _bookings = bookingsList;
          final pagination = data['pagination'] as Map<String, dynamic>?;
          _totalBookingPages = pagination?['totalPages'] as int? ?? 1;
          _totalBookingCount = pagination?['totalCount'] as int? ?? 0;
          _bookingStatistics = data['statistics'] as Map<String, dynamic>?;
        });
      } else {
        final message = result['message'];
        final statusCode = result['statusCode'];
        
        if (statusCode == 403) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Access denied: Admin privileges required'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Login as Admin',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Navigate to admin login
                  print('Navigate to admin login');
                },
              ),
            ),
          );
        } else if (statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please log in to access this feature'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
              action: SnackBarAction(
                label: 'Login',
                textColor: Colors.white,
                onPressed: () {
                  // TODO: Navigate to login screen
                  print('Navigate to login screen');
                },
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading bookings: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading bookings: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoadingBookings = false;
      });
    }
  }

  Future<void> _loadBranchComments() async {
    if (_isLoadingComments) return;
    
    setState(() {
      _isLoadingComments = true;
    });

    try {
      final result = await _branchCommentService.getAllBranchCommentsForAdmin(
        page: _currentCommentPage,
        limit: _commentLimit,
        branchType: _selectedBranchType,
        hasReply: _selectedCommentHasReply,
        rating: _selectedCommentRating,
      );

      if (result['success']) {
        final data = result['data'];
        setState(() {
          final commentsList = <BranchComment>[];
          final rawComments = data['comments'] as List<dynamic>? ?? [];
          
          for (var enrichedComment in rawComments) {
            try {
              if (enrichedComment == null) continue;
              
              // Extract the actual comment object from the enriched structure
              final commentData = enrichedComment['comment'] as Map<String, dynamic>?;
              if (commentData == null) {
                print('Warning: comment data is null');
                continue;
              }
              
              // Extract branch information
              final branchData = enrichedComment['branch'] as Map<String, dynamic>?;
              final branchName = branchData?['name'] as String?;
              
              // Extract user information
              final userData = enrichedComment['user'] as Map<String, dynamic>?;
              final userName = userData?['fullName'] as String?;
              final userEmail = userData?['email'] as String?;
              final userPhone = userData?['phone'] as String?;
              
              // Extract branch type and company/wholesaler info
              final branchType = enrichedComment['branchType'] as String?;
              final companyData = enrichedComment['company'] as Map<String, dynamic>?;
              final wholesalerData = enrichedComment['wholesaler'] as Map<String, dynamic>?;
              
              // Helper to safely extract string from ID
              String? _safeExtractId(dynamic idValue) {
                if (idValue == null) return null;
                if (idValue is String) return idValue;
                if (idValue is Map) {
                  return idValue['\$oid']?.toString() ?? idValue['_id']?.toString() ?? idValue.toString();
                }
                return idValue.toString();
              }
              
              // Create comment object with enriched data
              final comment = BranchComment.fromJson(commentData);
              
              // Update comment with enriched information
              commentsList.add(comment.copyWith(
                userName: userName,
                userEmail: userEmail,
                userPhone: userPhone,
                branchName: branchName,
                branchType: branchType,
                companyName: companyData?['name'] as String?,
                companyId: companyData != null && companyData.containsKey('id') 
                    ? _safeExtractId(companyData['id'])
                    : null,
                wholesalerName: wholesalerData?['name'] as String?,
                wholesalerId: wholesalerData != null && wholesalerData.containsKey('id')
                    ? _safeExtractId(wholesalerData['id'])
                    : null,
              ));
            } catch (e, stackTrace) {
              print('Error parsing branch comment: $e');
              print('Stack trace: $stackTrace');
              print('Enriched comment data: $enrichedComment');
              continue;
            }
          }
          
          print('Successfully parsed ${commentsList.length} comments out of ${rawComments.length} total');
          _branchComments = commentsList;
          final pagination = data['pagination'] as Map<String, dynamic>?;
          _totalCommentPages = pagination?['totalPages'] as int? ?? 1;
          _totalCommentCount = pagination?['totalCount'] as int? ?? 0;
          _commentStatistics = data['statistics'] as Map<String, dynamic>?;
        });
      } else {
        final message = result['message'];
        final statusCode = result['statusCode'];
        
        if (statusCode == 403) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Access denied: Admin privileges required'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        } else if (statusCode == 401) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please log in to access this feature'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(message),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 5),
            ),
          );
        }
      }
    } catch (e) {
      print('Error loading branch comments: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading branch comments: $e'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoadingComments = false;
      });
    }
  }

  Future<void> _deleteReview(String reviewId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Review'),
        content: Text('Are you sure you want to delete this review? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _reviewService.deleteReview(reviewId);
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          _loadReviews(); // Reload the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting review: $e')),
        );
      }
    }
  }

  Future<void> _deleteBooking(String bookingId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Booking'),
        content: Text('Are you sure you want to delete this booking? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _bookingService.deleteBooking(bookingId);
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
          _loadBookings(); // Reload the list
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(result['message'])),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error deleting booking: $e')),
        );
      }
    }
  }

  Future<void> _deleteBranchComment(String commentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Branch Comment'),
        content: Text('Are you sure you want to delete this branch comment? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final result = await _branchCommentService.deleteBranchComment(commentId);
        
        if (result['success']) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message']),
              backgroundColor: Colors.green,
            ),
          );
          _loadBranchComments(); // Reload the list
        } else {
          final message = result['message'] ?? 'Failed to delete comment';
          final statusCode = result['statusCode'];
          
          if (statusCode == 403) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Access denied: Admin privileges required'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (statusCode == 401) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please log in to access this feature'),
                backgroundColor: Colors.red,
              ),
            );
          } else if (statusCode == 404) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Comment not found'),
                backgroundColor: Colors.orange,
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(message),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting branch comment: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showReviewFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Reviews'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                labelText: 'Service Provider ID',
                hintText: 'Enter service provider ID',
              ),
              onChanged: (value) => _selectedServiceProviderId = value.isEmpty ? null : value,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<int?>(
              decoration: InputDecoration(labelText: 'Rating'),
              value: _selectedRating,
              items: [
                DropdownMenuItem(value: null, child: Text('All Ratings')),
                DropdownMenuItem(value: 1, child: Text('1 Star')),
                DropdownMenuItem(value: 2, child: Text('2 Stars')),
                DropdownMenuItem(value: 3, child: Text('3 Stars')),
                DropdownMenuItem(value: 4, child: Text('4 Stars')),
                DropdownMenuItem(value: 5, child: Text('5 Stars')),
              ],
              onChanged: (value) => _selectedRating = value,
            ),
            SizedBox(height: 16),
            DropdownButtonFormField<bool?>(
              decoration: InputDecoration(labelText: 'Verified'),
              value: _selectedVerified,
              items: [
                DropdownMenuItem(value: null, child: Text('All')),
                DropdownMenuItem(value: true, child: Text('Verified Only')),
                DropdownMenuItem(value: false, child: Text('Unverified Only')),
              ],
              onChanged: (value) => _selectedVerified = value,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentReviewPage = 1;
              });
              _loadReviews();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showBookingFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Bookings'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                decoration: InputDecoration(
                  labelText: 'Service Provider ID',
                  hintText: 'Enter service provider ID',
                ),
                onChanged: (value) => _selectedServiceProviderId = value.isEmpty ? null : value,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'User ID',
                  hintText: 'Enter user ID',
                ),
                onChanged: (value) => _selectedBookingUserId = value.isEmpty ? null : value,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(labelText: 'Status'),
                value: _selectedBookingStatus,
                items: [
                  DropdownMenuItem(value: null, child: Text('All Statuses')),
                  DropdownMenuItem(value: 'pending', child: Text('Pending')),
                  DropdownMenuItem(value: 'confirmed', child: Text('Confirmed')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                  DropdownMenuItem(value: 'cancelled', child: Text('Cancelled')),
                ],
                onChanged: (value) => _selectedBookingStatus = value,
              ),
              SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Specific Date (YYYY-MM-DD)',
                  hintText: 'e.g., 2024-01-15',
                ),
                onChanged: (value) => _selectedBookingDate = value.isEmpty ? null : value,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(labelText: 'Emergency Status'),
                value: _selectedIsEmergency,
                items: [
                  DropdownMenuItem(value: null, child: Text('All Bookings')),
                  DropdownMenuItem(value: 'true', child: Text('Emergency Only')),
                  DropdownMenuItem(value: 'false', child: Text('Non-Emergency Only')),
                ],
                onChanged: (value) => _selectedIsEmergency = value,
              ),
              SizedBox(height: 16),
              Text('Date Range (Optional)'),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Start Date (YYYY-MM-DD)',
                  hintText: 'e.g., 2024-01-01',
                ),
                onChanged: (value) => _selectedDateRangeStart = value.isEmpty ? null : value,
              ),
              SizedBox(height: 8),
              TextField(
                decoration: InputDecoration(
                  labelText: 'End Date (YYYY-MM-DD)',
                  hintText: 'e.g., 2024-01-31',
                ),
                onChanged: (value) => _selectedDateRangeEnd = value.isEmpty ? null : value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedServiceProviderId = null;
                _selectedBookingUserId = null;
                _selectedBookingStatus = null;
                _selectedBookingDate = null;
                _selectedIsEmergency = null;
                _selectedDateRangeStart = null;
                _selectedDateRangeEnd = null;
                _currentBookingPage = 1;
              });
              Navigator.of(context).pop();
              _loadBookings();
            },
            child: Text('Clear All'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentBookingPage = 1;
              });
              _loadBookings();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

    @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Container(
          width: 390, // Standard mobile width
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Scaffold(
            key: _scaffoldKey,
            backgroundColor: Colors.grey.shade100,
            endDrawer: Sidebar(
              onCollapse: () {
                _scaffoldKey.currentState?.closeEndDrawer();
              },
              parentContext: context,
            ),
            body: SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 30),
                  HeaderComponent(
                    logoPath: 'assets/logo/logo.png',
                    scaffoldKey: _scaffoldKey,
                    onMenuPressed: () {
                      _scaffoldKey.currentState?.openEndDrawer();
                    },
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back),
                          onPressed: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const DashboardPage()),
                            );
                          },
                          tooltip: 'Back to Dashboard',
                        ),
                        const SizedBox(width: 16),
                        const Text(
                          'Bookings & Reviews Management',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1C4B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Tab Bar
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 3,
                          offset: const Offset(0, 1),
                        ),
                      ],
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      indicator: BoxDecoration(
                        color: Theme.of(context).primaryColor,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tabs: [
                        Tab(text: 'Reviews (${_totalReviewCount})'),
                        Tab(text: 'Bookings (${_totalBookingCount})'),
                        Tab(text: 'Comments (${_totalCommentCount})'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Content Area
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Reviews Tab
                        _buildReviewsTab(),
                        // Bookings Tab
                        _buildBookingsTab(),
                        // Comments Tab
                        _buildCommentsTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Filters and Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showReviewFilters,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadReviews,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Reviews List
          Expanded(
            child: _isLoadingReviews
                ? const Center(child: CircularProgressIndicator())
                : _reviews.isEmpty
                    ? const Center(
                        child: Text(
                          'No reviews found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _reviews.length,
                        itemBuilder: (context, index) {
                          final review = _reviews[index];
                          return _buildReviewCard(review);
                        },
                      ),
          ),
          
          // Pagination
          if (_totalReviewPages > 1)
            _buildPagination(
              currentPage: _currentReviewPage,
              totalPages: _totalReviewPages,
              onPageChanged: (page) {
                setState(() {
                  _currentReviewPage = page;
                });
                _loadReviews();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Filters and Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showBookingFilters,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadBookings,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          
          // Bookings List
          Expanded(
            child: _isLoadingBookings
                ? const Center(child: CircularProgressIndicator())
                : _bookings.isEmpty
                    ? const Center(
                        child: Text(
                          'No bookings found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _bookings.length,
                        itemBuilder: (context, index) {
                          final booking = _bookings[index];
                          return _buildBookingCard(booking);
                        },
                      ),
          ),
          
          // Pagination
          if (_totalBookingPages > 1)
            _buildPagination(
              currentPage: _currentBookingPage,
              totalPages: _totalBookingPages,
              onPageChanged: (page) {
                setState(() {
                  _currentBookingPage = page;
                });
                _loadBookings();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCommentsTab() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          // Filters and Actions
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 3,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              children: [
                ElevatedButton.icon(
                  onPressed: _showCommentFilters,
                  icon: const Icon(Icons.filter_list),
                  label: const Text('Filters'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _loadBranchComments,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Refresh'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Comments List
          Expanded(
            child: _isLoadingComments
                ? const Center(child: CircularProgressIndicator())
                : _branchComments.isEmpty
                    ? const Center(
                        child: Text(
                          'No branch comments found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _branchComments.length,
                        itemBuilder: (context, index) {
                          final comment = _branchComments[index];
                          return _buildCommentCard(comment);
                        },
                      ),
          ),
          
          // Pagination
          if (_totalCommentPages > 1)
            _buildPagination(
              currentPage: _currentCommentPage,
              totalPages: _totalCommentPages,
              onPageChanged: (page) {
                setState(() {
                  _currentCommentPage = page;
                });
                _loadBranchComments();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildCommentCard(BranchComment comment) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating and Branch Type
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ...List.generate(5, (index) => Icon(
                      index < comment.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    )),
                    const SizedBox(width: 8),
                    Text(
                      '${comment.rating}/5',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: comment.branchType == 'company' 
                            ? Colors.blue.shade100 
                            : Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        comment.branchType?.toUpperCase() ?? 'UNKNOWN',
                        style: TextStyle(
                          color: comment.branchType == 'company' 
                              ? Colors.blue.shade700 
                              : Colors.orange.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => _deleteBranchComment(comment.id),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Comment',
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Comment Text
            Text(
              comment.comment,
              style: const TextStyle(fontSize: 16),
            ),
            
            // Replies Section
            if (comment.replies != null && comment.replies!.isNotEmpty) ...[
              const SizedBox(height: 12),
              ...comment.replies!.map((reply) => Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Reply${reply.repliedByName != null ? ' by ${reply.repliedByName}' : ''}:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      reply.comment,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('MMM dd, yyyy HH:mm').format(reply.createdAt),
                      style: TextStyle(
                        color: Colors.blue.shade600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              )),
            ],
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // User Information
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.userName ?? 'User ${comment.userId.length > 8 ? comment.userId.substring(0, 8) : comment.userId}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (comment.userEmail != null && comment.userEmail!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.email, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              comment.userEmail!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (comment.userPhone != null && comment.userPhone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              comment.userPhone!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Branch Information
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  comment.branchType == 'company' ? Icons.store : Icons.warehouse,
                  size: 16,
                  color: Colors.grey,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        comment.branchName ?? 'Branch ${comment.branchId.length > 8 ? comment.branchId.substring(0, 8) : comment.branchId}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (comment.companyName != null && comment.companyName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.business, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              comment.companyName!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (comment.wholesalerName != null && comment.wholesalerName!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.warehouse, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              comment.wholesalerName!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Timestamp
            Text(
              'Posted on ${DateFormat('MMM dd, yyyy HH:mm').format(comment.createdAt)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _showCommentFilters() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Branch Comments'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(labelText: 'Branch Type'),
                value: _selectedBranchType,
                items: [
                  DropdownMenuItem(value: null, child: Text('All Types')),
                  DropdownMenuItem(value: 'company', child: Text('Company')),
                  DropdownMenuItem(value: 'wholesaler', child: Text('Wholesaler')),
                ],
                onChanged: (value) => _selectedBranchType = value,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                decoration: InputDecoration(labelText: 'Rating'),
                value: _selectedCommentRating,
                items: [
                  DropdownMenuItem(value: null, child: Text('All Ratings')),
                  DropdownMenuItem(value: 1, child: Text('1 Star')),
                  DropdownMenuItem(value: 2, child: Text('2 Stars')),
                  DropdownMenuItem(value: 3, child: Text('3 Stars')),
                  DropdownMenuItem(value: 4, child: Text('4 Stars')),
                  DropdownMenuItem(value: 5, child: Text('5 Stars')),
                ],
                onChanged: (value) => _selectedCommentRating = value,
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                decoration: InputDecoration(labelText: 'Has Reply'),
                value: _selectedCommentHasReply,
                items: [
                  DropdownMenuItem(value: null, child: Text('All Comments')),
                  DropdownMenuItem(value: 'true', child: Text('With Replies Only')),
                  DropdownMenuItem(value: 'false', child: Text('Without Replies Only')),
                ],
                onChanged: (value) => _selectedCommentHasReply = value,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedBranchType = null;
                _selectedCommentRating = null;
                _selectedCommentHasReply = null;
                _currentCommentPage = 1;
              });
              Navigator.of(context).pop();
              _loadBranchComments();
            },
            child: Text('Clear All'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                _currentCommentPage = 1;
              });
              _loadBranchComments();
            },
            child: Text('Apply'),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(Review review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Rating and Actions Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    ...List.generate(5, (index) => Icon(
                      index < review.rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 20,
                    )),
                    const SizedBox(width: 8),
                    Text(
                      '${review.rating}/5',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Row(
                  children: [
                    if (review.isVerified)
                      const Icon(Icons.verified, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    IconButton(
                      onPressed: () => _deleteReview(review.id),
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: 'Delete Review',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Review Comment
            Text(
              review.comment,
              style: const TextStyle(fontSize: 16),
            ),
            
            // Reply Section (if exists)
            if (review.reply != null && review.reply!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.reply, size: 16, color: Colors.blue.shade700),
                        const SizedBox(width: 4),
                        Text(
                          'Service Provider Reply:',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      review.reply!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.blue.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // User Information
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.userName ?? 'User ${review.userId.length > 8 ? review.userId.substring(0, 8) : review.userId}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (review.userEmail != null && review.userEmail!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.email, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              review.userEmail!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (review.userPhone != null && review.userPhone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              review.userPhone!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Service Provider Information
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        review.serviceProviderName ?? 'Provider ${review.serviceProviderId.length > 8 ? review.serviceProviderId.substring(0, 8) : review.serviceProviderId}...',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (review.serviceProviderEmail != null && review.serviceProviderEmail!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.email, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              review.serviceProviderEmail!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (review.serviceProviderPhone != null && review.serviceProviderPhone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(Icons.phone, size: 12, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text(
                              review.serviceProviderPhone!,
                              style: TextStyle(color: Colors.grey[600], fontSize: 12),
                            ),
                          ],
                        ),
                      ],
                      if (review.companyBranchName != null && review.companyBranchName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.green.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.store, size: 12, color: Colors.green.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Branch: ${review.companyBranchName}',
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      if (review.wholesalerBranchName != null && review.wholesalerBranchName!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: Colors.orange.shade200),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.warehouse, size: 12, color: Colors.orange.shade700),
                              const SizedBox(width: 4),
                              Text(
                                'Wholesaler Branch: ${review.wholesalerBranchName}',
                                style: TextStyle(
                                  color: Colors.orange.shade700,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            
            // Timestamp
            Text(
              'Posted on ${DateFormat('MMM dd, yyyy HH:mm').format(review.createdAt)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getStatusColor(booking.status),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    booking.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => _deleteBooking(booking.id),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: 'Delete Booking',
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Booking Date: ${DateFormat('MMM dd, yyyy').format(booking.bookingDate)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
           
            if (booking.notes?.isNotEmpty == true) ...[
              const SizedBox(height: 8),
              Text(
                'Notes: ${booking.notes}',
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  booking.userName ?? 'User ${booking.userId.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  booking.serviceProviderName ?? 'Provider ${booking.serviceProviderId.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Created on ${DateFormat('MMM dd, yyyy').format(booking.createdAt)}',
              style: TextStyle(color: Colors.grey[500], fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'confirmed':
        return Colors.blue;
      case 'completed':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Widget _buildPagination({
    required int currentPage,
    required int totalPages,
    required Function(int) onPageChanged,
  }) {
    return Padding(
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            onPressed: currentPage > 1 ? () => onPageChanged(currentPage - 1) : null,
            icon: Icon(Icons.chevron_left),
          ),
          Text('Page $currentPage of $totalPages'),
          IconButton(
            onPressed: currentPage < totalPages ? () => onPageChanged(currentPage + 1) : null,
            icon: Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}
