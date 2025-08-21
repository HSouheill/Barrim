class WholesalerCategory {
  final String? id;
  final String name;
  final List<String> subcategories;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WholesalerCategory({
    this.id,
    required this.name,
    this.subcategories = const [],
    this.createdAt,
    this.updatedAt,
  });

  factory WholesalerCategory.fromJson(Map<String, dynamic> json) {
    return WholesalerCategory(
      id: json['_id'] ?? json['id'],
      name: json['name'] ?? '',
      subcategories: json['subcategories'] != null 
          ? List<String>.from(json['subcategories'])
          : [],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      'subcategories': subcategories,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  WholesalerCategory copyWith({
    String? id,
    String? name,
    List<String>? subcategories,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return WholesalerCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      subcategories: subcategories ?? this.subcategories,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class WholesalerCategoryResponse {
  final WholesalerCategory? category;
  final String message;
  final int status;

  WholesalerCategoryResponse({
    this.category,
    required this.message,
    required this.status,
  });

  factory WholesalerCategoryResponse.fromJson(Map<String, dynamic> json) {
    return WholesalerCategoryResponse(
      category: json['data'] != null 
          ? WholesalerCategory.fromJson(json['data'])
          : null,
      message: json['message'] ?? '',
      status: json['status'] ?? 0,
    );
  }
}

class WholesalerCategoryListResponse {
  final List<WholesalerCategory> categories;
  final String message;
  final int status;

  WholesalerCategoryListResponse({
    required this.categories,
    required this.message,
    required this.status,
  });

  factory WholesalerCategoryListResponse.fromJson(Map<String, dynamic> json) {
    List<WholesalerCategory> categories = [];
    if (json['data'] != null) {
      if (json['data'] is List) {
        categories = (json['data'] as List)
            .map((item) => WholesalerCategory.fromJson(item))
            .toList();
      }
    }

    return WholesalerCategoryListResponse(
      categories: categories,
      message: json['message'] ?? '',
      status: json['status'] ?? 0,
    );
  }
}
