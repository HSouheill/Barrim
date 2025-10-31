import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/wholesaler_category.dart';
import '../services/wholesaler_category_service.dart';

class AddWholesalerCategoryPopup extends StatefulWidget {
  final String? categoryId; // For editing existing category
  final String? initialName;
  final List<String>? initialSubcategories;

  const AddWholesalerCategoryPopup({
    Key? key,
    this.categoryId,
    this.initialName,
    this.initialSubcategories,
  }) : super(key: key);

  @override
  _AddWholesalerCategoryPopupState createState() => _AddWholesalerCategoryPopupState();
}

class _AddWholesalerCategoryPopupState extends State<AddWholesalerCategoryPopup> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _subcategoriesController = TextEditingController();
  final WholesalerCategoryService _categoryService = WholesalerCategoryService();
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.initialName ?? '';
    _subcategoriesController.text = widget.initialSubcategories?.join(', ') ?? '';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _subcategoriesController.dispose();
    super.dispose();
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
          };

          final response = await _categoryService.updateWholesalerCategory(
            widget.categoryId!,
            updateData,
          );
          
          if (response.status == 200) {
            Navigator.of(context).pop(response.category);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to update wholesaler category: ${response.message}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        } else {
          // Create new category
          final newCategory = WholesalerCategory(
            name: _nameController.text.trim(),
            subcategories: _subcategoriesController.text.trim().isNotEmpty 
                ? _subcategoriesController.text.trim().split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList()
                : [],
          );

          final response = await _categoryService.createWholesalerCategory(newCategory);
          
          if (response.status == 201) {
            Navigator.of(context).pop(response.category);
          } else {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Failed to create wholesaler category: ${response.message}'),
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.95,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
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
                      widget.categoryId != null ? 'Edit Wholesaler Category' : 'Add New Wholesaler Category',
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
                    labelText: 'Category Name',
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
                        'Enter subcategories separated by commas. These will help organize and filter wholesalers within this category.',
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
