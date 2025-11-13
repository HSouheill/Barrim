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
  final TextEditingController _externalIdController = TextEditingController();
  
  bool _isLoading = false;
  bool _isSidebarExpanded = false;
  Map<String, dynamic>? _paymentDetails;
  String? _errorMessage;

  @override
  void dispose() {
    _externalIdController.dispose();
    super.dispose();
  }

  Future<void> _fetchPaymentDetails() async {
    final externalId = _externalIdController.text.trim();
    
    if (externalId.isEmpty) {
      setState(() {
        _errorMessage = 'Please enter an external ID';
        _paymentDetails = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _paymentDetails = null;
    });

    try {
      final result = await _adminService.getWhishPaymentDetails(externalId);
      
      if (result['success'] == true || result['statusCode'] == 200 || result['statusCode'] == 404) {
        setState(() {
          _paymentDetails = result['data'];
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to fetch payment details';
          _paymentDetails = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
        _paymentDetails = null;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
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
                
                // Search Section
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Card(
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Whish Payment Details',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _externalIdController,
                                  decoration: InputDecoration(
                                    labelText: 'External ID',
                                    hintText: 'Enter payment external ID',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    prefixIcon: const Icon(Icons.search),
                                  ),
                                  keyboardType: TextInputType.number,
                                  onSubmitted: (_) => _fetchPaymentDetails(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                onPressed: _isLoading ? null : _fetchPaymentDetails,
                                icon: _isLoading
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                        ),
                                      )
                                    : const Icon(Icons.search),
                                label: Text(_isLoading ? 'Loading...' : 'Search'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue[600],
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
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
                                  ],
                                ),
                              ),
                            )
                          : _paymentDetails == null
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search,
                                        size: 64,
                                        color: Colors.grey[400],
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Enter an external ID to search for payment details',
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : _buildPaymentDetailsCard(),
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

  Widget _buildPaymentDetailsCard() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  const Icon(Icons.payment, size: 32, color: Colors.blue),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment Details',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (_paymentDetails?['externalId'] != null)
                          Text(
                            'External ID: ${_paymentDetails!['externalId']}',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const Divider(height: 32),
              
              // Whish API Information
              _buildSectionTitle('Whish API Information'),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Whish Status',
                _paymentDetails?['whishStatus']?.toString() ?? 'N/A',
                Icons.info_outline,
              ),
              const SizedBox(height: 8),
              _buildInfoRow(
                'Phone Number',
                _paymentDetails?['phoneNumber']?.toString() ?? 'N/A',
                Icons.phone,
              ),
              
              const SizedBox(height: 24),
              
              // Database Information
              _buildSectionTitle('Database Information'),
              const SizedBox(height: 12),
              _buildInfoRow(
                'Found In',
                _paymentDetails?['foundIn']?.toString() ?? 'Not found in database',
                Icons.storage,
                valueColor: _paymentDetails?['foundIn'] != null ? Colors.green : Colors.orange,
              ),
              
              // Payment Record Details
              if (_paymentDetails?['paymentRecord'] != null) ...[
                const SizedBox(height: 24),
                _buildSectionTitle('Payment Record'),
                const SizedBox(height: 12),
                _buildPaymentRecordDetails(_paymentDetails!['paymentRecord']),
              ] else ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: Colors.orange[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No payment record found in database',
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue[800],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    color: valueColor ?? Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentRecordDetails(Map<String, dynamic> paymentRecord) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Type Badge
          if (paymentRecord['type'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                paymentRecord['type'].toString().replaceAll('_', ' ').toUpperCase(),
                style: TextStyle(
                  color: Colors.blue[900],
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          
          const SizedBox(height: 16),
          
          // ID
          if (paymentRecord['id'] != null)
            _buildDetailRow('ID', paymentRecord['id'].toString()),
          
          // Type-specific fields
          if (paymentRecord['serviceProviderId'] != null)
            _buildDetailRow('Service Provider ID', paymentRecord['serviceProviderId'].toString()),
          
          if (paymentRecord['branchId'] != null)
            _buildDetailRow('Branch ID', paymentRecord['branchId'].toString()),
          
          if (paymentRecord['sponsorshipId'] != null)
            _buildDetailRow('Sponsorship ID', paymentRecord['sponsorshipId'].toString()),
          
          if (paymentRecord['entityType'] != null)
            _buildDetailRow('Entity Type', paymentRecord['entityType'].toString()),
          
          if (paymentRecord['entityId'] != null)
            _buildDetailRow('Entity ID', paymentRecord['entityId'].toString()),
          
          if (paymentRecord['entityName'] != null)
            _buildDetailRow('Entity Name', paymentRecord['entityName'].toString()),
          
          if (paymentRecord['planId'] != null)
            _buildDetailRow('Plan ID', paymentRecord['planId'].toString()),
          
          // Status fields
          if (paymentRecord['status'] != null)
            _buildDetailRow(
              'Status',
              paymentRecord['status'].toString(),
              valueColor: _getStatusColor(paymentRecord['status'].toString()),
            ),
          
          if (paymentRecord['paymentStatus'] != null)
            _buildDetailRow(
              'Payment Status',
              paymentRecord['paymentStatus'].toString(),
              valueColor: _getPaymentStatusColor(paymentRecord['paymentStatus'].toString()),
            ),
          
          // URLs and Dates
          if (paymentRecord['collectUrl'] != null)
            _buildDetailRow('Collect URL', paymentRecord['collectUrl'].toString()),
          
          if (paymentRecord['requestedAt'] != null)
            _buildDetailRow(
              'Requested At',
              _formatDate(paymentRecord['requestedAt']),
            ),
          
          if (paymentRecord['paidAt'] != null)
            _buildDetailRow(
              'Paid At',
              _formatDate(paymentRecord['paidAt']),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
        // Try to parse ISO 8601 format
        final dateTime = DateTime.parse(dateValue);
        return DateFormat('MMM dd, yyyy HH:mm:ss').format(dateTime);
      } else if (dateValue is int) {
        // Assume it's a timestamp
        final dateTime = DateTime.fromMillisecondsSinceEpoch(dateValue);
        return DateFormat('MMM dd, yyyy HH:mm:ss').format(dateTime);
      }
      return dateValue.toString();
    } catch (e) {
      return dateValue.toString();
    }
  }
}

