import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/salesperson_model.dart';
import '../../models/sales_manager.dart';
import '../../services/salesperson_service.dart';
import '../../services/admin_service.dart';
import '../../services/api_constant.dart';

class SalespersonManagementScreen extends StatefulWidget {
  const SalespersonManagementScreen({super.key});

  @override
  State<SalespersonManagementScreen> createState() => _SalespersonManagementScreenState();
}

class _SalespersonManagementScreenState extends State<SalespersonManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _searchController = TextEditingController();
  
  // Form controllers
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _commissionController = TextEditingController();
  final _regionController = TextEditingController();
  
  // Services
  late SalespersonService _salespersonService;
  late AdminService _adminService;
  
  // Data
  List<Salesperson> _salespersons = [];
  List<SalesManager> _salesManagers = [];
  SalesManager? _selectedSalesManager;
  bool _isLoading = false;
  bool _isCreating = false;
  bool _isUpdating = false;
  
  // UI state
  bool _showCreateForm = false;
  Salesperson? _editingSalesperson;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _salespersonService = SalespersonService(baseUrl: ApiConstants.baseUrl);
    _adminService = AdminService(baseUrl: ApiConstants.baseUrl);
    _loadSalespersons();
    _loadSalesManagers();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _commissionController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _loadSalespersons() async {
    setState(() => _isLoading = true);
    try {
      final salespersons = await _salespersonService.GetAdminSalespersons();
      setState(() {
        _salespersons = salespersons;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      _showErrorSnackBar('Failed to load salespersons: $e');
    }
  }

  Future<void> _loadSalesManagers() async {
    try {
      final response = await _adminService.getAllSalesManagers();
      if (response['status'] == 'success' && response['data'] != null) {
        final List<dynamic> managersData = response['data'];
        final managers = managersData.map((json) => SalesManager.fromJson(json)).toList();
        setState(() {
          _salesManagers = managers;
        });
      }
    } catch (e) {
      debugPrint('Failed to load sales managers: $e');
      // Don't show error to user as this is optional
    }
  }

  void _showForm() {
    setState(() {
      _showCreateForm = true;
      _editingSalesperson = null;
      _clearForm();
    });
  }

  void _showEditForm(Salesperson salesperson) {
    setState(() {
      _showCreateForm = true;
      _editingSalesperson = salesperson;
      _fillFormWithSalesperson(salesperson);
    });
  }

  void _hideForm() {
    setState(() {
      _showCreateForm = false;
      _editingSalesperson = null;
      _clearForm();
    });
  }

  void _clearForm() {
    _fullNameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    _commissionController.clear();
    _regionController.clear();
    _selectedSalesManager = null;
  }

  void _fillFormWithSalesperson(Salesperson salesperson) {
    _fullNameController.text = salesperson.fullName;
    _emailController.text = salesperson.email;
    _phoneController.text = salesperson.phoneNumber;
    _commissionController.text = salesperson.commissionPercent.toString();
    _regionController.text = salesperson.region ?? '';
    // Note: We don't fill password for security
    // Note: We don't fill salesManagerId as it's not in the current model
  }

  Future<void> _createSalesperson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isCreating = true);
    try {
      final salesperson = await _salespersonService.createSalesperson(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phoneNumber: _phoneController.text.trim(),
        commissionPercent: double.parse(_commissionController.text),
        region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
        salesManagerId: _selectedSalesManager?.id,
      );

      setState(() {
        _salespersons.insert(0, salesperson);
        _isCreating = false;
      });

      _hideForm();
      _showSuccessSnackBar('Salesperson created successfully');
    } catch (e) {
      setState(() => _isCreating = false);
      _showErrorSnackBar('Failed to create salesperson: $e');
    }
  }

  Future<void> _updateSalesperson() async {
    if (!_formKey.currentState!.validate() || _editingSalesperson == null) return;

    setState(() => _isUpdating = true);
    try {
      final updateData = <String, dynamic>{
        'fullName': _fullNameController.text.trim(),
        'email': _emailController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'commissionPercent': double.parse(_commissionController.text),
        'region': _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
      };

      if (_passwordController.text.isNotEmpty) {
        updateData['password'] = _passwordController.text;
      }

      if (_selectedSalesManager != null) {
        updateData['salesManagerId'] = _selectedSalesManager!.id;
      }

      final updatedSalesperson = await _salespersonService.updateSalesperson(
        _editingSalesperson!.id!,
        updateData,
      );

      setState(() {
        final index = _salespersons.indexWhere((s) => s.id == _editingSalesperson!.id);
        if (index != -1) {
          _salespersons[index] = updatedSalesperson;
        }
        _isUpdating = false;
      });

      _hideForm();
      _showSuccessSnackBar('Salesperson updated successfully');
    } catch (e) {
      setState(() => _isUpdating = false);
      _showErrorSnackBar('Failed to update salesperson: $e');
    }
  }

  Future<void> _deleteSalesperson(Salesperson salesperson) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Delete'),
        content: Text('Are you sure you want to delete ${salesperson.fullName}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _salespersonService.deleteSalesperson(salesperson.id!);
      setState(() {
        _salespersons.removeWhere((s) => s.id == salesperson.id);
      });
      _showSuccessSnackBar('Salesperson deleted successfully');
    } catch (e) {
      _showErrorSnackBar('Failed to delete salesperson: $e');
    }
  }

  List<Salesperson> get _filteredSalespersons {
    if (_searchQuery.isEmpty) return _salespersons;
    return _salespersons.where((salesperson) {
      return salesperson.fullName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             salesperson.email.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             salesperson.phoneNumber.contains(_searchQuery) ||
             (salesperson.region?.toLowerCase().contains(_searchQuery.toLowerCase()) ?? false);
    }).toList();
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Salesperson Management'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Create Button Row
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search salespersons...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _showForm,
                  icon: const Icon(Icons.add),
                  label: const Text('Create Salesperson'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ],
            ),
          ),

          // Create/Edit Form
          if (_showCreateForm) _buildForm(),

          // Salespersons List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildSalespersonsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _editingSalesperson != null ? 'Edit Salesperson' : 'Create New Salesperson',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  onPressed: _hideForm,
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Form Fields
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Full name is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Email is required';
                      }
                      if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Phone Number *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Phone number is required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _commissionController,
                    decoration: const InputDecoration(
                      labelText: 'Commission % *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Commission is required';
                      }
                      final commission = double.tryParse(value);
                      if (commission == null || commission < 0 || commission > 100) {
                        return 'Commission must be between 0 and 100';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _regionController,
                    decoration: const InputDecoration(
                      labelText: 'Region',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<SalesManager>(
                    value: _selectedSalesManager,
                    decoration: const InputDecoration(
                      labelText: 'Sales Manager (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: _salesManagers.map((manager) {
                      return DropdownMenuItem(
                        value: manager,
                        child: Text(manager.fullName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() => _selectedSalesManager = value);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Password field (only for creation or if updating)
            if (_editingSalesperson == null || _passwordController.text.isNotEmpty)
              TextFormField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: _editingSalesperson == null ? 'Password *' : 'New Password (leave empty to keep current)',
                  border: const OutlineInputBorder(),
                ),
                obscureText: true,
                validator: (value) {
                  if (_editingSalesperson == null && (value == null || value.isEmpty)) {
                    return 'Password is required';
                  }
                  return null;
                },
              ),
            
            const SizedBox(height: 16),
            
            // Submit Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreating || _isUpdating
                    ? null
                    : () {
                        if (_editingSalesperson != null) {
                          _updateSalesperson();
                        } else {
                          _createSalesperson();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCreating || _isUpdating
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                      )
                    : Text(_editingSalesperson != null ? 'Update Salesperson' : 'Create Salesperson'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSalespersonsList() {
    if (_filteredSalespersons.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty ? 'No salespersons found' : 'No salespersons match your search',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: _filteredSalespersons.length,
      itemBuilder: (context, index) {
        final salesperson = _filteredSalespersons[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.blue[100],
              child: Text(
                salesperson.fullName.substring(0, 1).toUpperCase(),
                style: TextStyle(color: Colors.blue[700], fontWeight: FontWeight.bold),
              ),
            ),
            title: Text(
              salesperson.fullName,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(salesperson.email),
                Text(salesperson.phoneNumber),
                if (salesperson.region != null && salesperson.region!.isNotEmpty)
                  Text('Region: ${salesperson.region}'),
                Text('Commission: ${salesperson.commissionPercent}%'),
                Text(
                  'Status: ${salesperson.status ?? 'Active'}',
                  style: TextStyle(
                    color: (salesperson.status == 'active' || salesperson.status == null) 
                        ? Colors.green 
                        : Colors.red,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    _showEditForm(salesperson);
                    break;
                  case 'delete':
                    _deleteSalesperson(salesperson);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
