import 'dart:io';
import 'package:admin_dashboard/src/services/api_services.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../components/header.dart';
import '../../models/sales_manager.dart';
import '../../services/admin_service.dart';
import 'package:image_picker/image_picker.dart';
import '../../components/sidebar.dart';
import '../../utils/auth_manager.dart';
import '../../models/manager_model.dart';
import '../../screens/homepage/homepage.dart';
import '../../services/manager_service.dart';
import '../../models/company_model.dart';
import '../../models/subscription.dart';
import 'sales_manager_details.dart';
import '../../models/salesperson_model.dart'; // Fixed import path for Salesperson

// Custom input formatter for commission fields to only allow numbers and decimal points
class CommissionInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Allow empty string
    if (newValue.text.isEmpty) {
      return newValue;
    }
    
    // Only allow digits and one decimal point
    final RegExp regex = RegExp(r'^\d*\.?\d*$');
    if (regex.hasMatch(newValue.text)) {
      return newValue;
    }
    
    // If input doesn't match regex, return old value
    return oldValue;
  }
}

class SalesAdminDashboard extends StatefulWidget {
  const SalesAdminDashboard({super.key});

  @override
  State<SalesAdminDashboard> createState() => _SalesAdminDashboardState();
}

class _SalesAdminDashboardState extends State<SalesAdminDashboard> with SingleTickerProviderStateMixin {
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final AdminService _adminService = AdminService(baseUrl: ApiService.baseUrl);
  List<SalesManager> _salesManagers = [];
  bool _isLoading = true;
  String? _error;
  List<Manager> _managers = [];
  TabController? _tabController;
  bool _isLoadingManagers = true;
  String? _errorManagers;

  // Business data
  List<Map<String, dynamic>> _businesses = [];
  bool _isLoadingBusinesses = true;
  String? _errorBusinesses;

  // Form controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _commissionPercentController = TextEditingController();

  File? _selectedImage;
  bool _passwordVisible = false;

  // Salesperson creation specific fields
  SalesManager? _selectedSalesManager;
  Manager? _selectedManager;
  String? _selectedAssignmentType; // 'manager' or 'salesmanager'



  // Salespersons data
  List<Salesperson> _salespersons = [];
  bool _isLoadingSalespersons = true;
  String? _errorSalespersons;

  // New: Permissions list for the popup
  final List<String> _permissions = [
    'User Management',
    'Categories',
    'Business Management',
    'Content moderation',
    'Sales Management',
    'Referral Program Monitoring',
    'Financial Dashboard(Revenue)',
    'Financial Dashboard Geographical (insights)',
  ];
  final Set<String> _selectedPermissions = {};

  // Map UI permission labels to backend keys
  final Map<String, String> _permissionKeys = {
    'User Management': 'user_management',
    'Categories': 'categories',
    'Business Management': 'business_management',
    'Content moderation': 'content_moderation',
    'Sales Management': 'sales_management',
    'Referral Program Monitoring': 'referral_program_monitoring',
    'Financial Dashboard(Revenue)': 'financial_dashboard_revenue',
    'Financial Dashboard Geographical (insights)': 'financial_dashboard_geographical_insights',
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadManagers();
    _loadSalesManagers();
    _loadSalespersons();
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    _commissionPercentController.dispose();

    super.dispose();
  }

  Future<void> _loadBusinesses() async {
    setState(() {
      _isLoadingBusinesses = true;
      _errorBusinesses = null;
    });

    try {
      final data = await ManagerService.getCreatedUsers();
      final List<Map<String, dynamic>> businesses = [];
      
      // Process companies
      final companies = data['companies'] ?? [];
      for (var company in companies) {
        if (company != null && company is Map<String, dynamic>) {
          final companyData = company['company'] ?? company;
          
          // Extract data directly from the root object based on the actual API structure
          final contactPerson = companyData['contactPerson'] ?? companyData['fullname'] ?? '';
          final contactPhone = companyData['contactPhone'] ?? companyData['phone'] ?? '';
          final createdAt = companyData['createdAt'] ?? '';
          final subscription = companyData['subscription'] ?? {};
          final planTitle = (subscription['planTitle'] ?? '').toString().isNotEmpty 
              ? subscription['planTitle'] 
              : companyData['category'] ?? '';
          final planPrice = subscription['planPrice'] ?? 0.0;
          final logoUrl = companyData['logoURL'] ?? companyData['logoUrl'] ?? '';
          
          final businessData = {
            'type': 'company',
            'businessName': companyData['businessName'] ?? '',
            'contactPerson': contactPerson,
            'contactPhone': contactPhone,
            'createdAt': createdAt,
            'planTitle': planTitle,
            'planPrice': planPrice,
            'logoUrl': logoUrl,
            'status': companyData['status'] ?? 'active',
          };
          
          businesses.add(businessData);
        }
      }

      // Process service providers
      final serviceProviders = data['serviceProviders'] ?? [];
      for (var sp in serviceProviders) {
        if (sp != null && sp is Map<String, dynamic>) {
          final spData = sp['serviceProvider'] ?? sp;
          
          final contactPerson = spData['contactPerson'] ?? spData['fullname'] ?? spData['name'] ?? '';
          final contactPhone = spData['contactPhone'] ?? spData['phone'] ?? '';
          final createdAt = spData['createdAt'] ?? '';
          final subscription = spData['subscription'] ?? {};
          final planTitle = (subscription['planTitle'] ?? '').toString().isNotEmpty 
              ? subscription['planTitle'] 
              : spData['category'] ?? spData['userType'] ?? '';
          final planPrice = subscription['planPrice'] ?? 0.0;
          final logoUrl = spData['logoURL'] ?? spData['logoUrl'] ?? spData['profileImage'] ?? '';
          
          final businessData = {
            'type': 'serviceProvider',
            'businessName': spData['businessName'] ?? spData['name'] ?? '',
            'contactPerson': contactPerson,
            'contactPhone': contactPhone,
            'createdAt': createdAt,
            'planTitle': planTitle,
            'planPrice': planPrice,
            'logoUrl': logoUrl,
            'status': spData['status'] ?? 'active',
          };
          
          businesses.add(businessData);
        }
      }

      // Process wholesalers
      final wholesalers = data['wholesalers'] ?? [];
      for (var w in wholesalers) {
        if (w != null && w is Map<String, dynamic>) {
          final wData = w['wholesaler'] ?? w;
          
          final contactPerson = wData['contactPerson'] ?? wData['fullname'] ?? wData['name'] ?? '';
          final contactPhone = wData['contactPhone'] ?? wData['phone'] ?? '';
          final createdAt = wData['createdAt'] ?? '';
          final subscription = wData['subscription'] ?? {};
          final planTitle = (subscription['planTitle'] ?? '').toString().isNotEmpty 
              ? subscription['planTitle'] 
              : wData['category'] ?? wData['userType'] ?? '';
          final planPrice = subscription['planPrice'] ?? 0.0;
          final logoUrl = wData['logoURL'] ?? wData['logoUrl'] ?? wData['profileImage'] ?? '';
          
          final businessData = {
            'type': 'wholesaler',
            'businessName': wData['businessName'] ?? wData['name'] ?? '',
            'contactPerson': contactPerson,
            'contactPhone': contactPhone,
            'createdAt': createdAt,
            'planTitle': planTitle,
            'planPrice': planPrice,
            'logoUrl': logoUrl,
            'status': wData['status'] ?? 'active',
          };
          
          businesses.add(businessData);
        }
      }

      setState(() {
        _businesses = businesses;
        _isLoadingBusinesses = false;
      });
    } catch (e) {
      setState(() {
        _errorBusinesses = e.toString();
        _isLoadingBusinesses = false;
      });
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _loadSalesManagers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _adminService.getAllSalesManagers();
      print('Sales Managers API Response: $response');
      
      if (response['success']) {
        final data = response['data'];
        print('Sales Managers Data: $data');
        
        setState(() {
          if (data == null) {
            _salesManagers = [];
          } else {
            final salesManagers = <SalesManager>[];
            
            // Handle different response structures
            List<dynamic> dataList = [];
            if (data is List) {
              dataList = data;
            } else if (data is Map<String, dynamic>) {
              // Check if it's a single sales manager wrapped in an object
              if (data.containsKey('salesManager')) {
                dataList = [data['salesManager']];
              } else if (data.containsKey('salesManagers')) {
                dataList = data['salesManagers'] as List? ?? [];
              } else {
                // If it's a single sales manager object, wrap it in a list
                dataList = [data];
              }
            }
            
            // Special handling for the current API response structure
            // The API seems to be returning a single sales manager instead of a list
            if (dataList.isEmpty && data is Map<String, dynamic>) {
              // Check if this looks like a single sales manager response
              if (data.containsKey('id') && data.containsKey('fullName') && data.containsKey('email')) {
                dataList = [data];
              }
            }
            
            print('Processed data list: $dataList');
            
            for (var json in dataList) {
              if (json != null && json is Map<String, dynamic>) {
                try {
                  print('Parsing sales manager: $json');
                  final salesManager = SalesManager.fromJson(json);
                  print('Parsed commission: ${salesManager.commissionPercent}');
                  salesManagers.add(salesManager);
                } catch (error) {
                  print('Error parsing sales manager: $error');
                  print('JSON that failed: $json');
                }
              }
            }
            _salesManagers = salesManagers;
            print('Final sales managers list: ${_salesManagers.map((sm) => '${sm.fullName}: ${sm.commissionPercent}').toList()}');
          }
          _isLoading = false;
        });
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _loadManagers() async {
    setState(() {
      _isLoadingManagers = true;
      _errorManagers = null;
    });
    try {
      final response = await ApiService.getManagers();
      if (response.success) {
        final data = response.data;
        setState(() {
          if (data is List) {
            final managers = <Manager>[];
            for (var json in data) {
              if (json != null && json is Map<String, dynamic>) {
                try {
                  managers.add(Manager.fromJson(json));
                } catch (error) {
                  print('Error parsing manager: $error');
                }
              }
            }
            _managers = managers;
          } else {
            _managers = [];
          }
          _isLoadingManagers = false;
        });
      } else {
        throw Exception(response.message);
      }
    } catch (e) {
      setState(() {
        _errorManagers = e.toString();
        _isLoadingManagers = false;
      });
      _showErrorSnackBar(e.toString());
    }
  }

  Future<void> _loadSalespersons() async {
    setState(() {
      _isLoadingSalespersons = true;
      _errorSalespersons = null;
    });
    try {
      final response = await _adminService.GetAdminSalespersons();
      if (response['success']) {
        final data = response['data'];
        setState(() {
          if (data == null) {
            _salespersons = [];
          } else {
            final salespersons = <Salesperson>[];
            final dataList = data as List? ?? [];
            for (var json in dataList) {
              if (json != null && json is Map<String, dynamic>) {
                try {
                  salespersons.add(Salesperson.fromJson(json));
                } catch (error) {
                  print('Error parsing salesperson: $error');
                }
              }
            }
            _salespersons = salespersons;
          }
          _isLoadingSalespersons = false;
        });
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      setState(() {
        _errorSalespersons = e.toString();
        _isLoadingSalespersons = false;
      });
      _showErrorSnackBar(e.toString());
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

  Future<void> _addSalesManager() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _phoneController.text.isEmpty ) { // Add territory validation
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    final newSalesManager = SalesManager(
      id: '', // Will be assigned by the server
      fullName: _nameController.text,
      email: _emailController.text,
      password: _passwordController.text,
      phoneNumber: _phoneController.text,
      status: 'active',
      createdBy: 'admin', // Replace with actual admin ID
      salespersons: [],
      // rolesAccess: [], // Add this line to fix the linter error
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      commissionPercent: double.tryParse(_commissionPercentController.text) ?? 0.0,
    );

    try {
      final response = await _adminService.createSalesManager(newSalesManager);
      if (response['success']) {
        _showSuccessSnackBar('Sales Manager added successfully');
        _clearForm();
        _loadSalesManagers();
        Navigator.of(context).pop();
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add sales manager: ${e.toString()}');
    }
  }

  void _showDeleteConfirmationDialog(SalesManager salesManager) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissing by tapping outside
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Account',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Are you sure you want\nto delete this user?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 18,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // Close dialog
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop(); // Close dialog first
                          // Then perform the delete operation
                          await _deleteSalesManager(salesManager);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF3B30),
                          ),
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
  }

// Extract the delete logic into a separate method
  Future<void> _deleteSalesManager(SalesManager salesManager) async {
    try {
      final response = await _adminService.deleteSalesManager(salesManager.id);
      if (response['success']) {
        _showSuccessSnackBar('Sales Manager deleted successfully');
        _loadSalesManagers();
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete: ${e.toString()}');
    }
  }

  void _showSalesManagerDetails(SalesManager salesManager) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => SalesManagerDetailsScreen(
          salesManagerId: salesManager.id,
          salesManagerName: salesManager.fullName,
        ),
      ),
    );
  }

  void _clearForm() {
    _nameController.clear();
    _emailController.clear();
    _passwordController.clear();
    _phoneController.clear();
    _commissionPercentController.clear();
    
    setState(() {
      _selectedImage = null;
      _passwordVisible = false;
      _selectedSalesManager = null;
      _selectedManager = null;
      _selectedAssignmentType = null;

    });
  }

  // New: Show user type selection dialog
  void _showUserTypeSelectionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 300),
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Center(
                  child: Text(
                    'Select User Type',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0A1747),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAddDialog(userType: 'Sales Manager');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1747),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(100, 44),
                  ),
                  child: const Text(
                    'Sales Manager',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAddDialog(userType: 'Manager');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1747),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(100, 44),
                  ),
                  child: const Text(
                    'Manager',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                    _showAddDialog(userType: 'Salesperson');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0A1747),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    minimumSize: const Size(100, 44),
                  ),
                  child: const Text(
                    'Salesperson',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // Update: Add userType parameter to showAddDialog
  void _showEmployeeDialog({required String userType}) {
    _clearForm();
    _selectedPermissions.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20.0),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Text(
                      'Add New $userType',
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0A1747),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      labelStyle: TextStyle(
                        color: Color(0xFF8A93AD),
                        fontSize: 16,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0A1747)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'Email Address',
                      labelStyle: TextStyle(
                        color: Color(0xFF8A93AD),
                        fontSize: 16,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Colors.grey),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(color: Color(0xFF0A1747)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  StatefulBuilder(
                    builder: (context, setState) {
                      return TextField(
                        controller: _passwordController,
                        obscureText: !_passwordVisible,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          labelStyle: const TextStyle(
                            color: Color(0xFF8A93AD),
                            fontSize: 16,
                          ),
                          enabledBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF0A1747)),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _passwordVisible ? Icons.visibility : Icons.visibility_outlined,
                              color: const Color(0xFF0A1747),
                            ),
                            onPressed: () {
                              setState(() {
                                _passwordVisible = !_passwordVisible;
                              });
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),
                  // Phone number field for Sales Manager and Salesperson
                  if (userType != 'Manager')
                    TextField(
                      controller: _phoneController,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        labelStyle: TextStyle(
                          color: Color(0xFF8A93AD),
                          fontSize: 16,
                        ),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Color(0xFF0A1747)),
                        ),
                      ),
                    ),
                  
                  // Commission Percent for Sales Manager and Salesperson
                  if (userType != 'Manager')
                    Column(
                      children: [
                        const SizedBox(height: 16),
                        TextField(
                          controller: _commissionPercentController,
                          keyboardType: TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [CommissionInputFormatter()],
                          decoration: const InputDecoration(
                            labelText: 'Commission Percent',
                            hintText: '30',
                            labelStyle: TextStyle(
                              color: Color(0xFF8A93AD),
                              fontSize: 16,
                            ),
                            enabledBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Color(0xFF0A1747)),
                            ),
                          ),
                        ),
                      ],
                    ),

                  // Manager/SalesManager assignment for Salesperson
                  
                  
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      OutlinedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Color(0xFF0A1747)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          minimumSize: const Size(100, 44),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF0A1747),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      ElevatedButton(
                        onPressed: () {
                          _addEmployee(userType: userType);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0A1747),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          minimumSize: const Size(100, 44),
                        ),
                        child: const Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
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
      },
    );
  }

  // Update: Show the new employee dialog from user type selection
  void _showAddDialog({String userType = 'Sales Manager'}) {
    _showEmployeeDialog(userType: userType);
  }

  Future<void> _addEmployee({required String userType}) async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty) {
      _showErrorSnackBar('Please fill in all required fields');
      return;
    }

    if (userType == 'Manager') {
      // if (_selectedPermissions.isEmpty) {
      //   _showErrorSnackBar('At least one access role must be selected');
      //   return;
      // }
      // final List<String> rolesAccess = _selectedPermissions
      //     .map((label) => _permissionKeys[label] ?? label)
      //     .toList();

      // Call the new API for Manager
      try {
        final response = await ApiService.createManager(
          fullName: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          // rolesAccess: rolesAccess,
        );
        if (response.success) {
          _showSuccessSnackBar('Manager added successfully');
          Navigator.of(context).pop();
          _clearForm();
          _loadManagers(); // Refresh managers list
        } else {
          _showErrorSnackBar(response.message ?? 'Failed to add Manager');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to add Manager: ${e.toString()}');
      }
      return;
    }

    if (userType == 'Salesperson') {
      // Validate salesperson-specific fields
      if (_phoneController.text.isEmpty) {
        _showErrorSnackBar('Phone number is required for salesperson');
        return;
      }


      // Get the real admin ObjectID from AuthManager
      String? adminObjectId;
      try {
        adminObjectId = await AuthManager.getCurrentUserId();
      } catch (e) {
        adminObjectId = null;
      }
      if (adminObjectId == null) {
        _showErrorSnackBar('Could not determine admin ID. Please log in again.');
        return;
      }

      double? commissionPercent;
      if (_commissionPercentController.text.isNotEmpty) {
        commissionPercent = double.tryParse(_commissionPercentController.text);
        if (commissionPercent == null) {
          _showErrorSnackBar('Invalid commission percent');
          return;
        }
      }

      try {
        // Create salesperson using the admin service
        final salespersonData = {
          'fullName': _nameController.text,
          'email': _emailController.text,
          'password': _passwordController.text,
          'phoneNumber': _phoneController.text,
          'status': 'active',
          'commissionPercent': commissionPercent ?? 0.0,
          'createdBy': adminObjectId,
        };

        // Note: Manager assignment would need to be handled separately as the current model doesn't support it

        final response = await _adminService.createSalesperson(salespersonData);
        if (response['success']) {
          _showSuccessSnackBar('Salesperson added successfully');
          Navigator.of(context).pop();
          _clearForm();
          _loadSalespersons(); // Refresh salespersons list
        } else {
          _showErrorSnackBar(response['message'] ?? 'Failed to add Salesperson');
        }
      } catch (e) {
        _showErrorSnackBar('Failed to add Salesperson: ${e.toString()}');
      }
      return;
    }

    // Handle Sales Manager creation (existing logic)
    // if (_selectedPermissions.isEmpty) {
    //   _showErrorSnackBar('At least one access role must be selected');
    //   return;
    // }
    // final List<String> rolesAccess = _selectedPermissions
    //     .map((label) => _permissionKeys[label] ?? label)
    //     .toList();

    // Get the real admin ObjectID from AuthManager
    String? adminObjectId;
    try {
      adminObjectId = await AuthManager.getCurrentUserId();
    } catch (e) {
      adminObjectId = null;
    }
    if (adminObjectId == null) {
      _showErrorSnackBar('Could not determine admin ID. Please log in again.');
      return;
    }

    double? commissionPercent;
    if (_commissionPercentController.text.isNotEmpty) {
      commissionPercent = double.tryParse(_commissionPercentController.text);
      if (commissionPercent == null) {
        _showErrorSnackBar('Invalid commission percent');
        return;
      }
    }

    try {
      final response = await ApiService.createSalesManager(
        fullName: _nameController.text,
        email: _emailController.text,
        password: _passwordController.text,
        phoneNumber: _phoneController.text,
        status: 'active',
        createdBy: adminObjectId,
        // rolesAccess: rolesAccess,
        commissionPercent: userType == 'Manager' ? 1.0 : commissionPercent,
      );
      if (response.success) {
        _showSuccessSnackBar('$userType added successfully');
        Navigator.of(context).pop();
        _clearForm();
        _loadSalesManagers();
      } else {
        _showErrorSnackBar(response.message ?? 'Failed to add $userType');
      }
    } catch (e) {
      _showErrorSnackBar('Failed to add $userType: ${e.toString()}');
    }
  }

  void _editSalesManager(SalesManager salesManager) {
    // TODO: Implement edit functionality
    _showSuccessSnackBar('Edit Sales Manager: ' + salesManager.fullName);
  }

  void _showEditManagerDialog(Manager manager) {
    final nameController = TextEditingController(text: manager.fullName);
    final emailController = TextEditingController(text: manager.email);
    final passwordController = TextEditingController();
    // final Set<String> selectedRoles = {...manager.rolesAccess};
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Manager'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password (leave blank to keep unchanged)'),
                      obscureText: true,
                    ),
                    const SizedBox(height: 12),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Roles', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                    // Column(
                    //   children: _permissions.map((role) {
                    //     final key = _permissionKeys[role] ?? role;
                    //     return CheckboxListTile(
                    //       value: selectedRoles.contains(key),
                    //       onChanged: (checked) {
                    //         setState(() {
                    //           if (checked == true) {
                    //             selectedRoles.add(key);
                    //           } else {
                    //             selectedRoles.remove(key);
                    //           }
                    //         });
                    //       },
                    //       title: Text(role),
                    //       controlAffinity: ListTileControlAffinity.leading,
                    //       dense: true,
                    //     );
                    //   }).toList(),
                    // ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final response = await ApiService.updateManager(
                      id: manager.id,
                      fullName: nameController.text,
                      email: emailController.text,
                      // rolesAccess: selectedRoles.toList(),
                      password: passwordController.text,
                    );
                    if (response.success) {
                      _showSuccessSnackBar('Manager updated successfully');
                      Navigator.of(context).pop();
                      _loadManagers();
                    } else {
                      _showErrorSnackBar(response.message ?? 'Failed to update manager');
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _deleteManager(Manager manager) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Manager'),
        content: Text('Are you sure you want to delete ${manager.fullName}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Delete'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      final response = await ApiService.deleteManager(manager.id);
      if (response.success) {
        _showSuccessSnackBar('Manager deleted successfully');
        _loadManagers();
      } else {
        _showErrorSnackBar(response.message ?? 'Failed to delete manager');
      }
    }
  }

  void _showEditSalespersonDialog(Salesperson salesperson) {
    final nameController = TextEditingController(text: salesperson.fullName);
    final emailController = TextEditingController(text: salesperson.email);
    final phoneController = TextEditingController(text: salesperson.phoneNumber);
    final commissionController = TextEditingController(text: salesperson.commissionPercent.toString());
    final passwordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Salesperson'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'Full Name'),
                    ),
                    TextField(
                      controller: emailController,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    TextField(
                      controller: phoneController,
                      decoration: const InputDecoration(labelText: 'Phone Number'),
                    ),
                    TextField(
                      controller: commissionController,
                      decoration: const InputDecoration(labelText: 'Commission Percent'),
                      keyboardType: TextInputType.number,
                      inputFormatters: [CommissionInputFormatter()],
                    ),
                    TextField(
                      controller: passwordController,
                      decoration: const InputDecoration(labelText: 'Password (leave blank to keep unchanged)'),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final updateData = {
                      'fullName': nameController.text,
                      'email': emailController.text,
                      'phoneNumber': phoneController.text,
                      'commissionPercent': double.tryParse(commissionController.text) ?? salesperson.commissionPercent,
                    };

                    if (passwordController.text.isNotEmpty) {
                      updateData['password'] = passwordController.text;
                    }

                    final response = await _adminService.updateSalesperson(salesperson.id!, updateData);
                    if (response['success']) {
                      _showSuccessSnackBar('Salesperson updated successfully');
                      Navigator.of(context).pop();
                      _loadSalespersons();
                    } else {
                      _showErrorSnackBar(response['message'] ?? 'Failed to update salesperson');
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }



  void _showDeleteSalespersonConfirmationDialog(Salesperson salesperson) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.0),
          ),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 400),
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Delete Salesperson',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Are you sure you want\nto delete ${salesperson.fullName}?',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF666666),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                Container(
                  height: 1,
                  color: Colors.grey.shade300,
                ),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomLeft: Radius.circular(16),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF007AFF),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: Colors.grey.shade300,
                    ),
                    Expanded(
                      child: TextButton(
                        onPressed: () async {
                          Navigator.of(context).pop();
                          await _deleteSalesperson(salesperson);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              bottomRight: Radius.circular(16),
                            ),
                          ),
                        ),
                        child: const Text(
                          'Delete',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF3B30),
                          ),
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
  }

  Future<void> _deleteSalesperson(Salesperson salesperson) async {
    try {
      final response = await _adminService.deleteSalesperson(salesperson.id!);
      if (response['success']) {
        _showSuccessSnackBar('Salesperson deleted successfully');
        _loadSalespersons();
      } else {
        throw Exception(response['message']);
      }
    } catch (e) {
      _showErrorSnackBar('Failed to delete salesperson: ${e.toString()}');
    }
  }

  void _showEditSalesManagerDialog(SalesManager salesManager) {
    print('Edit dialog - Sales Manager: ${salesManager.fullName}');
    print('Edit dialog - Commission Percent: ${salesManager.commissionPercent}');
    print('Edit dialog - Commission Percent type: ${salesManager.commissionPercent.runtimeType}');
    
    final nameController = TextEditingController(text: salesManager.fullName);
    final emailController = TextEditingController(text: salesManager.email);
    final phoneController = TextEditingController(text: salesManager.phoneNumber);
    final commissionController = TextEditingController(text: salesManager.commissionPercent.toString());
    // final Set<String> selectedRoles = {...salesManager.rolesAccess};
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Edit Sales Manager'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                    TextField(controller: emailController, decoration: const InputDecoration(labelText: 'Email')),
                    TextField(controller: phoneController, decoration: const InputDecoration(labelText: 'Phone Number')),
                    TextField(
                      controller: commissionController, 
                      decoration: const InputDecoration(labelText: 'Commission Percent'), 
                      keyboardType: TextInputType.number,
                      inputFormatters: [CommissionInputFormatter()],
                    ),
                    const SizedBox(height: 12),
                    const Align(alignment: Alignment.centerLeft, child: Text('Roles', style: TextStyle(fontWeight: FontWeight.bold))),
                    // Column(
                    //   children: _permissions.map((role) {
                    //     final key = _permissionKeys[role] ?? role;
                    //     return CheckboxListTile(
                    //       value: selectedRoles.contains(key),
                    //       onChanged: (checked) {
                    //         setState(() {
                    //           if (checked == true) {
                    //             selectedRoles.add(key);
                    //           } else {
                    //             selectedRoles.remove(key);
                    //           }
                    //         });
                    //       },
                    //       title: Text(role),
                    //       controlAffinity: ListTileControlAffinity.leading,
                    //       dense: true,
                    //     );
                    //   }).toList(),
                    // ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final response = await ApiService.updateSalesManager(
                      id: salesManager.id,
                      fullName: nameController.text,
                      email: emailController.text,
                      phoneNumber: phoneController.text,
                      commissionPercent: double.tryParse(commissionController.text),
                      // rolesAccess: selectedRoles.toList(),
                    );
                    if (response.success) {
                      _showSuccessSnackBar('Sales Manager updated successfully');
                      Navigator.of(context).pop();
                      _loadSalesManagers();
                    } else {
                      _showErrorSnackBar(response.message ?? 'Failed to update sales manager');
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.white,
      endDrawer: Sidebar(
        onCollapse: () {
          _scaffoldKey.currentState?.closeEndDrawer();
        },
        parentContext: context,
      ),
      body: Column(
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
          AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: () {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardPage()),
                );
              },
            ),
            title: const Text(
              'Sales Management',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 18,
              ),
            ),
            actions: [
              IconButton(
                onPressed: _showUserTypeSelectionDialog,
                icon: const Icon(
                  Icons.add_circle,
                  color: Color(0xFF1565C0),
                  size: 24,
                ),
                tooltip: 'Add New User',
              ),
            ],
          ),
          TabBar(
            controller: _tabController,
            tabs: const [
              Tab(text: 'Managers'),
              Tab(text: 'Sales Managers'),
              Tab(text: 'Salespersons'),
            ],
            labelColor: Color(0xFF0A1747),
            unselectedLabelColor: Colors.grey,
            indicatorColor: Color(0xFF1565C0),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _isLoadingManagers
                    ? const Center(child: CircularProgressIndicator())
                    : _errorManagers != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error: $_errorManagers',
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadManagers,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _managers.isEmpty
                            ? const Center(child: Text('No managers found'))
                            : ListView.builder(
                                itemCount: _managers.length,
                                itemBuilder: (context, index) {
                                  final manager = _managers[index];
                                  return ManagerListTile(
                                    manager: manager,
                                    onEdit: () => _showEditManagerDialog(manager),
                                    onDelete: () => _deleteManager(manager),
                                  );
                                },
                              ),
                // Sales Managers Tab
                _isLoading
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
                                  onPressed: _loadSalesManagers,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : _salesManagers.isEmpty
                            ? const Center(child: Text('No sales managers found'))
                            : ListView.builder(
                                itemCount: _salesManagers.length,
                                itemBuilder: (context, index) {
                                  final salesManager = _salesManagers[index];
                                          return SalesManagerListTile(
          salesManager: salesManager,
          onDelete: () => _showDeleteConfirmationDialog(salesManager),
          onEdit: () => _showEditSalesManagerDialog(salesManager),
          onTap: () => _showSalesManagerDetails(salesManager),
        );
                                },
                              ),
                // Salespersons Tab
                _isLoadingSalespersons
                    ? const Center(child: CircularProgressIndicator())
                    : _errorSalespersons != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Error: $_errorSalespersons',
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
                            ? const Center(child: Text('No salespersons found'))
                            : ListView.builder(
                                itemCount: _salespersons.length,
                                itemBuilder: (context, index) {
                                  final salesperson = _salespersons[index];
                                  return SalespersonListTile(
                                    salesperson: salesperson,
                                    onEdit: () => _showEditSalespersonDialog(salesperson),
                                    onDelete: () => _showDeleteSalespersonConfirmationDialog(salesperson),
                                  );
                                },
                              ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SalesManagerListTile extends StatelessWidget {
  final SalesManager salesManager;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const SalesManagerListTile({
    super.key,
    required this.salesManager,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarWidget;
    if (salesManager.image != null && salesManager.image!.isNotEmpty) {
      avatarWidget = CircleAvatar(
        backgroundImage: NetworkImage(salesManager.image!),
        radius: 20,
      );
    } else {
      final initials = salesManager.fullName
          .split(' ')
          .take(2)
          .map((part) => part.isNotEmpty ? part[0] : '')
          .join('')
          .toUpperCase();

      avatarWidget = CircleAvatar(
        backgroundColor: Colors.blue,
        radius: 20,
        child: Text(
          initials,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: ListTile(
        leading: avatarWidget,
        onTap: onTap,
        title: Text(
          salesManager.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        tileColor: Colors.grey[50],
        hoverColor: Colors.blue[50],
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(salesManager.email),
            // if (salesManager.rolesAccess.isNotEmpty)
            //   Text('Roles: ' + salesManager.rolesAccess.join(', '), style: const TextStyle(fontSize: 12)),
            
            if (salesManager.salespersons.isNotEmpty)
              Row(
                children: [
                  const Icon(
                    Icons.people,
                    size: 14,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${salesManager.salespersons.length} salespersons',
                    style: const TextStyle(color: Colors.orange),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              color: Colors.blue,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Colors.grey,
            ),
          ],
        ),
        ),
      ),
    );
  }
}

// Add ManagerListTile widget
class ManagerListTile extends StatelessWidget {
  final Manager manager;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const ManagerListTile({Key? key, required this.manager, required this.onEdit, required this.onDelete}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    final initials = manager.fullName
        .split(' ')
        .take(2)
        .map((part) => part.isNotEmpty ? part[0] : '')
        .join('')
        .toUpperCase();
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          radius: 20,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          manager.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(manager.email),
            // Text('Roles: ' + manager.rolesAccess.join(', '), style: const TextStyle(fontSize: 12)),
            // Text('Created: ' + manager.createdAt.toString().split(' ').first, style: const TextStyle(fontSize: 12)),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              color: Colors.blue,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

// Add SalespersonListTile widget
class SalespersonListTile extends StatelessWidget {
  final Salesperson salesperson;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const SalespersonListTile({
    super.key,
    required this.salesperson,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final initials = salesperson.fullName
        .split(' ')
        .take(2)
        .map((part) => part.isNotEmpty ? part[0] : '')
        .join('')
        .toUpperCase();

    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          radius: 20,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        title: Text(
          salesperson.fullName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(salesperson.email),
            Text(salesperson.phoneNumber),
            if (salesperson.region != null && salesperson.region!.isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.blue),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      salesperson.region!,
                      style: const TextStyle(fontSize: 12, color: Colors.blue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            if (salesperson.latitude != null && salesperson.longitude != null)
              Row(
                children: [
                  const Icon(Icons.gps_fixed, size: 14, color: Colors.green),
                  const SizedBox(width: 4),
                  Text(
                    '${salesperson.latitude!.toStringAsFixed(4)}, ${salesperson.longitude!.toStringAsFixed(4)}',
                    style: const TextStyle(fontSize: 11, color: Colors.green),
                  ),
                ],
              ),
            if (salesperson.radius != null && salesperson.radius! > 0)
              Row(
                children: [
                  const Icon(Icons.radio_button_checked, size: 14, color: Colors.purple),
                  const SizedBox(width: 4),
                  Text(
                    'Radius: ${salesperson.radius! >= 1000 ? "${(salesperson.radius! / 1000).toStringAsFixed(1)}km" : "${salesperson.radius!.toInt()}m"}',
                    style: const TextStyle(fontSize: 11, color: Colors.purple),
                  ),
                ],
              ),
            if (salesperson.commissionPercent > 0)
              Row(
                children: [
                  const Icon(Icons.percent, size: 14, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(
                    'Commission: ${salesperson.commissionPercent}%',
                    style: const TextStyle(fontSize: 12, color: Colors.orange),
                  ),
                ],
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: onEdit,
              color: Colors.blue,
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: onDelete,
              color: Colors.red,
            ),
          ],
        ),
      ),
    );
  }
}

// Add BusinessListTile widget
class BusinessListTile extends StatelessWidget {
  final Map<String, dynamic> business;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const BusinessListTile({
    super.key,
    required this.business,
    required this.onEdit,
    required this.onDelete,
  });

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';
    try {
      // Handle different date formats
      DateTime date;
      if (dateString.contains('T')) {
        // ISO format
        date = DateTime.parse(dateString);
      } else if (dateString.contains('-')) {
        // Date only format
        date = DateTime.parse(dateString);
      } else {
        // Try to parse as timestamp
        final timestamp = int.tryParse(dateString);
        if (timestamp != null) {
          date = DateTime.fromMillisecondsSinceEpoch(timestamp);
        } else {
          return dateString;
        }
      }
      return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    } catch (e) {
      print('DEBUG: Date parsing error for $dateString: $e');
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Business logo/avatar
    Widget avatarWidget;
    if (business['logoUrl'] != null && business['logoUrl'].toString().isNotEmpty) {
      avatarWidget = CircleAvatar(
        backgroundImage: NetworkImage(business['logoUrl']),
        radius: 25,
        onBackgroundImageError: (exception, stackTrace) {
          // Handle image loading error
        },
      );
    } else {
      final initials = (business['businessName'] ?? 'N/A')
          .toString()
          .split(' ')
          .take(2)
          .map((part) => part.isNotEmpty ? part[0] : '')
          .join('')
          .toUpperCase();

      avatarWidget = CircleAvatar(
        backgroundColor: const Color(0xFF1E40AF),
        radius: 25,
        child: Text(
          initials.isNotEmpty ? initials : 'N/A',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Business Logo/Avatar
            avatarWidget,
            
            const SizedBox(width: 16),
            
            // Business Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Business Name
                  Text(
                    business['businessName']?.toString() ?? 'N/A',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Contact Person
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          business['contactPerson']?.toString() ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Contact Phone
                  Row(
                    children: [
                      const Icon(
                        Icons.phone_outlined,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          business['contactPhone']?.toString() ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Created Date
                  Row(
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 14,
                        color: Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          'Created: ${_formatDate(business['createdAt']?.toString())}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF6B7280),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Subscription Plan
                  Row(
                    children: [
                      const Icon(
                        Icons.subscriptions_outlined,
                        size: 14,
                        color: Color(0xFF1E40AF),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          '${business['planTitle']?.toString() ?? 'N/A'} - \$${(business['planPrice'] ?? 0.0).toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF1E40AF),
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: onEdit,
                  tooltip: 'Edit',
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: onDelete,
                  tooltip: 'Delete',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Helper class for API responses
class ApiResponse<T> {
  Status status;
  T? data;
  String? message;

  ApiResponse.initial() : status = Status.initial;
  ApiResponse.loading() : status = Status.loading;
  ApiResponse.completed(this.data) : status = Status.completed;
  ApiResponse.error(this.message) : status = Status.error;

  @override
  String toString() {
    return "Status : $status \n Message : $message \n Data : $data";
  }
}

enum Status { initial, loading, completed, error }