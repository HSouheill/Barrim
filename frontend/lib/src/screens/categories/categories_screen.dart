import 'package:flutter/material.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_svg/flutter_svg.dart';
import '../../components/header.dart';
import '../../components/sidebar.dart';
import '../../components/add_category_popup.dart';
import '../../components/add_service_provider_category_popup.dart';
import '../../components/add_wholesaler_category_popup.dart';
import '../../models/category.dart';
import '../../models/service_provider_category.dart';
import '../../models/wholesaler_category.dart';
import '../../services/category_service.dart';
import '../../services/public_service_provider_category_service.dart';
import '../../services/service_provider_category_service.dart';
import '../../services/wholesaler_category_service.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedTabIndex = 0;
  final String _logoPath = 'assets/logo/logo.png';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final TextEditingController _searchController = TextEditingController();
  final CategoryApiService _categoryService = CategoryApiService();
  final PublicServiceProviderCategoryService _publicSpCategoryService = PublicServiceProviderCategoryService();
  final ServiceProviderCategoryService _spCategoryService = ServiceProviderCategoryService();
  final WholesalerCategoryService _wholesalerCategoryService = WholesalerCategoryService();

  List<Category> _categories = [];
  List<ServiceProviderCategory> _serviceProviderCategories = [];
  List<WholesalerCategory> _wholesalerCategories = [];
  bool _isLoading = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _loadServiceProviderCategories();
    _loadWholesalerCategories();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _categoryService.getAllCategories();
      if (response.status == 200) {
        setState(() {
          _categories = response.categories;
        });
      } else {
        setState(() {
          _errorMessage = response.message;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadServiceProviderCategories() async {
    try {
      final response = await _publicSpCategoryService.getAllServiceProviderCategories();
      if (response.status == 200) {
        setState(() {
          _serviceProviderCategories = response.categories;
        });
      }
    } catch (e) {
      print('Failed to load service provider categories: $e');
    }
  }

  Future<void> _loadWholesalerCategories() async {
    try {
      final response = await _wholesalerCategoryService.getAllWholesalerCategories();
      if (response.status == 200) {
        setState(() {
          _wholesalerCategories = response.categories;
        });
      }
    } catch (e) {
      print('Failed to load wholesaler categories: $e');
    }
  }

  void _showAddCategoryPopup() {
    showDialog(
      context: context,
      builder: (context) => const AddCategoryPopup(),
    ).then((result) {
      if (result != null) {
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Category ${result.id == null ? 'created' : 'updated'} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showEditCategoryPopup(Category category) {
    showDialog(
      context: context,
      builder: (context) => AddCategoryPopup(
        categoryId: category.id,
        initialName: category.name,
        initialColor: category.backgroundColor,
        initialImageUrl: category.logo,
        initialSubcategories: category.subcategories,
      ),
    ).then((result) {
      if (result != null) {
        _loadCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Category updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _deleteCategory(Category category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _categoryService.deleteCategory(category.id!);
        if (response.status == 200) {
          _loadCategories();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
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
            content: Text('Failed to delete category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Category> get _filteredCategories {
    if (_searchController.text.isEmpty) {
      return _categories;
    }
    return _categories.where((category) =>
      category.name.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  List<ServiceProviderCategory> get _filteredServiceProviderCategories {
    if (_searchController.text.isEmpty) {
      return _serviceProviderCategories;
    }
    return _serviceProviderCategories.where((category) =>
      category.name.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  List<WholesalerCategory> get _filteredWholesalerCategories {
    if (_searchController.text.isEmpty) {
      return _wholesalerCategories;
    }
    return _wholesalerCategories.where((category) =>
      category.name.toLowerCase().contains(_searchController.text.toLowerCase())
    ).toList();
  }

  // Service Provider Category Methods
  void _showAddServiceProviderCategoryPopup() {
    showDialog(
      context: context,
      builder: (context) => AddServiceProviderCategoryPopup(
        onSubmit: (name) async {
          await _createServiceProviderCategory(name, null);
          Navigator.of(context).pop();
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }

  void _showEditServiceProviderCategoryPopup(ServiceProviderCategory category) {
    showDialog(
      context: context,
      builder: (context) => AddServiceProviderCategoryPopup(
        category: category,
        onCancel: () => Navigator.of(context).pop(),
        onSubmit: (name) async {
          await _updateServiceProviderCategory(category.id!, name, null);
          Navigator.of(context).pop();
        },
      ),
    );
  }

  Future<void> _createServiceProviderCategory(String name, File? imageFile) async {
    try {
      final response = await _spCategoryService.createServiceProviderCategory(name, imageFile: imageFile);
      if (response.status == 201) {
        _loadServiceProviderCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _updateServiceProviderCategory(String id, String name, File? imageFile) async {
    try {
      final response = await _spCategoryService.updateServiceProviderCategory(
        id,
        {'name': name},
        imageFile: imageFile,
      );
      if (response.status == 200) {
        _loadServiceProviderCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message), backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    }
  }

  // Wholesaler Category Methods
  void _showAddWholesalerCategoryPopup() {
    showDialog(
      context: context,
      builder: (context) => const AddWholesalerCategoryPopup(),
    ).then((result) {
      if (result != null) {
        _loadWholesalerCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Wholesaler category ${result.id == null ? 'created' : 'updated'} successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  void _showEditWholesalerCategoryPopup(WholesalerCategory category) {
    showDialog(
      context: context,
      builder: (context) => AddWholesalerCategoryPopup(
        categoryId: category.id,
        initialName: category.name,
        initialSubcategories: category.subcategories,
      ),
    ).then((result) {
      if (result != null) {
        _loadWholesalerCategories();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Wholesaler category updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    });
  }

  Future<void> _deleteWholesalerCategory(WholesalerCategory category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Wholesaler Category'),
        content: Text('Are you sure you want to delete "${category.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        final response = await _wholesalerCategoryService.deleteWholesalerCategory(category.id!);
        if (response.status == 200) {
          _loadWholesalerCategories();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response.message),
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
            content: Text('Failed to delete wholesaler category: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _deleteServiceProviderCategory(ServiceProviderCategory category) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service Provider Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                final response = await _spCategoryService.deleteServiceProviderCategory(category.id!);
                if (response.status == 200) {
                  _loadServiceProviderCategories();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(response.message),
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
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      endDrawer: Sidebar(
        onCollapse: () => _scaffoldKey.currentState?.closeEndDrawer(),
        parentContext: context,
      ),

      body: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
        ),
        child: Column(
          children: [
            HeaderComponent(
              logoPath: _logoPath,
              scaffoldKey: _scaffoldKey,
              onMenuPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Responsive tab layout with proper overflow handling
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final isCompact = availableWidth < 600;
                        
                        return Row(
                          children: [
                            Expanded(
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    GestureDetector(
                                      onTap: () => setState(() => _selectedTabIndex = 0),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isCompact ? 16 : 20,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: _selectedTabIndex == 0 
                                                ? const Color(0xFF2079C2) 
                                                : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Companies',
                                          style: TextStyle(
                                            fontSize: isCompact ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedTabIndex == 0 
                                              ? const Color(0xFF2079C2) 
                                              : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isCompact ? 16 : 20),
                                    GestureDetector(
                                      onTap: () => setState(() => _selectedTabIndex = 1),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isCompact ? 16 : 20,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: _selectedTabIndex == 1 
                                                ? const Color(0xFF2079C2) 
                                                : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Services',
                                          style: TextStyle(
                                            fontSize: isCompact ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedTabIndex == 1 
                                              ? const Color(0xFF2079C2) 
                                              : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: isCompact ? 16 : 20),
                                    GestureDetector(
                                      onTap: () => setState(() => _selectedTabIndex = 2),
                                      child: Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: isCompact ? 16 : 20,
                                          vertical: 12,
                                        ),
                                        decoration: BoxDecoration(
                                          border: Border(
                                            bottom: BorderSide(
                                              color: _selectedTabIndex == 2 
                                                ? const Color(0xFF2079C2) 
                                                : Colors.transparent,
                                              width: 2,
                                            ),
                                          ),
                                        ),
                                        child: Text(
                                          'Wholesalers',
                                          style: TextStyle(
                                            fontSize: isCompact ? 14 : 16,
                                            fontWeight: FontWeight.w600,
                                            color: _selectedTabIndex == 2 
                                              ? const Color(0xFF2079C2) 
                                              : Colors.grey[600],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Add button for the current tab
                            GestureDetector(
                              onTap: _selectedTabIndex == 0 
                                  ? _showAddCategoryPopup 
                                  : _selectedTabIndex == 1
                                      ? _showAddServiceProviderCategoryPopup
                                      : _showAddWholesalerCategoryPopup,
                              child: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10105D),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.2),
                                      blurRadius: 4,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    // Responsive search bar and add button layout
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final availableWidth = constraints.maxWidth;
                        final isCompact = availableWidth < 500;
                        
                        return Row(
                          children: [
                            Expanded(
                              child: Container(
                                height: 50,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF10105D),
                                  borderRadius: BorderRadius.circular(25),
                                ),
                                child: TextField(
                                  controller: _searchController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: const InputDecoration(
                                    hintText: 'Search',
                                    hintStyle: TextStyle(color: Colors.white70),
                                    prefixIcon: Icon(Icons.search, color: Colors.white),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                                  ),
                                  onChanged: (value) {
                                    setState(() {});
                                  },
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            // Prominent Add Category Button for Companies tab
                            if (_selectedTabIndex == 0)
                              isCompact
                                ? IconButton(
                                    onPressed: _showAddCategoryPopup,
                                    icon: const Icon(Icons.add, color: Colors.white, size: 24),
                                    tooltip: 'Add Category',
                                    style: IconButton.styleFrom(
                                      backgroundColor: const Color(0xFF1708FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.all(12),
                                      minimumSize: const Size(44, 44),
                                    ),
                                  )
                                : ElevatedButton.icon(
                                    onPressed: _showAddCategoryPopup,
                                    icon: const Icon(Icons.add, color: Colors.white, size: 20),
                                    label: const Text(
                                      'Add Category',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1708FF),
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(25),
                                      ),
                                      elevation: 4,
                                      shadowColor: Colors.black.withValues(alpha: 0.3),
                                    ),
                                  ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 30),
                    Expanded(
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _errorMessage.isNotEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        _errorMessage,
                                        style: const TextStyle(color: Colors.red),
                                        textAlign: TextAlign.center,
                                      ),
                                      const SizedBox(height: 16),
                                      ElevatedButton(
                                        onPressed: _loadCategories,
                                        child: const Text('Retry'),
                                      ),
                                    ],
                                  ),
                                )
                              : _selectedTabIndex == 0
                                  ? _buildCategoriesGrid()
                                  : _selectedTabIndex == 1
                                      ? _buildServiceProviderCategoriesGrid()
                                      : _buildWholesalerCategoriesGrid(),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoriesGrid() {
    if (_filteredCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.category_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No company categories found'
                  : 'No company categories match your search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showAddCategoryPopup,
                child: const Text('Add First Company Category'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85, // Adjusted to prevent overflow
      ),
      itemCount: _filteredCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredCategories[index];
        return GestureDetector(
          onTap: () => _showEditCategoryPopup(category),
          onLongPress: () => _deleteCategory(category),
          child: Column(
            children: [
                                                                          Container(
                width: double.infinity,
                height: 100, // Reduced height to prevent overflow
                decoration: BoxDecoration(
                  color: Color(int.parse(category.backgroundColor.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(12), // Reduced border radius
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4, // Reduced shadow
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    // Background color layer (behind the image)
                    Container(
                      width: double.infinity,
                      height: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(int.parse(category.backgroundColor.replaceAll('#', '0xFF'))),
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    if (category.logo != null) ...[
                      // Debug: Print logo loading attempt
                      Builder(
                        builder: (context) {
                          print('=== Attempting to load logo for ${category.name} ===');
                          print('Logo URL: ${category.logo}');
                          
                          // Test URL accessibility
                          if (category.logo != null) {
                            print('Testing URL accessibility for ${category.name}...');
                            // Test with different approaches
                            // 1. Basic GET request
                            print('Testing basic GET request for ${category.name}...');
                            http.get(Uri.parse(category.logo!)).then((response) {
                              print('URL Test for ${category.name}: Status ${response.statusCode}');
                              print('Response headers: ${response.headers}');
                              if (response.statusCode != 200) {
                                print('Failed to access image URL: ${response.body}');
                              } else {
                                print('Successfully accessed image URL for ${category.name}');
                                print('Content-Type: ${response.headers['content-type']}');
                                print('Content-Length: ${response.headers['content-length']}');
                              }
                            }).catchError((error) {
                              print('Error testing URL for ${category.name}: $error');
                              print('Error type: ${error.runtimeType}');
                              print('Error details: $error');
                            });
                            
                            // 2. Test with User-Agent header (some servers block requests without proper headers)
                            print('Testing with User-Agent header for ${category.name}...');
                            http.get(
                              Uri.parse(category.logo!),
                              headers: {'User-Agent': 'Flutter/AdminDashboard'},
                            ).then((response) {
                              print('URL Test with User-Agent for ${category.name}: Status ${response.statusCode}');
                            }).catchError((error) {
                              print('Error testing URL with User-Agent for ${category.name}: $error');
                            });
                            
                            // 3. Test with additional headers that might help
                            print('Testing with additional headers for ${category.name}...');
                            http.get(
                              Uri.parse(category.logo!),
                              headers: {
                                'User-Agent': 'Flutter/AdminDashboard',
                                'Accept': 'image/*',
                                'Accept-Encoding': 'gzip, deflate',
                              },
                            ).then((response) {
                              print('URL Test with image headers for ${category.name}: Status ${response.statusCode}');
                            }).catchError((error) {
                              print('Error testing URL with image headers for ${category.name}: $error');
                            });
                          }
                          
                          return const SizedBox.shrink();
                        },
                      ),
                      // Base image (supports SVG and raster)
                      Center(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Builder(
                            builder: (context) {
                              final String baseUrl = category.logo!;
                              final String url = category.updatedAt != null
                                  ? (baseUrl.contains('?')
                                      ? '$baseUrl&v=${category.updatedAt!.millisecondsSinceEpoch}'
                                      : '$baseUrl?v=${category.updatedAt!.millisecondsSinceEpoch}')
                                  : baseUrl;
                              final bool isSvg = url.toLowerCase().endsWith('.svg');
                              if (isSvg) {
                                return SvgPicture.network(
                                  url,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.contain,
                                  placeholderBuilder: (context) => const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                  ),
                                );
                              }
                              return Image.network(
                                url,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return CircularProgressIndicator(
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                        : null,
                                    color: Colors.white,
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  // Debug: Print the actual error details
                                  print('=== Image Loading Error for ${category.name} ===');
                                  print('Logo URL: ${category.logo}');
                                  print('Error: $error');
                                  print('Stack Trace: $stackTrace');
                                  print('=== End Image Error Debug ===');
                                  
                                  // Check if it's an HTML/XML error (backend returning error pages)
                                  if (error.toString().contains('DOCTYPE') || 
                                      error.toString().contains('html') ||
                                      error.toString().contains('xml')) {
                                    return Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          Icons.warning,
                                          color: Colors.orange,
                                          size: 32,
                                        ),
                                        Text(
                                          'Backend\nError',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.orange,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                        Text(
                                          'Image endpoint\nreturning HTML',
                                          style: TextStyle(
                                            fontSize: 8,
                                            color: Colors.orange,
                                          ),
                                          textAlign: TextAlign.center,
                                        ),
                                      ],
                                    );
                                  }
                                  
                                  // Default error display with fallback icon
                                  return Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.category,
                                        color: Colors.white,
                                        size: 48,
                                      ),
                                      Text(
                                        'Logo\nUnavailable',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.white,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      Text(
                                        'Network issue',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.white70,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ] else
                      Center(
                        child: Icon(
                          Icons.category,
                          color: Colors.white,
                          size: 48,
                        ),
                      ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                    // Color indicator badge
                    Positioned(
                      bottom: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 12,
                              height: 12,
                              decoration: BoxDecoration(
                                color: Color(int.parse(category.backgroundColor.replaceAll('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(3),
                                border: Border.all(color: Colors.grey.shade400),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              category.backgroundColor,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade700,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6), // Reduced spacing
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 13, // Slightly smaller font
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF10105D),
                ),
                textAlign: TextAlign.center,
                maxLines: 1, // Reduced to 1 line to prevent overflow
                overflow: TextOverflow.ellipsis,
              ),
              if (category.subcategories.isNotEmpty) ...[
                const SizedBox(height: 2), // Minimal spacing
                Text(
                  'Subcategories: ${category.subcategories.take(2).join(', ')}${category.subcategories.length > 2 ? '...' : ''}',
                  style: TextStyle(
                    fontSize: 9, // Smaller font
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 2), // Minimal spacing
              Text(
                'Long press to delete',
                style: TextStyle(
                  fontSize: 9, // Smaller font
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildServiceProviderCategoriesGrid() {
    if (_filteredServiceProviderCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.handyman_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No service provider categories found'
                  : 'No service provider categories match your search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showAddServiceProviderCategoryPopup,
                child: const Text('Add First Service Category'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85, // Adjusted to prevent overflow
      ),
      itemCount: _filteredServiceProviderCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredServiceProviderCategories[index];
        return GestureDetector(
          onTap: () => _showEditServiceProviderCategoryPopup(category),
          onLongPress: () => _deleteServiceProviderCategory(category),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 100, // Reduced height to prevent overflow
                decoration: BoxDecoration(
                  color: const Color(0xFF1708FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12), // Reduced border radius
                  border: Border.all(color: const Color(0xFF1708FF).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4, // Reduced shadow
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.handyman,
                        color: const Color(0xFF1708FF),
                        size: 48,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF10105D),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (category.createdAt != null)
                Text(
                  'Created: ${category.createdAt!.year}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              Text(
                'Long press to delete',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWholesalerCategoriesGrid() {
    if (_filteredWholesalerCategories.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No wholesaler categories found'
                  : 'No wholesaler categories match your search',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
              ),
            ),
            if (_searchController.text.isEmpty) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _showAddWholesalerCategoryPopup,
                child: const Text('Add First Wholesaler Category'),
              ),
            ],
          ],
        ),
      );
    }

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85, // Adjusted to prevent overflow
      ),
      itemCount: _filteredWholesalerCategories.length,
      itemBuilder: (context, index) {
        final category = _filteredWholesalerCategories[index];
        return GestureDetector(
          onTap: () => _showEditWholesalerCategoryPopup(category),
          onLongPress: () => _deleteWholesalerCategory(category),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                height: 100, // Reduced height to prevent overflow
                decoration: BoxDecoration(
                  color: const Color(0xFF1708FF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12), // Reduced border radius
                  border: Border.all(color: const Color(0xFF1708FF).withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4, // Reduced shadow
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Icon(
                        Icons.store,
                        color: const Color(0xFF1708FF),
                        size: 48,
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.edit,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                category.name,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF10105D),
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (category.subcategories.isNotEmpty)
                Text(
                  'Subcategories: ${category.subcategories.take(2).join(', ')}${category.subcategories.length > 2 ? '...' : ''}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              if (category.createdAt != null)
                Text(
                  'Created: ${category.createdAt!.year}',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey[500],
                  ),
                  textAlign: TextAlign.center,
                ),
              Text(
                'Long press to delete',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey[500],
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        );
      },
    );
  }
}