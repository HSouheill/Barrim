import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import '../../components/sidebar.dart';
import '../../components/header.dart';
import '../../services/api_services.dart';
import '../../services/api_constant.dart';
import '../../models/voucher_model.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({Key? key}) : super(key: key);

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> with TickerProviderStateMixin {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // State variables
  List<Voucher> _vouchers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  int _refreshCounter = 0;
  
  // Sidebar state
  bool _isSidebarOpen = false;
  
  // Tab state
  int _selectedTabIndex = 0;
  late TabController _tabController;
  final List<String> _tabLabels = ['All', 'Users', 'Companies', 'Service Providers', 'Wholesalers'];
  final List<String> _tabUserTypes = ['all', 'user', 'company', 'serviceProvider', 'wholesaler'];
  
  // Form controllers for voucher creation
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  String _targetUserType = 'user';
  bool _isCreatingVoucher = false;
  
  // Image picker variables
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isProcessingImage = false;
  

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabLabels.length, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _selectedTabIndex = _tabController.index;
        });
      }
    });
    _fetchVouchers();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }



  Future<void> _fetchVouchers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await ApiService.getAllVouchers();
      
      if (response.success) {
        final data = response.data;
        if (data is Map<String, dynamic> && data['vouchers'] != null) {
          final List<dynamic> vouchersJson = data['vouchers'];
          setState(() {
            _vouchers = vouchersJson.map((json) => Voucher.fromJson(json)).toList();
            _isLoading = false;
          });
          
          // Debug: Print voucher image URLs
          for (var voucher in _vouchers) {
            print('=== VOUCHER DEBUG ===');
            print('Voucher: ${voucher.name}');
            print('Raw image field: ${voucher.image}');
            print('Constructed URL: ${_getImageUrl(voucher.image)}');
            print('Target User Type: ${voucher.targetUserType}');
            print('=== END VOUCHER DEBUG ===');
          }
          
        } else {
          setState(() {
            _errorMessage = 'Invalid response format';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = response.message;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load vouchers. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: kIsWeb ? 800 : 1200,
        maxHeight: kIsWeb ? 600 : 1200,
        imageQuality: kIsWeb ? 85 : 90,
      );

      if (image != null) {
        setState(() {
          _isProcessingImage = true;
        });

        if (kIsWeb) {
          // For web, read as bytes
          final Uint8List bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null;
            _isProcessingImage = false;
          });
        } else {
          // For mobile, use File
          setState(() {
            _selectedImage = File(image.path);
            _selectedImageBytes = null;
            _isProcessingImage = false;
          });
        }
      }
    } catch (e) {
      setState(() {
        _isProcessingImage = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showCreateVoucherDialog() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Create New Voucher'),
            content: SizedBox(
              width: 400,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Voucher Name',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter voucher name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Description',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter description';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _pointsController,
                      decoration: const InputDecoration(
                        labelText: 'Points',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter points';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    // Image upload section
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              children: [
                                Text(
                                  'Voucher Image',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_selectedImage != null || _selectedImageBytes != null)
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(color: Colors.grey[300]!),
                                    ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: kIsWeb
                              ? Image.memory(
                                  _selectedImageBytes!,
                                  fit: BoxFit.cover,
                                  key: ValueKey('preview_$_refreshCounter'),
                                )
                              : Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                  key: ValueKey('preview_$_refreshCounter'),
                                ),
                        ),
                                  )
                                else
                                  Container(
                                    height: 120,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[100],
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey[300]!,
                                        style: BorderStyle.solid,
                                      ),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.image_outlined,
                                          size: 40,
                                          color: Colors.grey[400],
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'No image selected',
                                          style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: _isProcessingImage ? null : _pickImage,
                                        icon: _isProcessingImage
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.upload, size: 18),
                                        label: Text(_isProcessingImage ? 'Processing...' : 'Select Image'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: const Color(0xFF5B87EA),
                                          foregroundColor: Colors.white,
                                          padding: const EdgeInsets.symmetric(vertical: 12),
                                        ),
                                      ),
                                    ),
                                    if (_selectedImage != null || _selectedImageBytes != null) ...[
                                      const SizedBox(width: 8),
                                      IconButton(
                                        onPressed: () {
                                          setDialogState(() {
                                            _selectedImage = null;
                                            _selectedImageBytes = null;
                                          });
                                        },
                                        icon: const Icon(Icons.delete, color: Colors.red),
                                        tooltip: 'Remove Image',
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      value: _targetUserType,
                      decoration: const InputDecoration(
                        labelText: 'Target User Type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'user', child: Text('User')),
                        DropdownMenuItem(value: 'company', child: Text('Company')),
                        DropdownMenuItem(value: 'serviceProvider', child: Text('Service Provider')),
                        DropdownMenuItem(value: 'wholesaler', child: Text('Wholesaler')),
                      ],
                      onChanged: (value) {
                        setDialogState(() {
                          _targetUserType = value ?? 'user';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: _isCreatingVoucher ? null : () {
                  Navigator.of(context).pop();
                  _clearForm();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isCreatingVoucher ? null : () => _createVoucherFromDialog(setDialogState),
                child: _isCreatingVoucher
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Voucher'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _createVoucherFromDialog(StateSetter setDialogState) async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if image is selected
    if (_selectedImage == null && _selectedImageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image for the voucher'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setDialogState(() {
      _isCreatingVoucher = true;
    });

    try {
      ApiResponse response;
      
      if (kIsWeb && _selectedImageBytes != null) {
        // For web, use createUserTypeVoucherWithImage with bytes
        response = await ApiService.createUserTypeVoucherWithImage(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          points: int.parse(_pointsController.text.trim()),
          imageBytes: _selectedImageBytes!,
          targetUserType: _targetUserType,
        );
      } else if (!kIsWeb && _selectedImage != null) {
        // For mobile, read file as bytes and use createUserTypeVoucherWithImage
        final bytes = await _selectedImage!.readAsBytes();
        response = await ApiService.createUserTypeVoucherWithImage(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim(),
          points: int.parse(_pointsController.text.trim()),
          imageBytes: bytes,
          targetUserType: _targetUserType,
        );
      } else {
        throw Exception('No image selected');
      }

      if (response.success) {
        print('=== VOUCHER CREATION SUCCESS ===');
        print('Response data: ${response.data}');
        print('Response message: ${response.message}');
        
        Navigator.of(context).pop();
        _clearForm();
        
        // Add a longer delay to ensure the server has processed the image
        await Future.delayed(const Duration(milliseconds: 1500));
        
        // Force refresh by incrementing counter
        setState(() {
          _refreshCounter++;
        });
        
        // Refresh the voucher list
        await _fetchVouchers();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating voucher: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setDialogState(() {
        _isCreatingVoucher = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _pointsController.clear();
    _targetUserType = 'user';
    _selectedImage = null;
    _selectedImageBytes = null;
  }








  Future<void> _deleteVoucher(Voucher voucher) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voucher'),
        content: Text('Are you sure you want to delete "${voucher.name}"?'),
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

    if (confirmed == true) {
      try {
        final response = await ApiService.deleteVoucher(voucher.id);
        
        if (response.success) {
          _fetchVouchers();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Voucher deleted successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting voucher: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _toggleVoucherStatus(Voucher voucher) async {
    try {
      final response = await ApiService.toggleVoucherStatus(voucher.id);
      
      if (response.success) {
        _fetchVouchers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voucher ${voucher.isActive ? 'deactivated' : 'activated'} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating voucher status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }


  String _getImageUrl(String? imagePath) {
    print('=== Image URL Debug ===');
    print('Raw imagePath: $imagePath');
    print('ApiConstants.baseUrl: ${ApiConstants.baseUrl}');
    
    if (imagePath == null || imagePath.isEmpty) {
      print('Image path is null or empty');
      return '';
    }
    
    if (imagePath.startsWith('http')) {
      print('Image path is already a full URL: $imagePath');
      // Add cache busting parameter with refresh counter
      final separator = imagePath.contains('?') ? '&' : '?';
      return '$imagePath${separator}t=${DateTime.now().millisecondsSinceEpoch}&r=$_refreshCounter';
    }
    
    // Ensure path starts with /
    String path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    print('Processed path: $path');
    
    // Construct the full URL with cache busting and refresh counter
    final fullUrl = '${ApiConstants.baseUrl}$path?t=${DateTime.now().millisecondsSinceEpoch}&r=$_refreshCounter';
    print('Final constructed URL: $fullUrl');
    print('=== End Image URL Debug ===');
    return fullUrl;
  }

  String _formatTargetUserType(String userType) {
    switch (userType.toLowerCase()) {
      case 'user':
        return 'For Users';
      case 'company':
        return 'For Companies';
      case 'serviceprovider':
        return 'For Service Providers';
      case 'wholesaler':
        return 'For Wholesalers';
      default:
        return 'For ${userType[0].toUpperCase()}${userType.substring(1)}';
    }
  }

  List<Voucher> _getFilteredVouchers() {
    if (_selectedTabIndex == 0) {
      // Show all vouchers
      return _vouchers;
    }
    
    final selectedUserType = _tabUserTypes[_selectedTabIndex];
    return _vouchers.where((voucher) {
      return voucher.targetUserType == selectedUserType;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          // Header Component
          Container(
            padding: const EdgeInsets.all(20),
            child: HeaderComponent(
              logoPath: 'assets/logo/logo.png',
              scaffoldKey: _scaffoldKey,
              onMenuPressed: () {
                setState(() {
                  _isSidebarOpen = !_isSidebarOpen;
                });
              },
            ),
          ),
          
          // Main content area with overlay sidebar
          Expanded(
            child: Stack(
              children: [
                // Main content area (full width)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    children: [
                      // Page title
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: const Text(
                          'Voucher Management',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1752),
                          ),
                        ),
                      ),
                      
                      // Create voucher button
                      Container(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: _showCreateVoucherDialog,
                              icon: const Icon(Icons.add, size: 18),
                              label: const Text('Create Voucher'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5B87EA),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      // Tabs
                      Container(
                        margin: const EdgeInsets.only(bottom: 16),
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
                          isScrollable: true,
                          indicator: BoxDecoration(
                            color: const Color(0xFF5B87EA),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.grey[600],
                          labelStyle: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          unselectedLabelStyle: const TextStyle(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                          tabAlignment: TabAlignment.start,
                          tabs: _tabLabels.map((label) {
                            return Tab(
                              text: label,
                            );
                          }).toList(),
                        ),
                      ),
                
                      // Vouchers list
                      Expanded(
                        child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          spreadRadius: 1,
                          blurRadius: 5,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                          child: _buildVouchersList(),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Right Sidebar (overlay)
                if (_isSidebarOpen)
                  Positioned(
                    right: 0,
                    top: 0,
                    bottom: 0,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 280,
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 4,
                              offset: Offset(-2, 0),
                            ),
                          ],
                        ),
                        child: Sidebar(
                          parentContext: context,
                          onCollapse: () {
                                            setState(() {
                              _isSidebarOpen = false;
                                            });
                                          },
                        ),
                      ),
                    ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    
  }

  Widget _buildVouchersList() {
    final filteredVouchers = _getFilteredVouchers();
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF2079C2),
        ),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (_errorMessage.contains('not be implemented yet'))
              Container(
                padding: const EdgeInsets.all(16),
                margin: const EdgeInsets.symmetric(horizontal: 32),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: const Text(
                  'The voucher management feature is currently being developed. The backend endpoints need to be implemented first.',
                  style: TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              )
            else
              ElevatedButton(
                onPressed: _fetchVouchers,
                child: const Text('Retry'),
              ),
          ],
        ),
      );
    }

    if (filteredVouchers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _selectedTabIndex == 0 
                ? 'No vouchers found. Create your first voucher!'
                : 'No vouchers found for ${_tabLabels[_selectedTabIndex]}.',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Header
        Container(
          padding: const EdgeInsets.all(16),
          decoration: const BoxDecoration(
            color: Color(0xFFF8F9FA),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(10),
              topRight: Radius.circular(10),
            ),
          ),
          child: Row(
            children: [
              Text(
                _selectedTabIndex == 0 
                  ? 'All Vouchers'
                  : '${_tabLabels[_selectedTabIndex]} Vouchers',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1752),
                ),
              ),
              const Spacer(),
              Text(
                '${filteredVouchers.length} voucher${filteredVouchers.length == 1 ? '' : 's'}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        // List
        Expanded(
          child: ListView.builder(
            itemCount: filteredVouchers.length,
            itemBuilder: (context, index) {
              final voucher = filteredVouchers[index];
              return _buildVoucherCard(voucher);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    return Container(
      key: ValueKey('${voucher.id}_$_refreshCounter'),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 3,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Voucher image or icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFF2079C2).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: voucher.image != null && voucher.image!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _getImageUrl(voucher.image),
                          fit: BoxFit.cover,
                          key: ValueKey('${voucher.id}_image_$_refreshCounter'),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Color(0xFF2079C2),
                                strokeWidth: 2,
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('=== Image Loading Error ===');
                            print('Voucher: ${voucher.name}');
                            print('Raw image field: ${voucher.image}');
                            print('Constructed URL: ${_getImageUrl(voucher.image)}');
                            print('Error: $error');
                            print('Stack trace: $stackTrace');
                            
                            // Try alternative URL if the original contains '/vouchers/'
                            if (voucher.image != null && voucher.image!.contains('/vouchers/')) {
                              final alternativePath = voucher.image!.replaceFirst('/vouchers/', '/');
                              final alternativeUrl = '${ApiConstants.baseUrl}$alternativePath';
                              print('Trying alternative URL: $alternativeUrl');
                              
                              return Image.network(
                                alternativeUrl,
                                fit: BoxFit.cover,
                                key: ValueKey('${voucher.id}_alt_image_$_refreshCounter'),
                                errorBuilder: (context, error, stackTrace) {
                                  print('Alternative URL also failed: $error');
                                  return const Icon(
                                    Icons.card_giftcard,
                                    color: Color(0xFF2079C2),
                                    size: 30,
                                  );
                                },
                              );
                            }
                            
                            print('=== End Image Loading Error ===');
                            return const Icon(
                              Icons.card_giftcard,
                              color: Color(0xFF2079C2),
                              size: 30,
                            );
                          },
                        ),
                      )
                    : const Icon(
                        Icons.card_giftcard,
                        color: Color(0xFF2079C2),
                        size: 30,
                      ),
              ),
              const SizedBox(width: 16),
              // Voucher details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      voucher.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1752),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      voucher.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    // Target user type
                    if (voucher.targetUserType != null && voucher.targetUserType!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF5B87EA).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFF5B87EA).withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.person,
                              size: 14,
                              color: const Color(0xFF5B87EA),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTargetUserType(voucher.targetUserType!),
                              style: const TextStyle(
                                color: Color(0xFF5B87EA),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: voucher.isActive ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            voucher.isActive ? 'Active' : 'Inactive',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${voucher.points} pts',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2079C2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                onPressed: () => _toggleVoucherStatus(voucher),
                icon: Icon(
                  voucher.isActive ? Icons.pause : Icons.play_arrow,
                  size: 20,
                ),
                tooltip: voucher.isActive ? 'Deactivate' : 'Activate',
                style: IconButton.styleFrom(
                  foregroundColor: voucher.isActive ? Colors.orange : Colors.green,
                ),
              ),
              IconButton(
                onPressed: () => _deleteVoucher(voucher),
                icon: const Icon(Icons.delete, size: 20),
                tooltip: 'Delete Voucher',
                style: IconButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
