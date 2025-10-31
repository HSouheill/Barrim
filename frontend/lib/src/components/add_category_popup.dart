import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:typed_data';
import '../models/category.dart';
import '../services/category_service.dart';
import 'package:flutter_svg/flutter_svg.dart';

class AddCategoryPopup extends StatefulWidget {
  final String? categoryId; // For editing existing category
  final String? initialName;
  final String? initialColor;
  final String? initialImageUrl;
  final List<String>? initialSubcategories;

  const AddCategoryPopup({
    Key? key,
    this.categoryId,
    this.initialName,
    this.initialColor,
    this.initialImageUrl,
    this.initialSubcategories,
  }) : super(key: key);

  @override
  _AddCategoryPopupState createState() => _AddCategoryPopupState();
}

class _AddCategoryPopupState extends State<AddCategoryPopup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subcategoriesController = TextEditingController();
  final _colorController = TextEditingController();
  final CategoryApiService _categoryService = CategoryApiService();
  final ImagePicker _imagePicker = ImagePicker();
  
  String _selectedColor = '#1708FF';
  String? _selectedImageUrl;
  File? _selectedImageFile;
  XFile? _webImageFile; // For web file handling
  bool _isLoading = false;
  bool _isUploadingImage = false;
  bool _isDragOver = false;
  int _selectedColorTab = 0;

  // Enhanced color palette organized by categories
  final Map<String, List<Map<String, dynamic>>> _colorPalette = {
    'Primary': [
      {'color': '#1708FF', 'name': 'Primary Blue'},
      {'color': '#0D47A1', 'name': 'Deep Blue'},
      {'color': '#1976D2', 'name': 'Material Blue'},
      {'color': '#2196F3', 'name': 'Light Blue'},
      {'color': '#64B5F6', 'name': 'Sky Blue'},
      {'color': '#90CAF9', 'name': 'Pale Blue'},
    ],
    'Secondary': [
      {'color': '#FF1708', 'name': 'Primary Red'},
      {'color': '#D32F2F', 'name': 'Deep Red'},
      {'color': '#F44336', 'name': 'Material Red'},
      {'color': '#E57373', 'name': 'Light Red'},
      {'color': '#FFCDD2', 'name': 'Pale Red'},
    ],
    'Accent': [
      {'color': '#FF8000', 'name': 'Orange'},
      {'color': '#FF9800', 'name': 'Material Orange'},
      {'color': '#FFB74D', 'name': 'Light Orange'},
      {'color': '#FFCC02', 'name': 'Yellow'},
      {'color': '#FFEB3B', 'name': 'Material Yellow'},
      {'color': '#FFF176', 'name': 'Light Yellow'},
    ],
    'Nature': [
      {'color': '#08FF17', 'name': 'Bright Green'},
      {'color': '#4CAF50', 'name': 'Material Green'},
      {'color': '#81C784', 'name': 'Light Green'},
      {'color': '#C8E6C9', 'name': 'Pale Green'},
      {'color': '#8BC34A', 'name': 'Lime Green'},
      {'color': '#CDDC39', 'name': 'Lime'},
    ],
    'Purple': [
      {'color': '#8000FF', 'name': 'Deep Purple'},
      {'color': '#9C27B0', 'name': 'Material Purple'},
      {'color': '#BA68C8', 'name': 'Light Purple'},
      {'color': '#E1BEE7', 'name': 'Pale Purple'},
      {'color': '#673AB7', 'name': 'Indigo'},
      {'color': '#9575CD', 'name': 'Light Indigo'},
    ],
    'Neutral': [
      {'color': '#424242', 'name': 'Dark Grey'},
      {'color': '#757575', 'name': 'Grey'},
      {'color': '#9E9E9E', 'name': 'Light Grey'},
      {'color': '#BDBDBD', 'name': 'Pale Grey'},
      {'color': '#E0E0E0', 'name': 'Very Light Grey'},
      {'color': '#F5F5F5', 'name': 'Off White'},
    ],
    'Warm': [
      {'color': '#FF5722', 'name': 'Deep Orange'},
      {'color': '#FF7043', 'name': 'Light Deep Orange'},
      {'color': '#FF8A65', 'name': 'Pale Deep Orange'},
      {'color': '#D84315', 'name': 'Dark Orange'},
      {'color': '#E64A19', 'name': 'Medium Orange'},
    ],
    'Cool': [
      {'color': '#00BCD4', 'name': 'Cyan'},
      {'color': '#4DD0E1', 'name': 'Light Cyan'},
      {'color': '#B2EBF2', 'name': 'Pale Cyan'},
      {'color': '#0097A7', 'name': 'Dark Cyan'},
      {'color': '#006064', 'name': 'Very Dark Cyan'},
    ],
  };

  // Recent colors
  List<String> _recentColors = [];

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _colorController.text = widget.initialColor ?? '#1708FF';
    _selectedColor = widget.initialColor ?? '#1708FF';
    _selectedImageUrl = widget.initialImageUrl;
    
    // Initialize subcategories controller with existing subcategories
    if (widget.initialSubcategories != null && widget.initialSubcategories!.isNotEmpty) {
      _subcategoriesController.text = widget.initialSubcategories!.join(', ');
    }
    
    // Initialize recent colors with some defaults
    _recentColors = [
      '#1708FF', '#FF1708', '#08FF17', '#FF8000', '#8000FF'
    ];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subcategoriesController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  void _addToRecentColors(String color) {
    if (!_recentColors.contains(color)) {
      setState(() {
        _recentColors.insert(0, color);
        if (_recentColors.length > 10) {
          _recentColors.removeLast();
        }
      });
    }
  }

  void _selectColor() {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Row(
              children: [
                Icon(Icons.palette, color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF')))),
                const SizedBox(width: 8),
                const Text('Select Color'),
              ],
            ),
            content: Container(
              width: MediaQuery.of(context).size.width * 0.85, // Responsive width
              height: MediaQuery.of(context).size.height * 0.7, // Responsive height
              child: Column(
                children: [
                  // Color preview
                  Container(
                    width: double.infinity,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Center(
                      child: Text(
                        _selectedColor,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Recent colors
                  if (_recentColors.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.history, size: 16),
                        const SizedBox(width: 8),
                        const Text('Recent Colors', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _recentColors.map((color) {
                        final isSelected = _selectedColor == color;
                        return GestureDetector(
                          onTap: () {
                            setDialogState(() {
                              _selectedColor = color;
                              _colorController.text = color;
                            });
                          },
                          child: Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                              border: Border.all(
                                color: isSelected ? Colors.black : Colors.grey.shade400,
                                width: isSelected ? 3 : 1,
                              ),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 16)
                                : null,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  
                  // Color categories tabs
                  Expanded(
                    child: DefaultTabController(
                      length: _colorPalette.length,
                      child: Column(
                        children: [
                          Container(
                            height: 40,
                            child: TabBar(
                              isScrollable: true,
                              tabs: _colorPalette.keys.map((category) => 
                                Tab(text: category)
                              ).toList(),
                              onTap: (index) {
                                setDialogState(() {
                                  _selectedColorTab = index;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 8),
                          Expanded(
                            child: TabBarView(
                              children: _colorPalette.values.map((colors) {
                                return GridView.builder(
                                  shrinkWrap: true,
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 6,
                                    crossAxisSpacing: 8,
                                    mainAxisSpacing: 8,
                                    childAspectRatio: 1.0,
                                  ),
                                  itemCount: colors.length,
                                  itemBuilder: (context, index) {
                                    final colorOption = colors[index];
                                    final colorString = colorOption['color'] as String;
                                    final colorName = colorOption['name'] as String;
                                    final isSelected = _selectedColor == colorString;
                                    return GestureDetector(
                                      onTap: () {
                                        setDialogState(() {
                                          _selectedColor = colorString;
                                          _colorController.text = colorString;
                                        });
                                      },
                                      child: Tooltip(
                                        message: colorName,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            color: Color(int.parse(colorString.replaceAll('#', '0xFF'))),
                                            border: Border.all(
                                              color: isSelected ? Colors.black : Colors.grey.shade400,
                                              width: isSelected ? 3 : 1,
                                            ),
                                            borderRadius: BorderRadius.circular(8),
                                            boxShadow: isSelected ? [
                                              BoxShadow(
                                                color: Colors.black.withValues(alpha: 0.3),
                                                blurRadius: 4,
                                                offset: const Offset(0, 2),
                                              ),
                                            ] : null,
                                          ),
                                          child: isSelected
                                              ? const Icon(Icons.check, color: Colors.white, size: 20)
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Custom hex input
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _colorController,
                          decoration: const InputDecoration(
                            labelText: 'Custom Hex Color',
                            hintText: '#RRGGBB',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.color_lens),
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'^#[0-9A-Fa-f]{6}$')),
                          ],
                          onChanged: (value) {
                            if (value.length == 7 && value.startsWith('#')) {
                              setDialogState(() {
                                _selectedColor = value;
                              });
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      ElevatedButton(
                        onPressed: () {
                          // Generate random color
                          final random = List.generate(6, (_) => 
                            '0123456789ABCDEF'[DateTime.now().millisecondsSinceEpoch % 16]
                          ).join();
                          final randomColor = '#$random';
                          setDialogState(() {
                            _selectedColor = randomColor;
                            _colorController.text = randomColor;
                          });
                        },
                        child: const Icon(Icons.shuffle),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _selectedColor = _colorController.text;
                    _addToRecentColors(_selectedColor);
                  });
                  Navigator.pop(context);
                },
                child: const Text('Select'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: source,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        if (kIsWeb) {
          // On web, handle file differently
          try {
            
            setState(() {
              _selectedImageFile = null; // Clear any existing file
              _selectedImageUrl = null; // Clear URL
              _webImageFile = pickedFile; // Store the XFile for web
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image selected: ${pickedFile.name}'),
                backgroundColor: Colors.green,
              ),
            );
            
          } catch (e) {
            throw Exception('Failed to process web image: $e');
          }
        } else {
          // Mobile environment - use File object
          try {
            
            final file = File(pickedFile.path);
            
            // Check if file exists and is readable
            if (!await file.exists()) {
              throw Exception('Selected file does not exist');
            }
            
            // Check file size (max 5MB)
            final fileSize = await file.length();
            
            if (fileSize > 5 * 1024 * 1024) {
              throw Exception('File size exceeds 5MB limit');
            }
            
            // Validate file extension
            final fileName = pickedFile.name.toLowerCase();
            final validExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp', '.svg'];
            final hasValidExtension = validExtensions.any((ext) => fileName.endsWith(ext));
            
            if (!hasValidExtension) {
              throw Exception('Invalid file format. Supported: JPG, PNG, GIF, WebP, SVG');
            }
            
            setState(() {
              _selectedImageFile = file;
              _selectedImageUrl = null; // Clear URL when file is selected
              _webImageFile = null; // Clear web image when file is selected
            });
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Image selected: ${pickedFile.name} (${(fileSize / 1024).toStringAsFixed(1)} KB)'),
                backgroundColor: Colors.green,
              ),
            );
            
          } catch (e) {
            throw Exception('Failed to process mobile image: $e');
          }
        }
      } else {
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Image Source'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _uploadImage() async {
    if (_selectedImageFile == null) {
      _showImageSourceDialog();
      return;
    }

    setState(() {
      _isUploadingImage = true;
    });

    try {
      // The image will be uploaded when the form is submitted
      // For now, we'll just prepare it for upload
      setState(() {
        // Keep the file for upload during form submission
        // Don't clear _selectedImageFile here
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image selected! Save the category to upload the image.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to prepare image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingImage = false;
      });
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImageFile = null;
      _selectedImageUrl = null;
      _webImageFile = null;
    });
  }

  void _handleImageDrop(Object data) {
    // Handle dropped image data
    if (data is String && data.startsWith('file://')) {
      // Handle file path
      setState(() {
        if (kIsWeb) {
          // On web, we might get a different format
          _selectedImageFile = File(data);
        } else {
          _selectedImageFile = File(data.replaceFirst('file://', ''));
        }
        _selectedImageUrl = null;
        _webImageFile = null; // Clear web image when file is selected
      });
    } else if (data is List<int>) {
      // Handle image bytes
      // You could save this to a temporary file
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image data received! Processing...'),
          backgroundColor: Colors.blue,
        ),
      );
    }
  }

  void _submitForm() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        if (widget.categoryId != null) {
          // Update existing category
          final updateData = {
            'name': _nameController.text.trim(),
            'subcategories': _subcategoriesController.text.trim().isNotEmpty 
                ? _subcategoriesController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                : [],
            'backgroundColor': _selectedColor, // Include background color for update
            // Don't include logo in updateData if we have a new file to upload
            if (_selectedImageFile == null && _selectedImageUrl != null) 'logo': _selectedImageUrl,
          };

          // Pass the logo file if available (File or XFile on web)
          final dynamic fileToSend = kIsWeb ? (_webImageFile ?? _selectedImageFile) : _selectedImageFile;
          final response = await _categoryService.updateCategory(
            widget.categoryId!,
            updateData,
            logoFile: fileToSend,
          );
          
          if (response.status == 200) {
            Navigator.of(context).pop(response.category);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update category: ${response.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // Create new category - explicitly exclude backgroundColor from backend data
          final newCategory = Category(
            name: _nameController.text.trim(),
            subcategories: _subcategoriesController.text.trim().isNotEmpty 
                ? _subcategoriesController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                : [],
            backgroundColor: _selectedColor, // Frontend-only field for UI display
            logo: _selectedImageFile != null ? null : _selectedImageUrl, // Don't send URL if we have a file
          );

          // Create category first (without logo)
          final response = await _categoryService.createCategory(newCategory);
          
          if (response.status == 201) {
            // Category created successfully, now upload logo if available
            if ((_selectedImageFile != null || _webImageFile != null) && response.category != null) {
              try {
                setState(() {
                  _isLoading = true;
                });
                
                // Determine which file to use for upload
                final fileToUpload = kIsWeb ? _webImageFile! : _selectedImageFile!;
                if (fileToUpload is XFile) {
                } else if (fileToUpload is File) {
                }
                
                final logoResponse = await _categoryService.uploadCategoryLogo(
                  response.category!.id!,
                  fileToUpload,
                );
                
                if (logoResponse.status == 200) {
                  // Logo uploaded successfully
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category created and logo uploaded successfully!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  // Category created but logo upload failed
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Category created but logo upload failed: ${logoResponse.message}'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                }
              } catch (e) {
                // Category created but logo upload failed
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Category created but logo upload failed: $e'),
                    backgroundColor: Colors.orange,
                  ),
                );
              } finally {
                setState(() {
                  _isLoading = false;
                });
              }
            }
            
            Navigator.of(context).pop(response.category);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create category: ${response.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  Widget _buildImagePreview() {
    if (_selectedImageFile != null || _webImageFile != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Background color layer (behind the image)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Base image - make it fill the container (supports SVG)
              Container(
                width: double.infinity,
                height: double.infinity,
                                        child: _webImageFile != null
                            ? FutureBuilder<Uint8List>(
                                future: _webImageFile!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: const Center(
                                        child: CircularProgressIndicator(),
                                      ),
                                    );
                                  }
                                  if (snapshot.hasError || !snapshot.hasData) {
                                    return Container(
                                      color: Colors.grey.shade200,
                                      child: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          const Icon(Icons.error, size: 24, color: Colors.grey),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Web Image\nError',
                                            style: TextStyle(
                                              fontSize: 8,
                                              color: Colors.grey.shade600,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                  final bytes = snapshot.data!;
                                  // Try detect SVG by starting bytes content
                                  final String head = String.fromCharCodes(bytes.take(64).toList()).toLowerCase();
                                  final bool isSvg = head.contains('<svg');
                                  if (isSvg) {
                                    return SvgPicture.memory(
                                      bytes,
                                      width: double.infinity,
                                      height: double.infinity,
                                      fit: BoxFit.contain,
                                    );
                                  }
                                  return ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.memory(
                                      bytes,
                                      fit: BoxFit.cover,
                                      width: double.infinity,
                                      height: double.infinity,
                                    ),
                                  );
                                },
                              )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Builder(
                          builder: (context) {
                            if (_selectedImageFile != null && _selectedImageFile!.path.toLowerCase().endsWith('.svg')) {
                              return FutureBuilder<Uint8List>(
                                future: _selectedImageFile!.readAsBytes(),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState == ConnectionState.waiting) {
                                    return const Center(child: CircularProgressIndicator());
                                  }
                                  if (!snapshot.hasData) {
                                    return const SizedBox.shrink();
                                  }
                                  return SvgPicture.memory(
                                    snapshot.data!,
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.contain,
                                  );
                                },
                              );
                            }
                            return Image.file(
                              _selectedImageFile!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(Icons.error, size: 24, color: Colors.grey),
                                      const SizedBox(height: 4),
                                      Text(
                                        'File Image\nError',
                                        style: TextStyle(
                                          fontSize: 8,
                                          color: Colors.grey.shade600,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
              ),
              // Color indicator badge with better positioning
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedColor,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
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
      );
    } else if (_selectedImageUrl != null) {
      return Container(
        width: 120,
        height: 120,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300, width: 2),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // Background color layer (behind the image)
              Container(
                width: double.infinity,
                height: double.infinity,
                decoration: BoxDecoration(
                  color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              // Base image - make it fill the container (supports SVG)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Builder(
                  builder: (context) {
                    final String baseUrl = _selectedImageUrl!;
                    final String url = (widget.categoryId != null)
                        ? (baseUrl.contains('?')
                            ? '$baseUrl&v=${DateTime.now().millisecondsSinceEpoch}'
                            : '$baseUrl?v=${DateTime.now().millisecondsSinceEpoch}')
                        : baseUrl;
                    final bool isSvg = url.toLowerCase().endsWith('.svg');
                    if (isSvg) {
                      return SvgPicture.network(
                        url,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      );
                    }
                    return Image.network(
                      url,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error, size: 24, color: Colors.grey),
                              const SizedBox(height: 4),
                              Text(
                                'Network\nError',
                                style: TextStyle(
                                  fontSize: 8,
                                  color: Colors.grey.shade600,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              // Color indicator badge with better positioning
              Positioned(
                bottom: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                          borderRadius: BorderRadius.circular(3),
                          border: Border.all(color: Colors.grey.shade400),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _selectedColor,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade800,
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
      );
    }
    
    // No image selected
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image,
            size: 32,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 4),
          Text(
            'No Image\nSelected',
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCombinedPreview() {
    if (_selectedImageFile != null || _selectedImageUrl != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.preview, size: 16, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                Text(
                  'Final Preview - How Your Category Will Look',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                // Combined image with color overlay
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Stack(
                      children: [
                        // Background color layer (behind the image)
                        Container(
                          width: double.infinity,
                          height: double.infinity,
                          decoration: BoxDecoration(
                            color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        // Base image (supports SVG)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: _webImageFile != null
                              ? FutureBuilder<Uint8List>(
                                  future: _webImageFile!.readAsBytes(),
                                  builder: (context, snapshot) {
                                    if (snapshot.connectionState == ConnectionState.waiting) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: CircularProgressIndicator(),
                                        ),
                                      );
                                    }
                                    if (snapshot.hasError || !snapshot.hasData) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Icon(Icons.error, size: 40, color: Colors.grey),
                                      );
                                    }
                                    final bytes = snapshot.data!;
                                    final head = String.fromCharCodes(bytes.take(64).toList()).toLowerCase();
                                    final bool isSvg = head.contains('<svg');
                                    if (isSvg) {
                                      return SvgPicture.memory(
                                        bytes,
                                        fit: BoxFit.contain,
                                        width: double.infinity,
                                        height: double.infinity,
                                      );
                                    }
                                    return Image.memory(bytes, fit: BoxFit.cover, width: double.infinity, height: double.infinity);
                                  },
                                )
                              : _selectedImageFile != null
                                  ? Builder(
                                      builder: (context) {
                                        if (_selectedImageFile!.path.toLowerCase().endsWith('.svg')) {
                                          return FutureBuilder<Uint8List>(
                                            future: _selectedImageFile!.readAsBytes(),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState == ConnectionState.waiting) {
                                                return const Center(child: CircularProgressIndicator());
                                              }
                                              if (!snapshot.hasData) {
                                                return const SizedBox.shrink();
                                              }
                                              return SvgPicture.memory(
                                                snapshot.data!,
                                                fit: BoxFit.contain,
                                                width: double.infinity,
                                                height: double.infinity,
                                              );
                                            },
                                          );
                                        }
                                        return Image.file(
                                          _selectedImageFile!,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        );
                                      },
                                    )
                                  : Builder(
                                      builder: (context) {
                                        final String url = _selectedImageUrl!;
                                        if (url.toLowerCase().endsWith('.svg')) {
                                          return SvgPicture.network(
                                            url,
                                            fit: BoxFit.contain,
                                            width: double.infinity,
                                            height: double.infinity,
                                          );
                                        }
                                        return Image.network(
                                          url,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                        );
                                      },
                                    ),
                        ),
                        // Category icon overlay
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Icon(
                              Icons.category,
                              size: 24,
                              color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Color info and description
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Selected Color:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade400, width: 2),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _selectedColor,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey.shade800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'The selected background color is automatically applied behind your uploaded image. This creates a unique visual identity for your category with the image displayed on top of the colored background.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade700,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDragTarget() {
    return DragTarget<Object>(
      onWillAccept: (data) {
        setState(() {
          _isDragOver = true;
        });
        return true;
      },
      onAccept: (data) {
        setState(() {
          _isDragOver = false;
        });
        _handleImageDrop(data);
      },
      onLeave: (data) {
        setState(() {
          _isDragOver = false;
        });
      },
      builder: (context, candidateData, rejectedData) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            border: Border.all(
              color: _isDragOver 
                  ? const Color(0xFF1708FF) 
                  : Colors.grey.shade300,
              style: BorderStyle.solid,
              width: _isDragOver ? 3 : 2,
            ),
            borderRadius: BorderRadius.circular(12),
            color: _isDragOver 
                ? const Color(0xFF1708FF).withValues(alpha: 0.05)
                : Colors.transparent,
          ),
          child: Column(
            children: [
              if (_selectedImageFile != null || _webImageFile != null || _selectedImageUrl != null) ...[
                // Display the uploaded image in a compact size
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                                      child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          // Background color layer (behind the image)
                          Container(
                            width: double.infinity,
                            height: double.infinity,
                            decoration: BoxDecoration(
                              color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        // The actual image
                        if (_webImageFile != null)
                          FutureBuilder<Uint8List>(
                            future: _webImageFile!.readAsBytes(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }
                              if (snapshot.hasError || !snapshot.hasData) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.error, size: 48, color: Colors.grey),
                                  ),
                                );
                              }
                              return ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  snapshot.data!,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              );
                            },
                          )
                        else if (_selectedImageFile != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: kIsWeb
                                ? FutureBuilder<Uint8List>(
                                    future: _selectedImageFile!.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState == ConnectionState.waiting) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: CircularProgressIndicator(),
                                          ),
                                        );
                                      }
                                      if (snapshot.hasError || !snapshot.hasData) {
                                        return Container(
                                          color: Colors.grey.shade200,
                                          child: const Center(
                                            child: Icon(Icons.error, size: 48, color: Colors.grey),
                                          ),
                                        );
                                      }
                                      return Image.memory(
                                        snapshot.data!,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                      );
                                    },
                                  )
                                : Image.file(
                                    _selectedImageFile!,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        color: Colors.grey.shade200,
                                        child: const Center(
                                          child: Icon(Icons.error, size: 48, color: Colors.grey),
                                        ),
                                      );
                                    },
                                  ),
                          )
                        else if (_selectedImageUrl != null)
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              _selectedImageUrl!,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: const Center(
                                    child: Icon(Icons.error, size: 48, color: Colors.grey),
                                  ),
                                );
                              },
                            ),
                          ),
                        // Color indicator badge
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: Colors.grey.shade300),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 2,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 12,
                                  height: 12,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                                    borderRadius: BorderRadius.circular(3),
                                    border: Border.all(color: Colors.grey.shade400),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _selectedColor,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade800,
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
                ),
                const SizedBox(height: 16),
                // Action buttons for the uploaded image - just icons
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: _showImageSourceDialog,
                      icon: const Icon(Icons.edit, size: 20),
                      tooltip: 'Change Image',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.orange.withValues(alpha: 0.1),
                        foregroundColor: Colors.orange,
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _removeImage,
                      icon: const Icon(Icons.delete, size: 20),
                      tooltip: 'Remove Image',
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.red.withValues(alpha: 0.1),
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.all(12),
                        minimumSize: const Size(44, 44),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Row(
                //   mainAxisAlignment: MainAxisAlignment.center,
                //   children: [
                //     Icon(
                //       Icons.check_circle,
                //       color: Colors.green.shade600,
                //       size: 20,
                //     ),
                //     const SizedBox(width: 8),
                //     Text(
                //       'Image uploaded successfully!',
                //       style: TextStyle(
                //         fontSize: 14,
                //         fontWeight: FontWeight.w600,
                //         color: Colors.green.shade700,
                //       ),
                //     ),
                //   ],
                // ),
              ] else ...[
                // Show placeholder when no image is selected
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300, width: 2),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Icon(
                          _isDragOver ? Icons.cloud_download : Icons.cloud_outlined,
                          size: 48,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      // Color preview overlay
                      Positioned(
                        bottom: 8,
                        right: 8,
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  _isDragOver ? 'Drop image here!' : 'Drop your images here',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _isDragOver ? const Color(0xFF1708FF) : Colors.grey,
                  ),
                ),
                Text(
                  'or click the button below',
                  style: TextStyle(
                    fontSize: 14,
                    color: _isDragOver ? const Color(0xFF1708FF) : Colors.grey,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              ElevatedButton.icon(
                onPressed: _isUploadingImage ? null : _showImageSourceDialog,
                icon: _isUploadingImage 
                    ? const SizedBox(
                        height: 16,
                        width: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.upload),
                label: Text(_isUploadingImage ? 'Uploading...' : 'Select Image'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1708FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withValues(alpha: 0.3),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        width: MediaQuery.of(context).size.width * 0.9,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      widget.categoryId != null ? 'Edit Category' : 'Add new category',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1C4B),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Category Name Input
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Category name',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                      borderSide: BorderSide(color: Color(0xFF1708FF), width: 2),
                    ),
                    prefixIcon: Icon(Icons.category),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Category name is required';
                    }
                    if (value.trim().length < 2) {
                      return 'Category name must be at least 2 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Color Selection for UI Display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      
                      Row(
                        children: [
                          GestureDetector(
                            onTap: _selectColor,
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Color(int.parse(_selectedColor.replaceAll('#', '0xFF'))),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: Colors.grey.shade300, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 8,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.color_lens,
                                color: Colors.white,
                                size: 28,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                
                                const SizedBox(height: 4),
                                Text(
                                  _selectedColor,
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey.shade800,
                                    fontFamily: 'monospace',
                                  ),
                                ),
                                
                              ],
                            ),
                          ),
                          // const SizedBox(width: 8),
                          // Flexible(
                          //   child: ElevatedButton.icon(
                          //     onPressed: _selectColor,
                          //     icon: const Icon(Icons.palette),
                          //     label: const Text('Change Color'),
                          //     style: ElevatedButton.styleFrom(
                          //       backgroundColor: const Color(0xFF1708FF),
                          //       foregroundColor: Colors.white,
                          //       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          //       shape: RoundedRectangleBorder(
                          //         borderRadius: BorderRadius.circular(8),
                          //       ),
                          //     ),
                          //   ),
                          // ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Quick color suggestions
                      Text(
                        'Quick Picks:',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            '#1708FF', '#FF1708', '#08FF17', '#FF8000', '#8000FF', '#00FFFF'
                          ].map((color) {
                            final isSelected = _selectedColor == color;
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: GestureDetector(
                                onTap: () {
                                  setState(() {
                                    _selectedColor = color;
                                    _colorController.text = color;
                                    _addToRecentColors(color);
                                  });
                                },
                                child: Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(color.replaceAll('#', '0xFF'))),
                                    border: Border.all(
                                      color: isSelected ? Colors.black : Colors.grey.shade400,
                                      width: isSelected ? 3 : 1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                    boxShadow: isSelected ? [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ] : null,
                                  ),
                                  child: isSelected
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Image Upload Area with Drag & Drop
                _buildDragTarget(),
                const SizedBox(height: 16),
                

                
                // Combined Preview
                _buildCombinedPreview(),
                const SizedBox(height: 24),

                // Subcategories Input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.category, color: Colors.grey.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'Subcategories',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.grey.shade800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _subcategoriesController,
                        decoration: const InputDecoration(
                          labelText: 'Subcategories (comma-separated)',
                          hintText: 'e.g., Electronics, Gadgets, Accessories',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.all(Radius.circular(8)),
                            borderSide: BorderSide(color: Color(0xFF1708FF), width: 2),
                          ),
                          prefixIcon: Icon(Icons.subdirectory_arrow_right),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        maxLines: 3,
                        validator: (value) {
                          // Subcategories are optional
                          return null;
                        },
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter subcategories separated by commas. These will help organize and filter companies within this category.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: Color(0xFF1708FF)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            color: Color(0xFF1708FF),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF1708FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
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
      ),
    );
  }
}
