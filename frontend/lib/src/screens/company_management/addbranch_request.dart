import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../services/business_management_service.dart';
import '../../components/header.dart';
import '../../components/sidebar.dart';
import '../../services/manager_service.dart'; // Added import for ManagerService
import '../../models/enriched_company.dart'; // Added import for EnrichedCompany
import '../../services/api_services.dart'; // Added import for API services
import '../../services/admin_service.dart'; // Added import for AdminService
import '../../screens/homepage/homepage.dart';

class RestaurantListScreen extends StatefulWidget {
  const RestaurantListScreen({Key? key}) : super(key: key);

  @override
  State<RestaurantListScreen> createState() => _RestaurantListScreenState();
}

class _RestaurantListScreenState extends State<RestaurantListScreen> {
  String selectedTab = 'All';

  // Handles tab changes
  void _onTabSelected(String tab) {
    if (selectedTab == tab) return;
    setState(() {
      selectedTab = tab;
    });
  }

  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  void _openEndDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }

  // Remove static restaurant data
  // final List<Map<String, dynamic>> restaurants = [ ... ];

  // State for fetched data
  List<dynamic> _companies = [];
  List<dynamic> _serviceProviders = [];
  List<dynamic> _wholesalers = [];
  List<dynamic> _users = [];
  bool _isLoadingUsers = false;
  String _usersError = '';

  // Branch requests state
  List<Map<String, dynamic>> _branchRequests = [];
  bool _isLoadingRequests = false;
  String _requestsError = '';
  int _requestsPage = 1;
  int _requestsLimit = 10;

  @override
  void initState() {
    super.initState();
    _fetchCreatedUsers();
  }

  Future<void> _fetchCreatedUsers() async {
    setState(() {
      _isLoadingUsers = true;
      _usersError = '';
    });
    try {
      final data = await ManagerService.getCreatedUsers();
      print('API Response data: $data'); // Debug log
      
      final companies = data['companies'] ?? [];
      final serviceProviders = data['serviceProviders'] ?? [];
      final wholesalers = data['wholesalers'] ?? [];
      final users = data['users'] ?? [];
      
      print('Companies data: $companies'); // Debug log
      print('Companies length: ${companies.length}'); // Debug log
      print('ServiceProviders data: $serviceProviders'); // Debug log
      print('ServiceProviders length: ${serviceProviders.length}'); // Debug log
      print('Wholesalers data: $wholesalers'); // Debug log
      print('Wholesalers length: ${wholesalers.length}'); // Debug log
      print('Users data: $users'); // Debug log
      print('Users length: ${users.length}'); // Debug log
      
      if (companies.isNotEmpty) {
        print('First company structure: ${companies.first}'); // Debug log
      }
      if (serviceProviders.isNotEmpty) {
        print('First serviceProvider structure: ${serviceProviders.first}'); // Debug log
      }
      if (wholesalers.isNotEmpty) {
        print('First wholesaler structure: ${wholesalers.first}'); // Debug log
      }
      
      setState(() {
        _companies = companies;
        _serviceProviders = serviceProviders;
        _wholesalers = wholesalers;
        _users = users;
        _isLoadingUsers = false;
      });
    } catch (e) {
      print('Error fetching users: $e'); // Debug log
      setState(() {
        _usersError = 'Error:  [${e.toString()}';
        _isLoadingUsers = false;
      });
    }
  }



  // Method to toggle entity status
  Future<bool> toggleEntityStatus(String entityType, String entityId, String currentStatus) async {
    print('Toggle called: $entityType, $entityId, $currentStatus'); // Debug log
    try {
      final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
      print('New status will be: $newStatus'); // Debug log
      
      // Handle service providers with their specific endpoint
      if (entityType == 'serviceProvider') {
        final adminService = AdminService(baseUrl: ApiService.secureBaseUrl);
        final result = await adminService.toggleServiceProviderStatus(
          serviceProviderId: entityId,
          status: newStatus,
        );
        
        if (result['success']) {
          // Refresh the data after successful toggle without showing loading
          await _refreshDataSilently();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: ${result['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      } else {
        // Use generic endpoint for other entity types
        final headers = await ApiService.getAuthHeaders();
        final url = '${ApiService.secureBaseUrl}/api/admin/toggle-status/$entityType/$entityId';
        print('Calling URL: $url'); // Debug log
        
        final response = await http.put(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({'status': newStatus}),
        );
        
        print('Response status: ${response.statusCode}'); // Debug log
        print('Response body: ${response.body}'); // Debug log
        
        if (response.statusCode == 200) {
          // Refresh the data after successful toggle without showing loading
          await _refreshDataSilently();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Status updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
          return true;
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update status: ${response.statusCode}'),
              backgroundColor: Colors.red,
            ),
          );
          return false;
        }
      }
    } catch (e) {
      print('Error in toggleEntityStatus: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
  }

  // Method to refresh data without showing loading indicator
  Future<void> _refreshDataSilently() async {
    try {
      final data = await ManagerService.getCreatedUsers();
      print('API Response data: $data'); // Debug log
      
      final companies = data['companies'] ?? [];
      final serviceProviders = data['serviceProviders'] ?? [];
      final wholesalers = data['wholesalers'] ?? [];
      final users = data['users'] ?? [];
      
      print('Companies data: $companies'); // Debug log
      print('Companies length: ${companies.length}'); // Debug log
      print('ServiceProviders data: $serviceProviders'); // Debug log
      print('ServiceProviders length: ${serviceProviders.length}'); // Debug log
      print('Wholesalers data: $wholesalers'); // Debug log
      print('Wholesalers length: ${wholesalers.length}'); // Debug log
      print('Users data: $users'); // Debug log
      print('Users length: ${users.length}'); // Debug log
      
      if (companies.isNotEmpty) {
        print('First company structure: ${companies.first}'); // Debug log
      }
      if (serviceProviders.isNotEmpty) {
        print('First serviceProvider structure: ${serviceProviders.first}'); // Debug log
      }
      if (wholesalers.isNotEmpty) {
        print('First wholesaler structure: ${wholesalers.first}'); // Debug log
      }
      
      setState(() {
        _companies = companies;
        _serviceProviders = serviceProviders;
        _wholesalers = wholesalers;
        _users = users;
      });
    } catch (e) {
      print('Error refreshing data silently: $e'); // Debug log
      // Don't show error to user for silent refresh
    }
  }

  // Method to delete entity
  Future<void> deleteEntity(String entityId, String entityType, String entityName) async {
    print('Delete called for $entityType ID: $entityId'); // Debug log
    try {
      final adminService = AdminService(baseUrl: ApiService.secureBaseUrl);
      final result = await adminService.deleteEntity(entityType, entityId);
      
      print('Delete response: $result'); // Debug log
      
      if (result['success']) {
        // Refresh the data after successful delete without showing loading
        await _refreshDataSilently();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$entityName deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete $entityName: ${result['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print('Error in deleteEntity: $e'); // Debug log
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Method to delete user (for backward compatibility)
  Future<void> deleteUser(String userId) async {
    await deleteEntity(userId, 'user', 'User');
  }

  // Method to show delete confirmation dialog
  void _showDeleteConfirmation(String entityId, String entityName, String entityType) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text('Are you sure you want to delete "$entityName"? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                deleteEntity(entityId, entityType, entityName); // Proceed with deletion
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  List<dynamic> getFilteredCompanies() {
    if (selectedTab == 'All') return _companies.where((c) => c != null).toList();
    
    return _companies.where((c) {
      if (c == null) return false;
      
      try {
        // Handle both enriched and non-enriched company data
        String? status;
        Map<String, dynamic>? companyData;
        
        // Check if this is an enriched company object
        if (c is Map<String, dynamic>) {
          if (c['company'] != null && c['company'] is Map<String, dynamic>) {
            // This is an enriched company object
            companyData = c['company'] as Map<String, dynamic>;
          } else if (c['businessName'] != null || c['name'] != null) {
            // This is a direct company object
            companyData = c;
          }
          
          // Get status from company data if available
          if (companyData != null) {
            // First check branches if they exist
            if (companyData['branches'] != null && 
                companyData['branches'] is List && 
                (companyData['branches'] as List).isNotEmpty) {
              // Get status from the first branch
              final firstBranch = (companyData['branches'] as List).first;
              if (firstBranch is Map<String, dynamic> && firstBranch['status'] != null) {
                status = firstBranch['status'];
              }
            }
            // Fall back to company status if no branch status
            status ??= companyData['status'];
          }
        }
        
        // Default to 'active' if status is still null
        status ??= 'active';
        
        // Apply filter based on selected tab
        if (selectedTab == 'Active') {
          return status == 'active';
        } else if (selectedTab == 'Inactive') {
          return status == 'inactive';
        }
        return false;
      } catch (e) {
        print('Error filtering company: $e');
        return false;
      }
    }).toList();
  }

  List<dynamic> getFilteredServiceProviders() {
    if (selectedTab == 'All') return _serviceProviders.where((sp) => sp != null).toList();
    
    return _serviceProviders.where((sp) {
      if (sp == null) return false;
      
      try {
        // Service providers now come in enriched format
        String? status;
        if (sp is Map<String, dynamic>) {
          if (sp['serviceProvider'] != null && sp['serviceProvider'] is Map<String, dynamic>) {
            status = sp['serviceProvider']['status'];
          } else if (sp['status'] != null) {
            status = sp['status'];
          }
        }
        status ??= 'active';
        
        if (selectedTab == 'Active') {
          return status == 'active';
        } else if (selectedTab == 'Inactive') {
          return status == 'inactive';
        }
        return false;
      } catch (e) {
        print('Error filtering service provider: $e');
        return false;
      }
    }).toList();
  }

  List<dynamic> getFilteredWholesalers() {
    if (selectedTab == 'All') return _wholesalers.where((w) => w != null).toList();
    
    return _wholesalers.where((w) {
      if (w == null) return false;
      
      try {
        // Wholesalers now come in enriched format
        String? status;
        if (w is Map<String, dynamic>) {
          if (w['wholesaler'] != null && w['wholesaler'] is Map<String, dynamic>) {
            status = w['wholesaler']['status'];
          } else if (w['status'] != null) {
            status = w['status'];
          }
        }
        status ??= 'active';
        
        if (selectedTab == 'Active') {
          return status == 'active';
        } else if (selectedTab == 'Inactive') {
          return status == 'inactive';
        }
        return false;
      } catch (e) {
        print('Error filtering wholesaler: $e');
        return false;
      }
    }).toList();
  }

  List<dynamic> getFilteredUsers() {
    if (selectedTab == 'All') return _users.where((u) => u != null).toList();
    
    return _users.where((u) {
      if (u == null) return false;
      
      try {
        // Users come as raw User objects
        final status = u['status'] ?? 'active';
        
        if (selectedTab == 'Active') {
          return status == 'active';
        } else if (selectedTab == 'Inactive') {
          return status == 'inactive';
        }
        return false;
      } catch (e) {
        print('Error filtering user: $e');
        return false;
      }
    }).toList();
  }

  @override
  void didUpdateWidget(RestaurantListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
  }


  Future<void> _fetchBranchRequests() async {
    setState(() {
      _isLoadingRequests = true;
      _requestsError = '';
    });
    try {
      final response = await BusinessManagementService.getPendingBranchRequests(page: _requestsPage, limit: _requestsLimit);
      if (response['status'] == 200 && response['data'] != null && response['data']['requests'] != null) {
        setState(() {
          _branchRequests = List<Map<String, dynamic>>.from(response['data']['requests']);
          _isLoadingRequests = false;
        });
      } else {
        setState(() {
          _requestsError = response['message'] ?? 'Failed to load requests';
          _isLoadingRequests = false;
        });
      }
    } catch (e) {
      setState(() {
        _requestsError = 'Error: ${e.toString()}';
        _isLoadingRequests = false;
      });
    }
  }

  Future<void> _processBranchRequest(String? id, String status, {String? adminNote}) async {
    if (id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Request ID is missing'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() {
      _isLoadingRequests = true;
    });
    try {
      final response = await BusinessManagementService.processBranchRequest(id: id, status: status, adminNote: adminNote);
      if (response['status'] == 200) {
        // Refresh list after processing
        await _fetchBranchRequests();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Request $status successfully'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to process request'), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() {
        _isLoadingRequests = false;
      });
    }
  }

  // Method to toggle company status using the new endpoint
  Future<bool> toggleCompanyStatusWithBranch(String companyId, String branchId, String currentStatus) async {
    print('Toggle company status: companyId=$companyId, branchId=$branchId, currentStatus=$currentStatus');
    try {
      final newStatus = currentStatus == 'active' ? 'inactive' : 'active';
      final adminService = AdminService(baseUrl: ApiService.secureBaseUrl);
      final result = await adminService.toggleCompanyBranchStatus(
        companyId: companyId,
        branchId: branchId,
        status: newStatus,
      );
      if (result['success']) {
        await _refreshDataSilently();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Status updated successfully'), backgroundColor: Colors.green),
        );
        return true;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update status:  [38;5;8m${result['message']} [0m'), backgroundColor: Colors.red),
        );
        return false;
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}'), backgroundColor: Colors.red),
      );
      return false;
    }
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
              logoPath: _logoPath,
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
                          'List of Companies',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1C4B),
                          ),
                        ),
                        const Spacer(),
                        // Notification icon with badge
                        
                         
                      ],
                    ),
                  ),
                  // The rest of the body content:
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          color: Colors.white,
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Column(
                            children: [
                              // Filter tabs
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Row(
                                  children: [
                                    buildTabButton('All'),
                                    const SizedBox(width: 12),
                                    buildTabButton('Active'),
                                    const SizedBox(width: 12),
                                    buildTabButton('Inactive'),
                                    const Spacer(),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.grey[100],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.file_download_outlined, color: Colors.black),
                                        onPressed: () {},
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                        iconSize: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.indigo[900],
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: IconButton(
                                        icon: const Icon(Icons.edit_note, color: Colors.white),
                                        onPressed: () {},
                                        padding: const EdgeInsets.all(8),
                                        constraints: const BoxConstraints(),
                                        iconSize: 22,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Main content
                        Expanded(
                          child: _isLoadingUsers
                                  ? const Center(child: CircularProgressIndicator())
                                  : _usersError.isNotEmpty
                                      ? Center(child: Text(_usersError, style: const TextStyle(color: Colors.red)))
                                      : Builder(
                                          builder: (context) {
                                            final filteredCompanies = getFilteredCompanies();
                                            final filteredServiceProviders = getFilteredServiceProviders();
                                            final filteredWholesalers = getFilteredWholesalers();
                                            final filteredUsers = getFilteredUsers();
                                            
                                            print('Filtered companies length: ${filteredCompanies.length}'); // Debug log
                                            print('Filtered service providers length: ${filteredServiceProviders.length}'); // Debug log
                                            print('Filtered wholesalers length: ${filteredWholesalers.length}'); // Debug log
                                            print('Filtered users length: ${filteredUsers.length}'); // Debug log
                                            print('Selected tab: $selectedTab'); // Debug log
                                            
                                            final allEntities = [
                                              ...filteredCompanies.map((c) => {'type': 'company', 'data': c}),
                                              ...filteredServiceProviders.map((sp) => {'type': 'serviceProvider', 'data': sp}),
                                              ...filteredWholesalers.map((w) => {'type': 'wholesaler', 'data': w}),
                                            ];
                                            
                                            if (allEntities.isEmpty) {
                                              return const Center(
                                                child: Text('No entities found for the selected filter.'),
                                              );
                                            }
                                            
                                            return ListView.builder(
                                              padding: const EdgeInsets.all(12),
                                              itemCount: allEntities.length,
                                              itemBuilder: (context, index) {
                                                final entity = allEntities[index];
                                                final type = entity['type'] as String;
                                                final data = entity['data'];
                                                try {
                                                  if (data == null) {
                                                    return const SizedBox.shrink(); // Skip null entities
                                                  }
                                                  
                                                  // Handle different entity types
                                                  String name = 'N/A';
                                                  String address = 'N/A';
                                                  String? entityId;
                                                  String? currentStatus;
                                                  String entityType = type;
                                                  String? branchId;
                                                  
                                                  if (type == 'company') {
                                                    // Companies now come in enriched format
                                                    Map<String, dynamic>? companyData;
                                                    if (data['company'] != null && data['company'] is Map<String, dynamic>) {
                                                      companyData = data['company'];
                                                    } else if (data['businessName'] != null) {
                                                      companyData = data;
                                                    }
                                                    if (companyData != null && companyData['branches'] != null && companyData['branches'] is List && (companyData['branches'] as List).isNotEmpty) {
                                                      final firstBranch = (companyData['branches'] as List).first;
                                                      if (firstBranch is Map<String, dynamic>) {
                                                        // Capture branch ID
                                                        if (firstBranch['id'] != null) {
                                                          branchId = firstBranch['id'];
                                                        }
                                                        // Prefer branch status if provided
                                                        currentStatus = firstBranch['status'] ?? 'active';
                                                      }
                                                    }
                                                    // Fallback to company level information where needed
                                                    if (companyData != null) {
                                                      name = companyData['businessName'] ?? companyData['name'] ?? 'N/A';
                                                      address = companyData['contactInfo']?['address']?['city'] ?? 'N/A';
                                                      entityId = companyData['id'];
                                                      // If branch status not set, use company status
                                                      currentStatus ??= companyData['status'] ?? 'active';
                                                    }
                                                  } else if (type == 'serviceProvider') {
                                                    print('  Processing ServiceProvider data type: ${data.runtimeType}'); // Debug log
                                                    
                                                    // Service providers now come in enriched format
                                                    if (data is Map<String, dynamic>) {
                                                      Map<String, dynamic>? spData;
                                                      if (data['serviceProvider'] != null && data['serviceProvider'] is Map<String, dynamic>) {
                                                        spData = data['serviceProvider'];
                                                      } else if (data['businessName'] != null || data['fullName'] != null) {
                                                        spData = data;
                                                      }
                                                      
                                                      if (spData != null) {
                                                        // Use businessName, contactPerson, or fullName in that order
                                                        name = spData['businessName'] ?? spData['contactPerson'] ?? spData['fullname'] ?? spData['fullName'] ?? spData['name'] ?? 'N/A';
                                                        address = spData['contactInfo']?['address']?['city'] ?? spData['city'] ?? 'N/A';
                                                        entityId = spData['id'];
                                                        currentStatus = spData['status'] ?? 'active';
                                                        
                                                        print('  ServiceProvider from Map - ID: $entityId, Name: $name, Status: $currentStatus'); // Debug log
                                                      }
                                                    }
                                                  } else if (type == 'wholesaler') {
                                                    // Wholesalers now come in enriched format
                                                    if (data is Map<String, dynamic>) {
                                                      Map<String, dynamic>? wholesalerData;
                                                      if (data['wholesaler'] != null && data['wholesaler'] is Map<String, dynamic>) {
                                                        wholesalerData = data['wholesaler'];
                                                      } else if (data['businessName'] != null) {
                                                        wholesalerData = data;
                                                      }
                                                      
                                                      if (wholesalerData != null) {
                                                        name = wholesalerData['businessName'] ?? wholesalerData['name'] ?? 'N/A';
                                                        address = wholesalerData['contactInfo']?['address']?['city'] ?? 'N/A';
                                                        entityId = wholesalerData['id'];
                                                        currentStatus = wholesalerData['status'] ?? 'active';
                                                      }
                                                    }
                                                  } else if (type == 'user') {
                                                    // Users come as raw User objects
                                                    if (data is Map<String, dynamic>) {
                                                      name = data['fullName'] ?? data['name'] ?? 'N/A';
                                                      address = data['email'] ?? 'N/A'; // Use email as address for users
                                                      entityId = data['id'];
                                                      currentStatus = data['status'] ?? 'active';
                                                    }
                                                  }
                                                  
                                                  final isActive = currentStatus == 'active';
                                                  
                                                  print('Creating RestaurantCard:'); // Debug log
                                                  print('  Name: $name'); // Debug log
                                                  print('  Entity ID: $entityId'); // Debug log
                                                  print('  Current Status: $currentStatus'); // Debug log
                                                  print('  Entity Type: $entityType'); // Debug log
                                                  print('  Is Active: $isActive'); // Debug log
                                                  print('  Has onStatusToggle: ${entityId != null && currentStatus != null}'); // Debug log
                                                  
                                                  return RestaurantCard(
                                                    name: name,
                                                    address: address,
                                                    isActive: isActive,
                                                    logo: 'roadster', // Placeholder, adapt as needed
                                                    hasInfo: true, // Placeholder, adapt as needed
                                                    onStatusToggle: (type == 'company' && entityId != null && branchId != null && currentStatus != null)
                                                        ? () => toggleCompanyStatusWithBranch(entityId!, branchId!, currentStatus!)
                                                        : (entityId != null && currentStatus != null)
                                                            ? () => toggleEntityStatus(entityType, entityId!, currentStatus!)
                                                            : null,
                                                    onDelete: entityId != null
                                                        ? () => _showDeleteConfirmation(entityId!, name, entityType)
                                                        : null,
                                                  );
                                                } catch (e) {
                                                  print('Error building entity card: $e');
                                                  return const SizedBox.shrink();
                                                }
                                              },
                                            );
                                          },
                                        ),
                        ),
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

  Widget buildTabButton(String title) {
    final isSelected = selectedTab == title;

    return InkWell(
      onTap: () => _onTabSelected(title),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? Colors.blue : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isSelected ? Colors.blue : Colors.grey,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildRequestsTab() {
    if (_isLoadingRequests) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_requestsError.isNotEmpty) {
      return Center(child: Text(_requestsError, style: const TextStyle(color: Colors.red)));
    }
    if (_branchRequests.isEmpty) {
      return const Center(child: Text('No pending branch requests.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: _branchRequests.length,
      itemBuilder: (context, index) {
        final req = _branchRequests[index];
        final requestId = req['_id'] ?? req['id'];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            title: Text('Branch: ${req['branchData']?['name'] ?? 'N/A'}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Company: ${req['companyName'] ?? 'N/A'}'),
                Text('Submitted: ${req['submittedAt'] ?? 'N/A'}'),
                if (req['adminNote'] != null && req['adminNote'].toString().isNotEmpty)
                  Text('Admin Note: ${req['adminNote']}'),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.check, color: Colors.green),
                  tooltip: 'Approve',
                  onPressed: requestId != null
                      ? () => _processBranchRequest(requestId, 'approved')
                      : null,
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.red),
                  tooltip: 'Reject',
                  onPressed: requestId != null
                      ? () => _processBranchRequest(requestId, 'rejected')
                      : null,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class RestaurantCard extends StatefulWidget {
  final String name;
  final String address;
  final bool isActive;
  final String logo;
  final bool hasInfo;
  final Future<bool> Function()? onStatusToggle;
  final VoidCallback? onDelete;

  const RestaurantCard({
    Key? key,
    required this.name,
    required this.address,
    required this.isActive,
    required this.logo,
    required this.hasInfo,
    this.onStatusToggle,
    this.onDelete,
  }) : super(key: key);

  @override
  State<RestaurantCard> createState() => _RestaurantCardState();
}

class _RestaurantCardState extends State<RestaurantCard> {
  bool _isLoading = false;
  bool _localIsActive = false;

  @override
  void initState() {
    super.initState();
    _localIsActive = widget.isActive;
  }

  @override
  void didUpdateWidget(RestaurantCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _localIsActive = widget.isActive;
    }
  }

  Future<void> _handleStatusToggle() async {
    if (_isLoading || widget.onStatusToggle == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Call the parent's status toggle function
      final success = await widget.onStatusToggle!();
      
      // If the API call was successful (200 response), update the local state
      if (success) {
        setState(() {
          _localIsActive = !_localIsActive;
          _isLoading = false;
        });
      } else {
        // If the API call failed, just stop loading
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      // If there's an error, revert the loading state
      setState(() {
        _isLoading = false;
      });
      // The error will be handled by the parent function
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;
    
    return Container(
      width: double.infinity, // Make card stretch full width
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Logo container - responsive sizing
          Container(
            width: isSmallScreen ? 40 : 50,
            height: isSmallScreen ? 40 : 50,
            padding: const EdgeInsets.all(4),
            margin: EdgeInsets.all(isSmallScreen ? 6 : 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300, width: 0.5),
            ),
            child: _getLogo(widget.logo),
          ),

          // Restaurant details
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: _getContainerColor(),
                borderRadius: const BorderRadius.horizontal(right: Radius.circular(12)),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: isSmallScreen ? 8 : 12, 
                vertical: isSmallScreen ? 8 : 12
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 14 : 16,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 2,
                        ),
                        SizedBox(height: isSmallScreen ? 2 : 4),
                        Row(
                          children: [
                            Text(
                              'Address: ',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: isSmallScreen ? 11 : 13,
                              ),
                            ),
                            Expanded(
                              child: Text(
                                widget.address,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: isSmallScreen ? 11 : 13,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Info icon if applicable
                  if (widget.hasInfo)
                    Container(
                      width: isSmallScreen ? 20 : 24,
                      height: isSmallScreen ? 20 : 24,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.info_outline,
                        color: Colors.white,
                        size: isSmallScreen ? 14 : 16,
                      ),
                    ),

                  SizedBox(width: isSmallScreen ? 8 : 12),

                  // Status button
                  GestureDetector(
                    onTap: _isLoading ? null : _handleStatusToggle,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isSmallScreen ? 8 : 12, 
                        vertical: isSmallScreen ? 4 : 6
                      ),
                      decoration: BoxDecoration(
                        color: _localIsActive ? Colors.green : Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                        border: widget.onStatusToggle != null ? Border.all(color: Colors.white, width: 1) : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoading)
                            SizedBox(
                              width: isSmallScreen ? 10 : 12,
                              height: isSmallScreen ? 10 : 12,
                              child: const CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          else ...[
                            Text(
                              _localIsActive ? 'Active' : 'Not Active',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: isSmallScreen ? 10 : 12,
                              ),
                            ),
                            if (widget.onStatusToggle != null) ...[
                              SizedBox(width: isSmallScreen ? 2 : 4),
                              Icon(
                                Icons.swap_horiz,
                                color: Colors.white,
                                size: isSmallScreen ? 10 : 12,
                              ),
                            ],
                          ],
                        ],
                      ),
                    ),
                  ),

                  SizedBox(width: isSmallScreen ? 6 : 8),

                  // Delete button
                  if (widget.onDelete != null)
                    GestureDetector(
                      onTap: () {
                        print('Delete button tapped!'); // Debug log
                        widget.onDelete!();
                      },
                      child: Container(
                        padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.white, width: 1),
                        ),
                        child: Icon(
                          Icons.delete,
                          color: Colors.white,
                          size: isSmallScreen ? 14 : 16,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getContainerColor() {
    switch (widget.logo) {
      case 'roadster':
        return const Color(0xFF0D1D3D);
      case 'pizzanini':
        return const Color(0xFFD71F26);
      case 'burger_king':
        return const Color(0xFF0D1D3D);
      case 'pizza_hut':
        return const Color(0xFF0D1D3D);
      default:
        return Colors.blueGrey;
    }
  }

  Widget _getLogo(String logo) {
    // In a real app, you would use actual images
    // For this example, we'll create placeholder colored containers with text
    switch (logo) {
      case 'roadster':
        return Container(
          color: Colors.white,
          child: const Center(
            child: Text(
              'R',
              style: TextStyle(
                color: Color(0xFF0D1D3D),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case 'pizzanini':
        return Container(
          color: const Color(0xFFD71F26),
          child: const Center(
            child: Text(
              'P',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      case 'burger_king':
        return Container(
          color: Colors.white,
          child: const Center(
            child: Text(
              'BK',
              style: TextStyle(
                color: Color(0xFFD71F26),
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        );
      case 'pizza_hut':
        return Container(
          color: const Color(0xFFD71F26),
          child: const Center(
            child: Text(
              'PH',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 10,
              ),
            ),
          ),
        );
      default:
        return Container(
          color: Colors.grey,
          child: const Center(
            child: Text(
              '?',
              style: TextStyle(color: Colors.white),
            ),
          ),
        );
    }
  }
}