import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/withdrawal_model.dart';
import '../services/withdrawal_service.dart';
import '../services/api_services.dart';
import '../utils/secure_storage.dart';
import '../components/header.dart';
import '../components/sidebar.dart';

class AdminWithdrawsScreen extends StatefulWidget {
  const AdminWithdrawsScreen({super.key});

  @override
  State<AdminWithdrawsScreen> createState() => _AdminWithdrawsScreenState();
}

class _AdminWithdrawsScreenState extends State<AdminWithdrawsScreen> {
  final WithdrawalService _withdrawalService = WithdrawalService(
    baseUrl: ApiService.baseUrl,
  );
  
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  List<EnrichedWithdrawal> _withdrawals = [];
  bool _isLoading = false;
  bool _isRefreshing = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadWithdrawals();
  }

  Future<void> _loadWithdrawals() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final result = await _withdrawalService.getPendingWithdrawalRequests();
      
      if (result['success']) {
        setState(() {
          _withdrawals = List<EnrichedWithdrawal>.from(result['data'] ?? []);
          _errorMessage = null;
        });
      } else {
        setState(() {
          _errorMessage = result['message'] ?? 'Failed to load withdrawal requests';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshWithdrawals() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    await _loadWithdrawals();
    
    setState(() {
      _isRefreshing = false;
    });
  }

  Future<void> _approveWithdrawal(EnrichedWithdrawal enrichedWithdrawal) async {
    final TextEditingController noteController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Approve Withdrawal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Approve withdrawal request for ${enrichedWithdrawal.user['fullName'] ?? 'User'}?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Amount:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${enrichedWithdrawal.withdrawal.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, color: Colors.green),
              ),
              const SizedBox(height: 16),
              const Text(
                'Admin Note (Optional):',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText: 'Enter approval note...',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Approve'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _processApproval(enrichedWithdrawal, noteController.text);
    }
  }

  Future<void> _rejectWithdrawal(EnrichedWithdrawal enrichedWithdrawal) async {
    final TextEditingController noteController = TextEditingController();
    
    final result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Reject Withdrawal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Reject withdrawal request for ${enrichedWithdrawal.user['fullName'] ?? 'User'}?',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 16),
              const Text(
                'Amount:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(
                '\$${enrichedWithdrawal.withdrawal.amount.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 18, color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                'Admin Note (Required):',
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: noteController,
                decoration: const InputDecoration(
                  hintText: 'Enter rejection reason...',
                  border: OutlineInputBorder(),
                  errorText: 'Note is required for rejection',
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: noteController.text.trim().isEmpty ? null : () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Reject'),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await _processRejection(enrichedWithdrawal, noteController.text);
    }
  }

  Future<void> _processApproval(EnrichedWithdrawal enrichedWithdrawal, String note) async {
    _showLoadingDialog('Approving withdrawal...');

    try {
      final result = await _withdrawalService.approveWithdrawalRequest(
        enrichedWithdrawal.withdrawal.id!,
        note,
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (result['success']) {
        _showSuccessDialog('Withdrawal Approved', result['message']);
        await _refreshWithdrawals();
      } else {
        _showErrorDialog('Approval Failed', result['message']);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Error', 'Failed to approve withdrawal: ${e.toString()}');
    }
  }

  Future<void> _processRejection(EnrichedWithdrawal enrichedWithdrawal, String note) async {
    _showLoadingDialog('Rejecting withdrawal...');

    try {
      final result = await _withdrawalService.rejectWithdrawalRequest(
        enrichedWithdrawal.withdrawal.id!,
        note,
      );

      Navigator.of(context).pop(); // Close loading dialog

      if (result['success']) {
        _showSuccessDialog('Withdrawal Rejected', result['message']);
        await _refreshWithdrawals();
      } else {
        _showErrorDialog('Rejection Failed', result['message']);
      }
    } catch (e) {
      Navigator.of(context).pop(); // Close loading dialog
      _showErrorDialog('Error', 'Failed to reject withdrawal: ${e.toString()}');
    }
  }

  void _showLoadingDialog(String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              const CircularProgressIndicator(),
              const SizedBox(width: 16),
              Text(message),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog(String title, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  String _getUserTypeDisplay(String userType) {
    switch (userType) {
      case 'salesperson':
        return 'Salesperson';
      case 'sales_manager':
        return 'Sales Manager';
      default:
        return userType;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
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
                  const SizedBox(height: 10),
                              HeaderComponent(
              logoPath: _logoPath,
              scaffoldKey: _scaffoldKey,
              onMenuPressed: () {
                _scaffoldKey.currentState?.openEndDrawer();
              },
            ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Withdrawal Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1C4B),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _isRefreshing ? null : _refreshWithdrawals,
                          tooltip: 'Refresh',
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : _errorMessage != null
                            ? _buildErrorWidget()
                            : _withdrawals.isEmpty
                                ? _buildEmptyWidget()
                                : _buildWithdrawalsList(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget() {
    return Center(
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
            style: const TextStyle(fontSize: 16, color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadWithdrawals,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'No pending withdrawal requests',
            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'All withdrawal requests have been processed',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildWithdrawalsList() {
    return RefreshIndicator(
      onRefresh: _refreshWithdrawals,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _withdrawals.length,
        itemBuilder: (context, index) {
          final withdrawal = _withdrawals[index];
          return _buildWithdrawalCard(withdrawal);
        },
      ),
    );
  }

  Widget _buildWithdrawalCard(EnrichedWithdrawal enrichedWithdrawal) {
    final withdrawal = enrichedWithdrawal.withdrawal;
    final user = enrichedWithdrawal.user;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with user info and amount
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Colors.blue[100],
                  child: Text(
                    (user['fullName'] ?? 'U')[0].toUpperCase(),
                    style: TextStyle(
                      color: Colors.blue[800],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user['fullName'] ?? 'Unknown User',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getUserTypeDisplay(withdrawal.userType),
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getStatusColor(withdrawal.status),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    withdrawal.status.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Amount and date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Amount',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      '\$${withdrawal.amount.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'Requested',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey,
                      ),
                    ),
                    Text(
                      DateFormat('MMM dd, yyyy').format(withdrawal.createdAt),
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      DateFormat('HH:mm').format(withdrawal.createdAt),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // User contact info
            if (user['email'] != null || user['phone'] != null) ...[
              const Divider(),
              const SizedBox(height: 8),
              if (user['email'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      Icon(Icons.email, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 8),
                      Text(
                        user['email'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              if (user['phone'] != null)
                Row(
                  children: [
                    Icon(Icons.phone, size: 16, color: Colors.grey[600]),
                    const SizedBox(width: 8),
                    Text(
                      user['phone'],
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
            ],
            
            const SizedBox(height: 16),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _approveWithdrawal(enrichedWithdrawal),
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      'Approve',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _rejectWithdrawal(enrichedWithdrawal),
                    icon: const Icon(Icons.close, color: Colors.white),
                    label: const Text(
                      'Reject',
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
