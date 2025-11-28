import 'dart:io';
import 'package:admin_dashboard/src/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../components/header.dart';
import '../../../models/salesperson_model.dart';
import '../../../models/withdrawal_model.dart';
import '../../../services/sales_manager_service.dart';
import 'package:admin_dashboard/main.dart';
import '../../../components/sidebar.dart';
import '../../../components/request_sent_popup.dart';

class SalesManagerDashboard extends StatefulWidget {
  const SalesManagerDashboard({super.key});

  @override
  State<SalesManagerDashboard> createState() => _SalesManagerDashboardState();
}

class _SalesManagerDashboardState extends State<SalesManagerDashboard> {
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isDrawerOpen = false;
  int _selectedTabIndex = 0; // 0 for Salespersons, 1 for Commission

  final SalesManagerService _salesManagerService = SalesManagerService.instance;
  List<Salesperson> _salespersons = [];
  bool _isLoading = true;
  String? _error;

  // Commission summary state
  bool _isCommissionLoading = false;
  String? _commissionError;
  double _totalCommission = 0.0;
  double _totalWithdrawn = 0.0;
  double _availableBalance = 0.0;

  // Commission/withdrawal history state
  bool _isHistoryLoading = false;
  String? _historyError;
  List<Commission> _commissions = [];
  List<Withdrawal> _withdrawals = [];

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _commissionController = TextEditingController();
  File? _selectedImage;
  bool _passwordVisible = false;

  @override
  void initState() {
    super.initState();
    _loadSalespersons();
    _fetchCommissionSummary();
    _fetchHistory();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _commissionController.dispose();
    super.dispose();
  }

  Future<void> _loadSalespersons() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _salesManagerService.GetAdminSalespersons();
      if (response.status == Status.completed) {
        setState(() {
          _salespersons = response.data!;
          _isLoading = false;
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });

      // Handle authentication errors
      if (e.toString().toLowerCase().contains('invalid or expired token')) {
        _showErrorSnackBar('Your session has expired. Please login again.');
        // Navigate to login screen after a short delay
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        });
      } else {
        _showErrorSnackBar(e.toString());
      }
    }
  }

  Future<void> _fetchCommissionSummary() async {
    setState(() {
      _isCommissionLoading = true;
      _commissionError = null;
    });
    try {
      final response = await _salesManagerService.getCommissionSummary();
      if (response.status == Status.completed) {
        setState(() {
          _totalCommission = response.data!['totalCommission'] ?? 0.0;
          _totalWithdrawn = response.data!['totalWithdrawn'] ?? 0.0;
          _availableBalance = response.data!['availableBalance'] ?? 0.0;
          _isCommissionLoading = false;
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      setState(() {
        _commissionError = e.toString();
        _isCommissionLoading = false;
      });
    }
  }

  Future<void> _fetchHistory() async {
    setState(() {
      _isHistoryLoading = true;
      _historyError = null;
    });
    try {
      final response = await _salesManagerService.getCommissionAndWithdrawalHistory();
      if (response.status == Status.completed) {
        final data = response.data!;
        final commissions = (data['commissions'] as List?) ?? [];
        final withdrawals = (data['withdrawals'] as List?) ?? [];
        
        // Parse commissions into Commission objects
        final List<Commission> parsedCommissions = [];
        for (var c in commissions) {
          if (c != null && c is Map<String, dynamic>) {
            try {
              parsedCommissions.add(Commission.fromJson(c));
            } catch (e) {
              debugPrint('Error parsing commission: $e');
            }
          }
        }
        
        // Parse withdrawals into Withdrawal objects
        final List<Withdrawal> parsedWithdrawals = [];
        for (var w in withdrawals) {
          if (w != null && w is Map<String, dynamic>) {
            try {
              parsedWithdrawals.add(Withdrawal.fromJson(w));
            } catch (e) {
              debugPrint('Error parsing withdrawal: $e');
            }
          }
        }
        
        setState(() {
          _commissions = parsedCommissions;
          _withdrawals = parsedWithdrawals;
          _isHistoryLoading = false;
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      setState(() {
        _historyError = e.toString();
        _isHistoryLoading = false;
      });
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  void _selectTab(int index) {
    setState(() {
      _selectedTabIndex = index;
    });
    // Refresh data when switching to commission tab
    if (index == 1) {
      _fetchCommissionSummary();
      _fetchHistory();
    }
  }

  void _showWithdrawDialog() async {
    await showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => WithdrawDialog(
        availableBalance: _availableBalance,
        onWithdraw: (amount) async {
          try {
            final response = await _salesManagerService.requestCommissionWithdrawal(amount);
            if (response.status == Status.completed) {
              if (mounted) {
                _showRequestSentPopup();
                _fetchCommissionSummary();
                _fetchHistory();
              }
            } else {
              throw Exception(response.message);
            }
          } catch (e) {
            if (mounted) {
              _showErrorSnackBar(e.toString());
            }
          }
        },
      ),
    );
  }

  void _showRequestSentPopup() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const RequestSentPopup(
        title: 'Withdrawal Request Sent',
        message: 'Your withdrawal request has been sent to admin for approval.',
      ),
    );
  }

  Future<void> _addSalesperson() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }
    final commissionText = _commissionController.text.trim();
    final commissionPercent = double.tryParse(commissionText) ?? 0.0;
    if (commissionPercent < 0 || commissionPercent > 100) {
      _showErrorSnackBar('Commission percent must be between 0 and 100');
      return;
    }
    final newSalesperson = Salesperson(
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phoneNumber: _phoneController.text,
      status: 'active',
      commissionPercent: commissionPercent,
    );

    try {
      final response = await _salesManagerService.createSalesperson(salesperson: newSalesperson);
      if (response.status == Status.completed) {
        _showSuccessSnackBar('Salesperson added successfully');
        _clearForm();
        _loadSalespersons();
        Navigator.of(context).pop();
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('invalid or expired token')) {
        _showErrorSnackBar('Your session has expired. Please login again.');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        });
      } else {
        _showErrorSnackBar('Failed to add salesperson: ${e.toString()}');
      }
    }
  }

  Future<void> _editSalesperson(Salesperson salesperson) async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _phoneController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }
    final commissionText = _commissionController.text.trim();
    final commissionPercent = double.tryParse(commissionText) ?? 0.0;
    if (commissionPercent < 0 || commissionPercent > 100) {
      _showErrorSnackBar('Commission percent must be between 0 and 100');
      return;
    }
    final updatedSalesperson = Salesperson(
      id: salesperson.id,
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text.isNotEmpty ? _passwordController.text : salesperson.password,
      phoneNumber: _phoneController.text,
      status: salesperson.status,
      image: salesperson.image,
      createdAt: salesperson.createdAt,
      updatedAt: DateTime.now(),
      createdBy: salesperson.createdBy,
      companyId: salesperson.companyId,
      commissions: salesperson.commissions,
      commissionPercent: commissionPercent,
    );

    try {
      final response = await _salesManagerService.updateSalesperson(
        salespersonId: salesperson.id!,
        salesperson: updatedSalesperson,
      );
      if (response.status == Status.completed) {
        _showSuccessSnackBar('Salesperson updated successfully');
        _clearForm();
        _loadSalespersons();
        Navigator.of(context).pop();
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      if (e.toString().toLowerCase().contains('invalid or expired token')) {
        _showErrorSnackBar('Your session has expired. Please login again.');
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
          );
        });
      } else {
        _showErrorSnackBar('Failed to update salesperson: ${e.toString()}');
      }
    }
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    _commissionController.clear();
    setState(() {
      _selectedImage = null;
      _passwordVisible = false;
    });
  }

  void _populateFormForEdit(Salesperson salesperson) {
    _nameController.text = salesperson.fullName;
    _emailController.text = salesperson.email;
    _phoneController.text = salesperson.phoneNumber;
    _commissionController.text = salesperson.commissionPercent.toString();
    _passwordController.clear(); // Clear password for security
  }

  void _showAddDialog({Salesperson? salespersonToEdit}) {
    final bool isEditing = salespersonToEdit != null;

    if (isEditing) {
      _populateFormForEdit(salespersonToEdit);
    } else {
      _clearForm();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Text(
                        isEditing ? 'Edit Salesperson' : 'Add New Salesperson',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        hintText: 'Full Name',
                        hintStyle: TextStyle(
                          color: Color(0xFFA0AEC0),
                          fontSize: 16,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3182CE)),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Email Address',
                        hintStyle: TextStyle(
                          color: Color(0xFFA0AEC0),
                          fontSize: 16,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3182CE)),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_passwordVisible,
                      decoration: InputDecoration(
                        hintText: isEditing ? 'Password (leave empty to keep current)' : 'Password',
                        hintStyle: const TextStyle(
                          color: Color(0xFFA0AEC0),
                          fontSize: 16,
                        ),
                        border: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3182CE)),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _passwordVisible ? Icons.visibility : Icons.visibility_off,
                            color: const Color(0xFF718096),
                          ),
                          onPressed: () {
                            setDialogState(() {
                              _passwordVisible = !_passwordVisible;
                            });
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        hintText: 'Phone Number',
                        hintStyle: TextStyle(
                          color: Color(0xFFA0AEC0),
                          fontSize: 16,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3182CE)),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    TextField(
                      controller: _commissionController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      decoration: const InputDecoration(
                        hintText: 'Commission Percent (0-100)',
                        hintStyle: TextStyle(
                          color: Color(0xFFA0AEC0),
                          fontSize: 16,
                        ),
                        border: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF3182CE)),
                        ),
                        contentPadding: EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                    

                    const SizedBox(height: 32),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Color(0xFFE2E8F0)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(100, 44),
                          ),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              color: Color(0xFF4A5568),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: () {
                            if (isEditing) {
                              _editSalesperson(salespersonToEdit);
                            } else {
                              _addSalesperson();
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF1A202C),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            minimumSize: const Size(100, 44),
                          ),
                          child: Text(
                            isEditing ? 'Edit' : 'Add',
                            style: const TextStyle(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _openDrawer() {
    setState(() {
      _isDrawerOpen = true;
    });
    _scaffoldKey.currentState?.openEndDrawer();
  }

  void _closeDrawer() {
    setState(() {
      _isDrawerOpen = false;
    });
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF8F9FA),
      endDrawer: Drawer(
        width: 220,
        backgroundColor: Colors.transparent,
        child: SalesManagerSidebar(
          onCollapse: _closeDrawer,
          parentContext: context,
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          HeaderComponent(
            logoPath: _logoPath,
            scaffoldKey: _scaffoldKey,
            onMenuPressed: _openDrawer,
          ),
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sales Manager Dashboard',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Manage your sales team and commissions',
                      style: TextStyle(
                        fontSize: 12,
                        color: Color(0xFF718096),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3182CE),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: IconButton(
                        onPressed: () {
                          if (_selectedTabIndex == 0) {
                            _loadSalespersons();
                          } else {
                            _fetchCommissionSummary();
                            _fetchHistory();
                          }
                        },
                        icon: const Icon(
                          Icons.refresh,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    if (_selectedTabIndex == 0)
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF3182CE),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: IconButton(
                          onPressed: () => _showAddDialog(),
                          icon: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          // Navigation Tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _selectTab(0),
                  child: _buildTabButton('Salespersons', isActive: _selectedTabIndex == 0),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _selectTab(1),
                  child: _buildTabButton('Wallet', isActive: _selectedTabIndex == 1),
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              color: const Color(0xFFF8F9FA),
              child: _selectedTabIndex == 0 ? _buildSalespersonsContent() : _buildCommissionContent(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String text, {required bool isActive}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1E40AF) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: isActive ? Colors.white : Colors.grey,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildSalespersonsContent() {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : _error != null
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Error: $_error',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadSalespersons,
                  child: const Text('Retry'),
                ),
              ],
            ),
          )
        : _salespersons.isEmpty
        ? const Center(
            child: Text('No salespersons found'),
          )
        : Padding(
            padding: const EdgeInsets.all(16),
            child: ListView.builder(
              itemCount: _salespersons.length,
              itemBuilder: (context, index) {
                final salesperson = _salespersons[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SalespersonCard(
                    salesperson: salesperson,
                    onEdit: () {
                      _showAddDialog(salespersonToEdit: salesperson);
                    },
                    onDelete: () async {
                      try {
                        final response = await _salesManagerService.deleteSalesperson(salesperson.id!);
                        if (response.status == Status.completed) {
                          _showSuccessSnackBar('Salesperson deleted successfully');
                          _loadSalespersons();
                        } else {
                          throw Exception(response.message);
                        }
                      } catch (e) {
                        _showErrorSnackBar('Failed to delete: ${e.toString()}');
                      }
                    },
                  ),
                );
              },
            ),
          );
  }

  Widget _buildCommissionContent() {
    if (_isCommissionLoading || _isHistoryLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_commissionError != null) {
      return Center(
        child: Text(
          'Error: $_commissionError',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    if (_historyError != null) {
      return Center(
        child: Text(
          'Error: $_historyError',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () async {
        await _fetchCommissionSummary();
        await _fetchHistory();
      },
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        children: [
        // Total Commission Card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [Color(0xFF1E90FF), Color(0xFF1E40AF)],
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Commission',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '\$${_totalCommission.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '+10.2%',
                      style: TextStyle(
                        color: Colors.green,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Balance and Withdraws Row
        Row(
          children: [
            // Balance Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF4169E1), Color(0xFF1E40AF)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Balance',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '\$${_availableBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Total Withdraws Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E90FF), Color(0xFF4169E1)],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.call_made,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Total Withdraws',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '-\$${_totalWithdrawn.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 24),

        // Withdraw Button
        Center(
          child: SizedBox(
            width: 200,
            child: ElevatedButton(
              onPressed: _showWithdrawDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E40AF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
                elevation: 2,
              ),
              child: const Text(
                'Withdraw',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 32),

        // History Section
        const Text(
          'History',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 16),

        if (_commissions.isEmpty && _withdrawals.isEmpty)
          const Center(child: Text('No history found'))
        else
          ..._buildHistoryItems(),
      ],
      ),
    );
  }

  List<Widget> _buildHistoryItems() {
    final List<Map<String, dynamic>> allItems = [];
    
    // Add commissions
    for (final commission in _commissions) {
      allItems.add({
        'type': 'Commission',
        'date': commission.createdAt,
        'amount': commission.amount,
        'isWithdraw': false,
      });
    }
    
    // Add withdrawals
    for (final withdrawal in _withdrawals) {
      allItems.add({
        'type': 'Withdrawn',
        'date': withdrawal.createdAt,
        'amount': withdrawal.amount,
        'isWithdraw': true,
      });
    }
    
    // Sort by date descending
    allItems.sort((a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime));
    
    return allItems.map((item) {
      final type = item['type'] as String;
      final date = item['date'] as DateTime;
      final amount = item['amount'] as double;
      final isWithdraw = item['isWithdraw'] as bool;
      final color = isWithdraw ? Colors.red : Colors.green;
      final amountStr = (isWithdraw ? '-' : '+') + '\$' + amount.abs().toStringAsFixed(2);
      final displayDate = '${date.day} ${_getMonthName(date.month)} ${date.year}';
      return _buildHistoryItem(type, displayDate, amountStr, color);
    }).toList();
  }

  String _getMonthName(int month) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return months[month - 1];
  }

  Widget _buildHistoryItem(String type, String date, String amount, Color amountColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: type == 'Withdrawn' ? Colors.red : Colors.green,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    date,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                amount,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: amountColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(
            height: 1,
            color: Colors.grey[300],
          ),
        ],
      ),
    );
  }
}

class SalespersonCard extends StatelessWidget {
  final Salesperson salesperson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SalespersonCard({
    super.key,
    required this.salesperson,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;
    if (salesperson.image != null && salesperson.image!.isNotEmpty) {
      avatarWidget = CircleAvatar(
        backgroundImage: NetworkImage(salesperson.image!),
        radius: 25,
      );
    } else {
      final initials = salesperson.fullName
          .split(' ')
          .take(2)
          .map((part) => part.isNotEmpty ? part[0] : '')
          .join('')
          .toUpperCase();

      avatarWidget = CircleAvatar(
        backgroundColor: const Color(0xFF4A5568),
        radius: 25,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Stack(
              children: [
                avatarWidget,
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      color: salesperson.status == 'active' ? const Color(0xFF38A169) : Colors.red,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    salesperson.fullName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    salesperson.email,
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF718096),
                    ),
                  ),
                  
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: IconButton(
                    onPressed: onEdit,
                    icon: const Icon(
                      Icons.edit_outlined,
                      color: Color(0xFF4A5568),
                      size: 18,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7FAFC),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: IconButton(
                    onPressed: onDelete,
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFE53E3E),
                      size: 18,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 36,
                      minHeight: 36,
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

// WithdrawDialog widget
class WithdrawDialog extends StatefulWidget {
  final double availableBalance;
  final Future<void> Function(double amount) onWithdraw;
  const WithdrawDialog({Key? key, required this.availableBalance, required this.onWithdraw}) : super(key: key);

  @override
  State<WithdrawDialog> createState() => _WithdrawDialogState();
}

class _WithdrawDialogState extends State<WithdrawDialog> {
  final TextEditingController _amountController = TextEditingController();
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _setMax() {
    setState(() {
      _amountController.text = widget.availableBalance.toStringAsFixed(2);
    });
  }

  Future<void> _handleWithdraw() async {
    final text = _amountController.text.trim();
    final amount = double.tryParse(text) ?? 0.0;
    if (amount <= 0) {
      setState(() {
        _error = 'Please enter a valid amount';
      });
      return;
    }
    if (amount > widget.availableBalance) {
      setState(() {
        _error = 'Amount exceeds available balance';
      });
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      await widget.onWithdraw(amount);
      // Close the dialog on success - the popup will be shown by the parent
      if (mounted) {
        Navigator.of(context).pop();
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        constraints: const BoxConstraints(maxWidth: 350),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Withdraw From Wallet',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E234A),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 18, color: Color(0xFFB2B2C2)),
                      decoration: const InputDecoration(
                        hintText: 'Amount',
                        hintStyle: TextStyle(color: Color(0xFFB2B2C2), fontSize: 18),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _setMax,
                    child: const Text(
                      'Max',
                      style: TextStyle(
                        color: Color(0xFF1E234A),
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFB2B2C2)),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red, fontSize: 14),
                  ),
                ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF1E234A)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          color: Color(0xFF1E234A),
                          fontWeight: FontWeight.w500,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleWithdraw,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1E234A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Withdraw',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 16,
                              ),
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
}
