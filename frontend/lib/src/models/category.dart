

class Category {
  final String? id;
  final String name;
  final String? description;
  final List<String> subcategories;
  final String? logo;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  // Frontend-only field for UI display
  final String backgroundColor;

  Category({
    this.id,
    required this.name,
    this.description,
    this.subcategories = const [],
    this.logo,
    this.createdAt,
    this.updatedAt,
    this.backgroundColor = '#1708FF', // Default blue for frontend
  });

  factory Category.fromJson(Map<String, dynamic> json) {
    // Convert relative logo URL to absolute URL if it exists
    String? logoUrl = json['logo'];
    print('=== Category.fromJson Debug ===');
    print('Raw logo from JSON: ${json['logo']}');
    print('Logo URL before processing: $logoUrl');
    
    if (logoUrl != null && logoUrl.startsWith('/')) {
      // Prepend the base URL to make it absolute
      logoUrl = 'https://barrim.online$logoUrl';
      print('Converted relative URL to: $logoUrl');
    } else {
      print('Logo URL is already absolute or null: $logoUrl');
    }
    print('Final logo URL: $logoUrl');
    print('=== End Category.fromJson Debug ===');
    
    // Handle subcategories - could be a list or comma-separated string
    List<String> subcategoriesList = [];
    if (json['subcategories'] != null) {
      if (json['subcategories'] is List) {
        subcategoriesList = List<String>.from(json['subcategories']);
      } else if (json['subcategories'] is String) {
        subcategoriesList = json['subcategories']
            .split(',')
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .toList();
      }
    }
    
    // Handle color field from backend (maps to backgroundColor for frontend)
    String backgroundColor = '#1708FF'; // Default
    if (json['color'] != null && json['color'].toString().isNotEmpty) {
      backgroundColor = json['color'].toString();
    } else if (json['backgroundColor'] != null && json['backgroundColor'].toString().isNotEmpty) {
      backgroundColor = json['backgroundColor'].toString();
    }
    
    // Note: If images don't load due to CORS, your backend needs to add CORS headers
    // for static file requests. See the documentation for proper CORS configuration.
    
    return Category(
      id: json['id'] ?? json['_id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      subcategories: subcategoriesList,
      logo: logoUrl,
      backgroundColor: backgroundColor,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (description != null) 'description': description,
      if (subcategories.isNotEmpty) 'subcategories': subcategories.join(', '),
      if (logo != null) 'logo': logo,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      // Note: backgroundColor is mapped to 'color' when sending to backend
    };
  }

  // Create a copy of this category with updated fields
  Category copyWith({
    String? id,
    String? name,
    String? description,
    List<String>? subcategories,
    String? logo,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? backgroundColor,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      subcategories: subcategories ?? this.subcategories,
      logo: logo ?? this.logo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      backgroundColor: backgroundColor ?? this.backgroundColor,
    );
  }

  @override
  String toString() {
    return 'Category(id: $id, name: $name, subcategories: $subcategories, backgroundColor: $backgroundColor, logo: $logo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Category &&
        other.id == id &&
        other.name == name &&
        other.subcategories == subcategories;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ subcategories.hashCode;
  }
}

class CategoryListResponse {
  final List<Category> categories;
  final String message;
  final int status;

  CategoryListResponse({
    required this.categories,
    required this.message,
    required this.status,
  });

  factory CategoryListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List?;
    return CategoryListResponse(
      categories: data?.map((item) => Category.fromJson(item)).toList() ?? [],
      message: json['message'] ?? '',
      status: json['status'] ?? 200,
    );
  }
}

class CategoryResponse {
  final Category? category;
  final String message;
  final int status;

  CategoryResponse({
    this.category,
    required this.message,
    required this.status,
  });

  factory CategoryResponse.fromJson(Map<String, dynamic> json) {
    return CategoryResponse(
      category: json['data'] != null ? Category.fromJson(json['data']) : null,
      message: json['message'] ?? '',
      status: json['status'] ?? 200,
    );
  }
}
