import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:admin_dashboard/src/services/api_services.dart';
import 'package:admin_dashboard/src/services/api_constant.dart';
import 'package:admin_dashboard/src/components/header.dart';
import 'package:admin_dashboard/src/components/sidebar.dart';
import 'package:admin_dashboard/src/screens/homepage/homepage.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  UserManagementScreenState createState() => UserManagementScreenState();
}

class UserManagementScreenState extends State<UserManagementScreen> with SingleTickerProviderStateMixin {
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  late TabController _tabController;
  
  // Users data
  List<dynamic> _users = [];
  bool _isLoadingUsers = true;
  String _errorUsers = '';
  int _currentPageUsers = 1;
  int _totalCountUsers = 0;
  int _totalPagesUsers = 1;

  // Salespersons data
  List<dynamic> _salespersons = [];
  bool _isLoadingSalespersons = true;
  String _errorSalespersons = '';
  int _currentPageSalespersons = 1;
  int _totalCountSalespersons = 0;
  int _totalPagesSalespersons = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchUsers();
    _fetchSalespersons();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _fetchUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _errorUsers = '';
    });

    try {
      // Use the new endpoint for getting all users
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.allUsers}'),
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for both success: true and status: 200 patterns
        if (data['success'] == true || data['status'] == 200) {
          final users = data['data']?['users'] ?? [];
          final count = data['data']?['count'] ?? users.length;
          
          setState(() {
            _users = users;
            _totalCountUsers = count;
            _isLoadingUsers = false;
          });
        } else {
          setState(() {
            _errorUsers = data['message'] ?? 'Failed to load users';
            _isLoadingUsers = false;
          });
        }
      } else {
        setState(() {
          _errorUsers = 'Failed to load users. Status code: ${response.statusCode}';
          _isLoadingUsers = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorUsers = 'Error: ${e.toString()}';
        _isLoadingUsers = false;
      });
    }
  }

  Future<void> _fetchSalespersons() async {
    setState(() {
      _isLoadingSalespersons = true;
      _errorSalespersons = '';
    });

    try {
      // Use the new endpoint for getting all salespersons
      final response = await http.get(
        Uri.parse('${ApiConstants.baseUrl}${ApiConstants.getAllSalespersons}'),
        headers: await ApiService.getAuthHeaders(),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // Check for both success: true and status: 200 patterns
        if (data['success'] == true || data['status'] == 200) {
          final salespersons = data['data']?['salespersons'] ?? [];
          final count = data['data']?['count'] ?? salespersons.length;
          
          setState(() {
            _salespersons = salespersons;
            _totalCountSalespersons = count;
            _isLoadingSalespersons = false;
          });
        } else {
          setState(() {
            _errorSalespersons = data['message'] ?? 'Failed to load salespersons';
            _isLoadingSalespersons = false;
          });
        }
      } else {
        setState(() {
          _errorSalespersons = 'Failed to load salespersons. Status code: ${response.statusCode}';
          _isLoadingSalespersons = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorSalespersons = 'Error: ${e.toString()}';
        _isLoadingSalespersons = false;
      });
    }
  }

  void _navigateToPageUsers(int page) {
    if (page >= 1 && page <= _totalPagesUsers && page != _currentPageUsers) {
      setState(() {
        _currentPageUsers = page;
      });
      _fetchUsers();
    }
  }

  void _navigateToPageSalespersons(int page) {
    if (page >= 1 && page <= _totalPagesSalespersons && page != _currentPageSalespersons) {
      setState(() {
        _currentPageSalespersons = page;
      });
      _fetchSalespersons();
    }
  }

  void _showUserDetails(Map<String, dynamic> user) {
    // Get the display name - use email if fullName is empty
    final displayName = (user['fullName'] != null && user['fullName'].toString().isNotEmpty) 
        ? user['fullName'] 
        : (user['email'] ?? 'No Name');
    
    // Get the first character for avatar
    final firstChar = displayName.isNotEmpty 
        ? displayName.substring(0, 1).toUpperCase() 
        : 'U';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.indigo[100],
                child: Text(
                  firstChar,
                  style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Email', user['email'] ?? 'No Email'),
                _buildDetailRow('Phone', user['phoneNumber'] ?? user['phone'] ?? 'No Phone'),
                _buildDetailRow('Role', user['userType'] ?? user['role'] ?? 'user'),
                _buildDetailRow('Status', user['status'] ?? (user['isActive'] == true ? 'active' : 'inactive')),
                _buildDetailRow('Created', _formatDate(user['createdAt'])),
                _buildDetailRow('Updated', _formatDate(user['updatedAt'])),
                if (user['profileImage'] != null && user['profileImage'].isNotEmpty)
                  _buildDetailRow('Profile Image', 'Available'),
                if (user['profilePic'] != null && user['profilePic'].isNotEmpty)
                  _buildDetailRow('Profile Picture', 'Available'),
                if (user['address'] != null)
                  _buildDetailRow('Address', user['address']),
                if (user['city'] != null)
                  _buildDetailRow('City', user['city']),
                if (user['state'] != null)
                  _buildDetailRow('State', user['state']),
                if (user['country'] != null)
                  _buildDetailRow('Country', user['country']),
                if (user['dateOfBirth'] != null)
                  _buildDetailRow('Date of Birth', user['dateOfBirth']),
                if (user['gender'] != null)
                  _buildDetailRow('Gender', user['gender']),
                if (user['points'] != null)
                  _buildDetailRow('Points', user['points'].toString()),
                if (user['referralCode'] != null)
                  _buildDetailRow('Referral Code', user['referralCode']),
                if (user['phoneVerified'] != null)
                  _buildDetailRow('Phone Verified', user['phoneVerified'] ? 'Yes' : 'No'),
                if (user['googleId'] != null)
                  _buildDetailRow('Google ID', user['googleId']),
                if (user['appleUserID'] != null)
                  _buildDetailRow('Apple User ID', user['appleUserID']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      if (date is String) {
        return DateTime.parse(date).toLocal().toString().split('.')[0];
      }
      return date.toString();
    } catch (e) {
      return 'Invalid Date';
    }
  }

  Widget _buildUserCard(Map<String, dynamic> user) {
    // Get the display name - use email if fullName is empty
    final displayName = (user['fullName'] != null && user['fullName'].toString().isNotEmpty) 
        ? user['fullName'] 
        : (user['email'] ?? 'No Name');
    
    // Get the first character for avatar
    final firstChar = displayName.isNotEmpty 
        ? displayName.substring(0, 1).toUpperCase() 
        : 'U';
    
    // Get phone number
    final phoneNumber = user['phoneNumber'] ?? user['phone'] ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showUserDetails(user),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.indigo[100],
                child: Text(
                  firstChar,
                  style: const TextStyle(
                    color: Colors.indigo,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user['email'] ?? 'No Email',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (phoneNumber.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Removed status and user type badges
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _currentPageUsers > 1
                ? () => _navigateToPageUsers(_currentPageUsers - 1)
                : null,
          ),
          Text(
            'Page $_currentPageUsers of $_totalPagesUsers',
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _currentPageUsers < _totalPagesUsers
                ? () => _navigateToPageUsers(_currentPageUsers + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildSalespersonsPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: _currentPageSalespersons > 1
                ? () => _navigateToPageSalespersons(_currentPageSalespersons - 1)
                : null,
          ),
          Text(
            'Page $_currentPageSalespersons of $_totalPagesSalespersons',
            style: const TextStyle(fontSize: 16),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios),
            onPressed: _currentPageSalespersons < _totalPagesSalespersons
                ? () => _navigateToPageSalespersons(_currentPageSalespersons + 1)
                : null,
          ),
        ],
      ),
    );
  }

  void _showSalespersonDetails(Map<String, dynamic> salesperson) {
    // Get the display name - use email if fullName is empty
    final displayName = (salesperson['fullName'] != null && salesperson['fullName'].toString().isNotEmpty) 
        ? salesperson['fullName'] 
        : (salesperson['email'] ?? 'No Name');
    
    // Get the first character for avatar
    final firstChar = displayName.isNotEmpty 
        ? displayName.substring(0, 1).toUpperCase() 
        : 'S';
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Text(
                  firstChar,
                  style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  displayName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Name', displayName),
                _buildDetailRow('Email', salesperson['email'] ?? 'No Email'),
                _buildDetailRow('Phone', salesperson['phoneNumber'] ?? 'No Phone'),
                _buildDetailRow('Commission %', '${salesperson['commissionPercent'] ?? 0}%'),
                if (salesperson['createdByName'] != null && salesperson['createdByName'] != 'None')
                  _buildDetailRow('Created By', salesperson['createdByName']),
                if (salesperson['assignedSalesManager'] != null && salesperson['assignedSalesManager']['email'] != null)
                  _buildDetailRow('Sales Manager Email', salesperson['assignedSalesManager']['email']),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSalespersonCard(Map<String, dynamic> salesperson) {
    // Get the display name - use email if fullName is empty
    final displayName = (salesperson['fullName'] != null && salesperson['fullName'].toString().isNotEmpty) 
        ? salesperson['fullName'] 
        : (salesperson['email'] ?? 'No Name');
    
    // Get the first character for avatar
    final firstChar = displayName.isNotEmpty 
        ? displayName.substring(0, 1).toUpperCase() 
        : 'S';
    
    // Get phone number
    final phoneNumber = salesperson['phoneNumber'] ?? '';
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _showSalespersonDetails(salesperson),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundColor: Colors.green[100],
                child: Text(
                  firstChar,
                  style: const TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      salesperson['email'] ?? 'No Email',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (phoneNumber.isNotEmpty)
                      Row(
                        children: [
                          Icon(Icons.phone, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            phoneNumber,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    if (salesperson['createdByName'] != null && salesperson['createdByName'] != 'None')
                      Row(
                        children: [
                          Icon(Icons.person_add, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text(
                            'Created by: ${salesperson['createdByName']}',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${salesperson['commissionPercent'] ?? 0}%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openEndDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
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
                  const SizedBox(height: 10),
                  HeaderComponent(
                    logoPath: _logoPath,
                    scaffoldKey: _scaffoldKey,
                    onMenuPressed: _openEndDrawer,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                        const Expanded(
                          child: Text(
                            'User Management',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D1C4B),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: () {
                            if (_tabController.index == 0) {
                              _fetchUsers();
                            } else {
                              _fetchSalespersons();
                            }
                          },
                          tooltip: 'Refresh',
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
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.grey[600],
                      indicator: BoxDecoration(
                        color: Colors.indigo,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      tabs: const [
                        Tab(
                          icon: Icon(Icons.people),
                          text: 'Users',
                        ),
                        Tab(
                          icon: Icon(Icons.person_add),
                          text: 'Salespersons',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Tab Bar View
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Users Tab
                        _buildUsersTab(),
                        // Salespersons Tab
                        _buildSalespersonsTab(),
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

  Widget _buildUsersTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.people, color: Colors.indigo),
              const SizedBox(width: 8),
              Text(
                'Total Users: $_totalCountUsers',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.indigo,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingUsers
              ? const Center(child: CircularProgressIndicator())
              : _errorUsers.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorUsers,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchUsers,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _users.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.people_outline, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No users found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: _users.length,
                                itemBuilder: (context, index) {
                                  return _buildUserCard(
                                    Map<String, dynamic>.from(_users[index]),
                                  );
                                },
                              ),
                            ),
                            if (_totalPagesUsers > 1) _buildPaginationControls(),
                          ],
                        ),
        ),
      ],
    );
  }

  Widget _buildSalespersonsTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(Icons.person_add, color: Colors.green),
              const SizedBox(width: 8),
              Text(
                'Total Salespersons: $_totalCountSalespersons',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.green,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingSalespersons
              ? const Center(child: CircularProgressIndicator())
              : _errorSalespersons.isNotEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error, color: Colors.red, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            _errorSalespersons,
                            style: const TextStyle(color: Colors.red),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchSalespersons,
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    )
                  : _salespersons.isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.person_add_outlined, size: 48, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No salespersons found',
                                style: TextStyle(fontSize: 18, color: Colors.grey),
                              ),
                            ],
                          ),
                        )
                      : Column(
                          children: [
                            Expanded(
                              child: ListView.builder(
                                itemCount: _salespersons.length,
                                itemBuilder: (context, index) {
                                  return _buildSalespersonCard(
                                    Map<String, dynamic>.from(_salespersons[index]),
                                  );
                                },
                              ),
                            ),
                            if (_totalPagesSalespersons > 1) _buildSalespersonsPaginationControls(),
                          ],
                        ),
        ),
      ],
    );
  }
}
