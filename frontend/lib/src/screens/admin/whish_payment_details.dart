import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/admin_service.dart';
import '../../components/header.dart';
import '../../components/sidebar.dart';

class WhishPaymentDetailsScreen extends StatefulWidget {
  const WhishPaymentDetailsScreen({super.key});

  @override
  State<WhishPaymentDetailsScreen> createState() => _WhishPaymentDetailsScreenState();
}

class _WhishPaymentDetailsScreenState extends State<WhishPaymentDetailsScreen> {
  final AdminService _adminService = AdminService(baseUrl: 'http://barrim.online:8081');
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSidebarExpanded = false;
  List<dynamic> _allPayments = [];
  List<dynamic> _filteredPayments = [];
  String? _errorMessage;
  String _selectedTypeFilter = 'All';
  String _selectedStatusFilter = 'All';

  @override
  void initState() {
    super.initState();
    _loadPayments();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadPayments() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _adminService.getAllWhishPayments();
      
      if (result['success'] == true) {
        final data = result['data'];
        setState(() {
          _allPayments = data['payments'] ?? [];
          _filteredPayments = _allPayments;
        });
        _applyFilters();
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to fetch payments';
          _allPayments = [];
          _filteredPayments = [];
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _allPayments = [];
        _filteredPayments = [];
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _applyFilters() {
    setState(() {
      _filteredPayments = _allPayments.where((payment) {
        // Type filter
        if (_selectedTypeFilter != 'All') {
          final paymentType = payment['type']?.toString() ?? '';
          if (!paymentType.contains(_selectedTypeFilter.toLowerCase().replaceAll(' ', '_'))) {
            return false;
          }
        }

        // Status filter
        if (_selectedStatusFilter != 'All') {
          final paymentStatus = payment['paymentStatus']?.toString().toLowerCase() ?? '';
          if (paymentStatus != _selectedStatusFilter.toLowerCase()) {
            return false;
          }
        }

        // Search filter
        final searchTerm = _searchController.text.toLowerCase();
        if (searchTerm.isNotEmpty) {
          final externalId = payment['externalId']?.toString() ?? '';
          final userEmail = payment['user']?['email']?.toString().toLowerCase() ?? '';
          final userFullName = payment['user']?['fullName']?.toString().toLowerCase() ?? '';
          final subscriptionId = payment['subscriptionId']?.toString() ?? '';
          
          if (!externalId.contains(searchTerm) &&
              !userEmail.contains(searchTerm) &&
              !userFullName.contains(searchTerm) &&
              !subscriptionId.contains(searchTerm)) {
            return false;
          }
        }

        return true;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      body: Stack(
        children: [
          // Main Content
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
                
                // Header Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Whish Payment Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[800],
                          ),
                        ),
                      ),
                      if (!_isLoading)
                        Text(
                          'Total: ${_allPayments.length}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[700],
                          ),
                        ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _isLoading ? null : _loadPayments,
                        tooltip: 'Refresh',
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Filters Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          // Search
                          TextField(
                            controller: _searchController,
                            decoration: InputDecoration(
                              labelText: 'Search',
                              hintText: 'Search by External ID, Email, Name, or Subscription ID',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              prefixIcon: const Icon(Icons.search),
                              suffixIcon: _searchController.text.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(Icons.clear),
                                      onPressed: () {
                                        _searchController.clear();
                                        _applyFilters();
                                      },
                                    )
                                  : null,
                            ),
                            onChanged: (_) => _applyFilters(),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Type and Status Filters
                          Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedTypeFilter,
                                  decoration: InputDecoration(
                                    labelText: 'Type',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: [
                                    'All',
                                    'Service Provider',
                                    'Company Branch',
                                    'Wholesaler Branch',
                                    'Sponsorship',
                                  ].map((type) {
                                    return DropdownMenuItem(
                                      value: type,
                                      child: Text(type),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedTypeFilter = value ?? 'All';
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  value: _selectedStatusFilter,
                                  decoration: InputDecoration(
                                    labelText: 'Payment Status',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  items: [
                                    'All',
                                    'Paid',
                                    'Pending',
                                    'Failed',
                                    'Cancelled',
                                  ].map((status) {
                                    return DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    );
                                  }).toList(),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedStatusFilter = value ?? 'All';
                                    });
                                    _applyFilters();
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Results Section
                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : _errorMessage != null
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      size: 64,
                                      color: Colors.red[300],
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      _errorMessage!,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: Colors.red[700],
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                    const SizedBox(height: 16),
                                    ElevatedButton(
                                      onPressed: _loadPayments,
                                      child: const Text('Retry'),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : _filteredPayments.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.payment_outlined,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        _allPayments.isEmpty
                                            ? 'No payments found'
                                            : 'No payments match your filters',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 16),
                                  itemCount: _filteredPayments.length,
                                  itemBuilder: (context, index) {
                                    return _buildPaymentCard(_filteredPayments[index]);
                                  },
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

  Widget _buildPaymentCard(Map<String, dynamic> payment) {
    final type = payment['type']?.toString() ?? 'Unknown';
    final externalId = payment['externalId']?.toString() ?? 'N/A';
    final paymentStatus = payment['paymentStatus']?.toString() ?? 'Unknown';
    final whishStatus = payment['whishStatus']?.toString() ?? 'N/A';
    final user = payment['user'] as Map<String, dynamic>?;
    final plan = payment['plan'] as Map<String, dynamic>?;
    final branch = payment['branch'] as Map<String, dynamic>?;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        leading: Icon(
          Icons.payment,
          color: _getPaymentStatusColor(paymentStatus),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'External ID: $externalId',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _getTypeDisplayName(type),
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getPaymentStatusColor(paymentStatus).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPaymentStatusColor(paymentStatus),
                    width: 1,
                  ),
                ),
                child: Text(
                  paymentStatus,
                  style: TextStyle(
                    color: _getPaymentStatusColor(paymentStatus),
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ),
              if (whishStatus != 'N/A' && whishStatus.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Whish: $whishStatus',
                    style: TextStyle(
                      color: Colors.blue[900],
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Information
                if (user != null) ...[
                  _buildSectionTitle('User Information'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Name', user['fullName']?.toString() ?? 'N/A'),
                  _buildDetailRow('Email', user['email']?.toString() ?? 'N/A'),
                  _buildDetailRow('Phone', user['phone']?.toString() ?? 'N/A'),
                  _buildDetailRow('User Type', user['userType']?.toString() ?? 'N/A'),
                  const SizedBox(height: 16),
                ],

                // Plan Information
                if (plan != null) ...[
                  _buildSectionTitle('Plan Information'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Plan Title', plan['title']?.toString() ?? 'N/A'),
                  _buildDetailRow('Price', plan['price']?.toString() ?? 'N/A'),
                  _buildDetailRow('Plan Type', plan['type']?.toString() ?? 'N/A'),
                  const SizedBox(height: 16),
                ],

                // Branch Information (if applicable)
                if (branch != null) ...[
                  _buildSectionTitle('Branch Information'),
                  const SizedBox(height: 8),
                  _buildDetailRow('Branch Name', branch['name']?.toString() ?? 'N/A'),
                  _buildDetailRow('Category', branch['category']?.toString() ?? 'N/A'),
                  _buildDetailRow('Phone', branch['phone']?.toString() ?? 'N/A'),
                  const SizedBox(height: 16),
                ],

                // Payment Details
                _buildSectionTitle('Payment Details'),
                const SizedBox(height: 8),
                _buildDetailRow('Subscription ID', payment['subscriptionId']?.toString() ?? 'N/A'),
                _buildDetailRow('Status', payment['status']?.toString() ?? 'N/A',
                    valueColor: _getStatusColor(payment['status']?.toString() ?? '')),
                _buildDetailRow('Whish Status', whishStatus),
                if (payment['whishPhoneNumber'] != null)
                  _buildDetailRow('Whish Phone', payment['whishPhoneNumber']?.toString() ?? 'N/A'),
                if (payment['collectUrl'] != null)
                  _buildDetailRow('Collect URL', payment['collectUrl']?.toString() ?? 'N/A'),
                if (payment['requestedAt'] != null)
                  _buildDetailRow('Requested At', _formatDate(payment['requestedAt'])),
                if (payment['paidAt'] != null)
                  _buildDetailRow('Paid At', _formatDate(payment['paidAt'])),

                // Sponsorship-specific fields
                if (type == 'sponsorship_subscription') ...[
                  const SizedBox(height: 16),
                  _buildSectionTitle('Sponsorship Details'),
                  const SizedBox(height: 8),
                  if (payment['sponsorshipId'] != null)
                    _buildDetailRow('Sponsorship ID', payment['sponsorshipId']?.toString() ?? 'N/A'),
                  if (payment['entityType'] != null)
                    _buildDetailRow('Entity Type', payment['entityType']?.toString() ?? 'N/A'),
                  if (payment['entityId'] != null)
                    _buildDetailRow('Entity ID', payment['entityId']?.toString() ?? 'N/A'),
                  if (payment['entityName'] != null)
                    _buildDetailRow('Entity Name', payment['entityName']?.toString() ?? 'N/A'),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: valueColor ?? Colors.black87,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getTypeDisplayName(String type) {
    switch (type) {
      case 'service_provider_subscription':
        return 'Service Provider Subscription';
      case 'company_branch_subscription':
        return 'Company Branch Subscription';
      case 'wholesaler_branch_subscription':
        return 'Wholesaler Branch Subscription';
      case 'sponsorship_subscription':
        return 'Sponsorship Subscription';
      default:
        return type.replaceAll('_', ' ').toUpperCase();
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
      case 'approved':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getPaymentStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
      case 'completed':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'failed':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(dynamic dateValue) {
    if (dateValue == null) return 'N/A';
    
    try {
      if (dateValue is String) {
        final dateTime = DateTime.parse(dateValue);
        return DateFormat('MMM dd, yyyy HH:mm:ss').format(dateTime);
      } else if (dateValue is int) {
        final dateTime = DateTime.fromMillisecondsSinceEpoch(dateValue);
        return DateFormat('MMM dd, yyyy HH:mm:ss').format(dateTime);
      }
      return dateValue.toString();
    } catch (e) {
      return dateValue.toString();
    }
  }
}
