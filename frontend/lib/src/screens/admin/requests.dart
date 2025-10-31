import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/pending_request_models.dart';
import '../../services/admin_service.dart';
import '../../components/header.dart';
import '../../components/sidebar.dart';

class AdminRequestsScreen extends StatefulWidget {
  const AdminRequestsScreen({super.key});

  @override
  State<AdminRequestsScreen> createState() => _AdminRequestsScreenState();
}

class _AdminRequestsScreenState extends State<AdminRequestsScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService(baseUrl: 'https://barrim.online');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  bool _isLoading = true;
  bool _isSidebarExpanded = false;
  Set<String> _processingRequests = {}; // Track which requests are being processed
  
  List<PendingCompanyRequest> _pendingCompanyRequests = [];
  List<PendingWholesalerRequest> _pendingWholesalerRequests = [];
  List<PendingServiceProviderRequest> _pendingServiceProviderRequests = [];
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _processingRequests = <String>{}; // Ensure it's properly initialized
    _loadPendingRequests();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPendingRequests() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final result = await _adminService.getPendingRequestsFromAdminSalespersons();
      
      if (result['success'] == true) {
        final data = result['data'];
        
        // Parse company requests
        if (data['pendingCompanyRequests'] != null) {
          _pendingCompanyRequests = (data['pendingCompanyRequests'] as List)
              .map((json) => PendingCompanyRequest.fromJson(json))
              .toList();
        }
        
        // Parse wholesaler requests
        if (data['pendingWholesalerRequests'] != null) {
          _pendingWholesalerRequests = (data['pendingWholesalerRequests'] as List)
              .map((json) => PendingWholesalerRequest.fromJson(json))
              .toList();
        }
        
        // Parse service provider requests
        if (data['pendingServiceProviderRequests'] != null) {
          _pendingServiceProviderRequests = (data['pendingServiceProviderRequests'] as List)
              .map((json) => PendingServiceProviderRequest.fromJson(json))
              .toList();
        }
        
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to load pending requests'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading pending requests: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _processRequest({
    required String requestType,
    required String requestId,
    required String action,
  }) async {
    final requestKey = '${requestType}_$requestId';
    
    setState(() {
      _processingRequests.add(requestKey);
    });

    try {
      final result = await _adminService.processPendingRequest(
        requestType: requestType,
        requestId: requestId,
        action: action,
      );

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Request processed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Remove the specific request from the local list instead of reloading all
        _removeRequestFromList(requestType, requestId);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Failed to process request'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error processing request: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _processingRequests.remove(requestKey);
      });
    }
  }

  void _removeRequestFromList(String requestType, String requestId) {
    setState(() {
      switch (requestType.toLowerCase()) {
        case 'company':
          _pendingCompanyRequests.removeWhere((request) => request.id == requestId);
          break;
        case 'wholesaler':
          _pendingWholesalerRequests.removeWhere((request) => request.id == requestId);
          break;
        case 'serviceprovider':
          _pendingServiceProviderRequests.removeWhere((request) => request.id == requestId);
          break;
      }
    });
  }

  void _showProcessDialog({
    required String requestType,
    required String requestId,
    required String action,
  }) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('${action.capitalize()} Request'),
        content: Text('Are you sure you want to $action this $requestType request?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _processRequest(
                requestType: requestType,
                requestId: requestId,
                action: action,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: action == 'approve' ? Colors.green : Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(action.capitalize()),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              // TODO: Implement actual logout logic
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logout functionality not yet implemented.'),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                // Main Content (Full width)
                SafeArea(
                  child: Column(
                    children: [
                      // Header
                      HeaderComponent(
                        logoPath: 'assets/logo/logo.png',
                        scaffoldKey: _scaffoldKey,
                        backgroundColor: Colors.blue[800]!,
                        onMenuPressed: () {
                          setState(() {
                            _isSidebarExpanded = !_isSidebarExpanded;
                          });
                        },
                        isLogoutButton: false,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tab Bar
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[600],
                          indicator: BoxDecoration(
                            color: Colors.blue[600],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          isScrollable: false, // Prevent swiping and make tabs fit evenly
                          labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                          tabs: [
                            Tab(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.business, size: 18),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Companies\n(${_pendingCompanyRequests.length})',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.store, size: 18),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Wholesalers\n(${_pendingWholesalerRequests.length})',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            Tab(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.handyman, size: 18),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        'Service Providers\n(${_pendingServiceProviderRequests.length})',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tab Views
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildCompanyRequestsTab(),
                            _buildWholesalerRequestsTab(),
                            _buildServiceProviderRequestsTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Sidebar (Overlay on top)
                if (_isSidebarExpanded)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: Sidebar(
                      onCollapse: () {
                        setState(() {
                          _isSidebarExpanded = false;
                        });
                      },
                      parentContext: context,
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildCompanyRequestsTab() {
    if (_pendingCompanyRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending company requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _pendingCompanyRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingCompanyRequests[index];
        return _buildRequestCard(
          title: request.company.businessName,
          subtitle: request.company.fullname,
          email: request.email,
          category: request.company.category,
          subCategory: request.company.subCategory,
          phone: request.company.contactInfo.phone,
          address: request.company.contactInfo.address,
          createdAt: request.createdAt,
          requestId: request.id,
          requestType: 'company',
          onApprove: () => _showProcessDialog(
            requestType: 'company',
            requestId: request.id,
            action: 'approve',
          ),
          onReject: () => _showProcessDialog(
            requestType: 'company',
            requestId: request.id,
            action: 'reject',
          ),
        );
      },
    );
  }

  Widget _buildWholesalerRequestsTab() {
    if (_pendingWholesalerRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending wholesaler requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _pendingWholesalerRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingWholesalerRequests[index];
        return _buildRequestCard(
          title: request.wholesaler.businessName,
          subtitle: request.wholesaler.fullname,
          email: request.email,
          category: request.wholesaler.category,
          subCategory: request.wholesaler.subCategory,
          phone: request.wholesaler.contactInfo.phone,
          address: request.wholesaler.contactInfo.address,
          createdAt: request.createdAt,
          requestId: request.id,
          requestType: 'wholesaler',
          onApprove: () => _showProcessDialog(
            requestType: 'wholesaler',
            requestId: request.id,
            action: 'approve',
          ),
          onReject: () => _showProcessDialog(
            requestType: 'wholesaler',
            requestId: request.id,
            action: 'reject',
          ),
        );
      },
    );
  }

  Widget _buildServiceProviderRequestsTab() {
    if (_pendingServiceProviderRequests.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'No pending service provider requests',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: _pendingServiceProviderRequests.length,
      itemBuilder: (context, index) {
        final request = _pendingServiceProviderRequests[index];
        return _buildRequestCard(
          title: request.serviceProvider.businessName,
          subtitle: request.serviceProvider.fullname,
          email: request.email,
          category: request.serviceProvider.category,
          subCategory: request.serviceProvider.subCategory,
          phone: request.serviceProvider.contactInfo.phone,
          address: request.serviceProvider.contactInfo.address,
          createdAt: request.createdAt,
          requestId: request.id,
          requestType: 'serviceprovider',
          onApprove: () => _showProcessDialog(
            requestType: 'serviceprovider',
            requestId: request.id,
            action: 'approve',
          ),
          onReject: () => _showProcessDialog(
            requestType: 'serviceprovider',
            requestId: request.id,
            action: 'reject',
          ),
        );
      },
    );
  }

  Widget _buildRequestCard({
    required String title,
    required String subtitle,
    required String email,
    required String category,
    String? subCategory,
    required String phone,
    required Address address,
    required DateTime createdAt,
    required VoidCallback onApprove,
    required VoidCallback onReject,
    String? requestId,
    String? requestType,
  }) {
    final requestKey = requestId != null && requestType != null ? '${requestType}_$requestId' : null;
    final isThisRequestProcessing = requestKey != null && _processingRequests.contains(requestKey);
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Pending',
                    style: TextStyle(
                      color: Colors.orange[800],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Contact Information
            _buildInfoRow(Icons.email, email, maxLines: 2),
            const SizedBox(height: 8),
            _buildInfoRow(Icons.phone, phone),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.location_on,
              '${address.street}, ${address.city}, ${address.state}, ${address.country}',
              maxLines: 3,
            ),
            
            const SizedBox(height: 16),
            
            // Category Information
            _buildInfoRow(
              Icons.category,
              subCategory != null ? '$category - $subCategory' : category,
              maxLines: 2,
            ),
            const SizedBox(height: 8),
            _buildInfoRow(
              Icons.schedule,
              'Requested on ${DateFormat('MMM dd, yyyy').format(createdAt)}',
              textColor: Colors.grey[600],
            ),
            
            const SizedBox(height: 20),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isThisRequestProcessing ? null : onApprove,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: isThisRequestProcessing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.check),
                    label: Text(isThisRequestProcessing ? 'Processing...' : 'Approve'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isThisRequestProcessing ? null : onReject,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: isThisRequestProcessing 
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Icon(Icons.close),
                    label: Text(isThisRequestProcessing ? 'Processing...' : 'Reject'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text, {int? maxLines, Color? textColor}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(color: textColor),
            overflow: TextOverflow.ellipsis,
            maxLines: maxLines,
          ),
        ),
      ],
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}
