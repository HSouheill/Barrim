import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../components/sidebar.dart';
import '../../services/api_services.dart';
import '../../services/api_constant.dart';
import '../../models/voucher_model.dart';

class VoucherScreen extends StatefulWidget {
  const VoucherScreen({Key? key}) : super(key: key);

  @override
  State<VoucherScreen> createState() => _VoucherScreenState();
}

class _VoucherScreenState extends State<VoucherScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // State variables
  List<Voucher> _vouchers = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  
  // Form controllers for creating new voucher
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  
  bool _isCreatingVoucher = false;
  bool _showCreateForm = false;
  bool _isEditingVoucher = false;
  String? _editingVoucherId;
  File? _selectedImage;
  Uint8List? _selectedImageBytes;
  bool _isProcessingImage = false;

  @override
  void initState() {
    super.initState();
    _fetchVouchers();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
    });
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
            print('Voucher: ${voucher.name}');
            print('Raw image field: ${voucher.image}');
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
      setState(() {
        _isProcessingImage = true;
      });

      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: kIsWeb ? 800 : 1024, // Smaller for web to reduce processing time
        maxHeight: kIsWeb ? 800 : 1024,
        imageQuality: kIsWeb ? 70 : 80, // Lower quality for web
      );
      
      if (image != null) {
        if (kIsWeb) {
          // For web platform, read bytes asynchronously
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Processing image...'),
              duration: Duration(seconds: 2),
            ),
          );
          
          final Uint8List bytes = await image.readAsBytes();
          setState(() {
            _selectedImageBytes = bytes;
            _selectedImage = null; // Clear file reference for web
            _isProcessingImage = false;
          });
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Image processed successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );
        } else {
          // For mobile platforms, use File
          setState(() {
            _selectedImage = File(image.path);
            _selectedImageBytes = null; // Clear bytes for mobile
            _isProcessingImage = false;
          });
        }
      } else {
        setState(() {
          _isProcessingImage = false;
        });
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


  Future<void> _createVoucher() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if image is selected
    if ((kIsWeb && _selectedImageBytes == null) || (!kIsWeb && _selectedImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image for the voucher'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingVoucher = true;
    });

    try {
      final response = kIsWeb 
        ? await ApiService.createVoucherWeb(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            points: int.parse(_pointsController.text),
            imageBytes: _selectedImageBytes!,
            filename: 'voucher_image.jpg',
          )
        : await ApiService.createVoucher(
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            points: int.parse(_pointsController.text),
            imageFile: _selectedImage!,
          );

      if (response.success) {
        // Clear form
        _clearForm();
        
        // Hide form and refresh vouchers
        setState(() {
          _showCreateForm = false;
        });
        
        _fetchVouchers();
        
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
      String errorMessage = 'Error creating voucher: $e';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Upload timeout: Please try again with a smaller image or check your internet connection.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error: Please check your internet connection and try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isCreatingVoucher = false;
      });
    }
  }

  Future<void> _updateVoucher() async {
    if (!_formKey.currentState!.validate()) return;
    
    // Check if image is selected for update
    if ((kIsWeb && _selectedImageBytes == null) || (!kIsWeb && _selectedImage == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an image for the voucher'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isCreatingVoucher = true;
    });

    try {
      final response = kIsWeb 
        ? await ApiService.updateVoucherWithImageWeb(
            voucherId: _editingVoucherId!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            points: int.parse(_pointsController.text),
            imageBytes: _selectedImageBytes!,
            filename: 'voucher_image.jpg',
          )
        : await ApiService.updateVoucherWithImage(
            voucherId: _editingVoucherId!,
            name: _nameController.text.trim(),
            description: _descriptionController.text.trim(),
            points: int.parse(_pointsController.text),
            imageFile: _selectedImage!,
          );

      if (response.success) {
        // Clear form
        _clearForm();
        
        // Hide form and refresh vouchers
        setState(() {
          _showCreateForm = false;
          _isEditingVoucher = false;
          _editingVoucherId = null;
        });
        
        _fetchVouchers();
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voucher updated successfully!'),
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
      String errorMessage = 'Error updating voucher: $e';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Upload timeout: Please try again with a smaller image or check your internet connection.';
      } else if (e.toString().contains('network')) {
        errorMessage = 'Network error: Please check your internet connection and try again.';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isCreatingVoucher = false;
      });
    }
  }

  void _clearForm() {
    _nameController.clear();
    _descriptionController.clear();
    _pointsController.clear();
    _selectedImage = null;
    _selectedImageBytes = null;
  }

  void _editVoucher(Voucher voucher) {
    setState(() {
      _isEditingVoucher = true;
      _editingVoucherId = voucher.id;
      _nameController.text = voucher.name;
      _descriptionController.text = voucher.description;
      _pointsController.text = voucher.points.toString();
      _selectedImage = null; // Reset image selection for editing
      _selectedImageBytes = null; // Reset image bytes for editing
      _showCreateForm = true;
    });
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

  List<Voucher> get _filteredVouchers {
    if (_searchQuery.isEmpty) return _vouchers;
    
    return _vouchers.where((voucher) {
      return voucher.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
             voucher.description.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  String _getImageUrl(String? imagePath) {
    if (imagePath == null || imagePath.isEmpty) return '';
    
    if (imagePath.startsWith('http')) {
      return imagePath;
    }
    
    // Ensure path starts with /
    String path = imagePath.startsWith('/') ? imagePath : '/$imagePath';
    
    // Construct the full URL
    final fullUrl = '${ApiConstants.baseUrl}$path';
    print('Image URL constructed: $fullUrl');
    return fullUrl;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Voucher Management'),
        backgroundColor: const Color(0xFF5B87EA),
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
      ),
      drawer: Sidebar(
        parentContext: context,
        onCollapse: () {
          if (_scaffoldKey.currentState!.isDrawerOpen) {
            _scaffoldKey.currentState!.closeDrawer();
          }
        },
      ),
      body: Row(
        children: [
          // Main content
          Expanded(
            child: Column(
              children: [
                // Header section
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Search bar
                      Expanded(
                        flex: 2,
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
                          child: TextField(
                            controller: _searchController,
                            decoration: const InputDecoration(
                              hintText: 'Search vouchers...',
                              prefixIcon: Icon(Icons.search, color: Colors.grey),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      // Create voucher button
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() {
                            _showCreateForm = !_showCreateForm;
                          });
                        },
                        icon: const Icon(Icons.add),
                        label: const Text('Create Voucher'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2079C2),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
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
                
                // Create voucher form
                if (_showCreateForm)
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
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
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isEditingVoucher ? 'Edit Voucher' : 'Create New Voucher',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D1752),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _nameController,
                                  decoration: const InputDecoration(
                                    labelText: 'Voucher Name',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.card_giftcard),
                                  ),
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter voucher name';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextFormField(
                                  controller: _pointsController,
                                  decoration: const InputDecoration(
                                    labelText: 'Points Required',
                                    border: OutlineInputBorder(),
                                    prefixIcon: Icon(Icons.stars),
                                  ),
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  validator: (value) {
                                    if (value == null || value.trim().isEmpty) {
                                      return 'Please enter points';
                                    }
                                    if (int.tryParse(value) == null || int.parse(value) <= 0) {
                                      return 'Please enter valid points';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _descriptionController,
                            decoration: const InputDecoration(
                              labelText: 'Description',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.description),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Please enter description';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          // Image picker section
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey[300]!),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Padding(
                                  padding: EdgeInsets.all(12.0),
                                  child: Text(
                                    'Voucher Image *',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if ((kIsWeb && _selectedImageBytes != null) || (!kIsWeb && _selectedImage != null)) ...[
                                  Container(
                                    margin: const EdgeInsets.all(12),
                                    height: 200,
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
                                          )
                                        : Image.file(
                                            _selectedImage!,
                                            fit: BoxFit.cover,
                                          ),
                                    ),
                                  ),
                                ],
                                Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: _isProcessingImage ? null : _pickImage,
                                          icon: _isProcessingImage 
                                            ? const SizedBox(
                                                width: 16,
                                                height: 16,
                                                child: CircularProgressIndicator(
                                                  color: Colors.white,
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Icon(Icons.photo_library),
                                          label: Text(
                                            _isProcessingImage 
                                              ? 'Processing...'
                                              : (kIsWeb && _selectedImageBytes == null) || (!kIsWeb && _selectedImage == null) 
                                                  ? 'Select Image' 
                                                  : 'Change Image'
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: const Color(0xFF2079C2),
                                            foregroundColor: Colors.white,
                                          ),
                                        ),
                                      ),
                                      if ((kIsWeb && _selectedImageBytes != null) || (!kIsWeb && _selectedImage != null)) ...[
                                        const SizedBox(width: 12),
                                        IconButton(
                                          onPressed: () {
                                            setState(() {
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
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _showCreateForm = false;
                                    _isEditingVoucher = false;
                                    _editingVoucherId = null;
                                  });
                                  _clearForm();
                                },
                                child: const Text('Cancel'),
                              ),
                              const SizedBox(width: 16),
                              ElevatedButton(
                                onPressed: _isCreatingVoucher ? null : (_isEditingVoucher ? _updateVoucher : _createVoucher),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2079C2),
                                  foregroundColor: Colors.white,
                                ),
                                child: _isCreatingVoucher
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : Text(_isEditingVoucher ? 'Update Voucher' : 'Create Voucher'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                
                // Vouchers list
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.all(20),
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
        ],
      ),
    );
  }

  Widget _buildVouchersList() {
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

    if (_filteredVouchers.isEmpty) {
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
              _searchQuery.isEmpty
                  ? 'No vouchers found. Create your first voucher!'
                  : 'No vouchers match your search.',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
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
              const Text(
                'Vouchers',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1752),
                ),
              ),
              const Spacer(),
              Text(
                '${_filteredVouchers.length} voucher${_filteredVouchers.length == 1 ? '' : 's'}',
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
            itemCount: _filteredVouchers.length,
            itemBuilder: (context, index) {
              final voucher = _filteredVouchers[index];
              return _buildVoucherCard(voucher);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildVoucherCard(Voucher voucher) {
    return Container(
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
                            print('Image loading failed for ${voucher.name}: $error');
                            print('Failed URL: ${_getImageUrl(voucher.image)}');
                            
                            // Try alternative URL if the original contains '/vouchers/'
                            if (voucher.image != null && voucher.image!.contains('/vouchers/')) {
                              final alternativePath = voucher.image!.replaceFirst('/vouchers/', '/');
                              final alternativeUrl = '${ApiConstants.baseUrl}$alternativePath';
                              print('Trying alternative URL: $alternativeUrl');
                              
                              return Image.network(
                                alternativeUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.card_giftcard,
                                    color: Color(0xFF2079C2),
                                    size: 30,
                                  );
                                },
                              );
                            }
                            
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
                onPressed: () => _editVoucher(voucher),
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Edit Voucher',
                style: IconButton.styleFrom(
                  foregroundColor: const Color(0xFF2079C2),
                ),
              ),
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
