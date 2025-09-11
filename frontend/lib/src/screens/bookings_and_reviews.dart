import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/review_model.dart';
import '../models/booking_model.dart';
import '../services/admin_review_service.dart';
import '../services/admin_booking_service.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _reviewService = AdminReviewService(baseUrl: ApiConstants.baseUrl);
    _bookingService = AdminBookingService(baseUrl: ApiConstants.baseUrl);
    
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
          _reviews = (data['reviews'] as List<dynamic>)
              .map((reviewJson) => Review.fromJson(reviewJson))
              .toList();
          _totalReviewPages = data['pagination']['totalPages'];
          _totalReviewCount = data['pagination']['totalCount'];
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
        setState(() {
          _bookings = (data['bookings'] as List<dynamic>)
              .map((bookingJson) => Booking.fromJson(bookingJson))
              .toList();
          _totalBookingPages = data['pagination']['totalPages'];
          _totalBookingCount = data['pagination']['totalCount'];
          _bookingStatistics = data['statistics'];
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
            const SizedBox(height: 8),
            Text(
              review.comment,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  review.userName ?? 'User ${review.userId.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.business, size: 16, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  review.serviceProviderName ?? 'Provider ${review.serviceProviderId.substring(0, 8)}...',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Posted on ${DateFormat('MMM dd, yyyy').format(review.createdAt)}',
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
