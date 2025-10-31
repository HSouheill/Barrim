import 'package:flutter/material.dart';
import '../models/service_provider_category.dart';
import '../services/public_service_provider_category_service.dart';

class ServiceProviderCategorySelector extends StatefulWidget {
  final String? selectedCategoryId;
  final String? selectedCategoryName;
  final Function(ServiceProviderCategory?) onCategoryChanged;
  final String label;
  final String? hint;
  final bool isRequired;
  final bool showLogo;
  final double? width;

  const ServiceProviderCategorySelector({
    Key? key,
    this.selectedCategoryId,
    this.selectedCategoryName,
    required this.onCategoryChanged,
    this.label = 'Category',
    this.hint,
    this.isRequired = false,
    this.showLogo = true,
    this.width,
  }) : super(key: key);

  @override
  State<ServiceProviderCategorySelector> createState() => _ServiceProviderCategorySelectorState();
}

class _ServiceProviderCategorySelectorState extends State<ServiceProviderCategorySelector> {
  final PublicServiceProviderCategoryService _categoryService = PublicServiceProviderCategoryService();
  
  List<ServiceProviderCategory> _categories = [];
  bool _isLoading = false;
  String? _errorMessage;
  ServiceProviderCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadCategories();
    _setInitialSelection();
  }

  void _setInitialSelection() {
    if (widget.selectedCategoryId != null) {
      try {
        _selectedCategory = _categories.firstWhere(
          (cat) => cat.id == widget.selectedCategoryId,
        );
      } catch (e) {
        if (widget.selectedCategoryName != null) {
          try {
            _selectedCategory = _categories.firstWhere(
              (cat) => cat.name == widget.selectedCategoryName,
            );
          } catch (e) {
            _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
          }
        } else {
          _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
        }
      }
    } else if (widget.selectedCategoryName != null) {
      try {
        _selectedCategory = _categories.firstWhere(
          (cat) => cat.name == widget.selectedCategoryName,
        );
      } catch (e) {
        _selectedCategory = _categories.isNotEmpty ? _categories.first : null;
      }
    }
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final categories = await _categoryService.getCategoriesForSelection();
      setState(() {
        _categories = categories;
        _isLoading = false;
      });
      _setInitialSelection();
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load categories: $e';
        _isLoading = false;
      });
    }
  }

  void _onCategoryChanged(ServiceProviderCategory? category) {
    setState(() {
      _selectedCategory = category;
    });
    widget.onCategoryChanged(category);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.width,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          if (widget.label.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Text(
                    widget.label,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (widget.isRequired)
                    const Text(
                      ' *',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                ],
              ),
            ),

          // Category Selector
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: _isLoading
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(
                      child: SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  )
                : _errorMessage != null
                    ? Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: _loadCategories,
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      )
                    : _categories.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Text(
                              'No categories available',
                              style: TextStyle(color: Colors.grey),
                            ),
                          )
                        : DropdownButtonFormField<ServiceProviderCategory>(
                            value: _selectedCategory,
                            decoration: InputDecoration(
                              hintText: widget.hint ?? 'Select a category',
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            items: _categories.map((category) {
                              return DropdownMenuItem<ServiceProviderCategory>(
                                value: category,
                                child: Row(
                                  children: [
                                    if (widget.showLogo && category.logo != null)
                                      Container(
                                        width: 24,
                                        height: 24,
                                        margin: const EdgeInsets.only(right: 12),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(4),
                                          child: Image.network(
                                            category.logo!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              return Container(
                                                width: 24,
                                                height: 24,
                                                decoration: BoxDecoration(
                                                  color: Colors.grey[200],
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                                child: const Icon(
                                                  Icons.category,
                                                  size: 16,
                                                  color: Colors.grey,
                                                ),
                                              );
                                            },
                                          ),
                                        ),
                                      ),
                                    Expanded(
                                      child: Text(
                                        category.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            onChanged: _onCategoryChanged,
                            validator: widget.isRequired
                                ? (value) {
                                    if (value == null) {
                                      return 'Please select a category';
                                    }
                                    return null;
                                  }
                                : null,
                          ),
          ),

          // Selected Category Display
          if (_selectedCategory != null && widget.showLogo)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border.all(color: Colors.grey[200]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    if (_selectedCategory!.logo != null)
                      Container(
                        width: 40,
                        height: 40,
                        margin: const EdgeInsets.only(right: 12),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: Image.network(
                            _selectedCategory!.logo!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.grey[200],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Icon(
                                  Icons.category,
                                  size: 24,
                                  color: Colors.grey,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Selected: ${_selectedCategory!.name}',
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (_selectedCategory!.createdAt != null)
                            Text(
                              'Created: ${_selectedCategory!.createdAt!.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
