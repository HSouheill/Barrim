import 'dart:convert';

class ServiceProviderCategory {
  final String? id;
  final String name;
  final String? logo;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ServiceProviderCategory({
    this.id,
    required this.name,
    this.logo,
    this.createdAt,
    this.updatedAt,
  });

  factory ServiceProviderCategory.fromJson(Map<String, dynamic> json) {
    // Convert relative logo URL to absolute URL if it exists
    String? logoUrl = json['logo'];
    if (logoUrl != null && logoUrl.startsWith('/')) {
      // Prepend the base URL to make it absolute
      logoUrl = 'https://barrim.online$logoUrl';
      print('Converted logo URL: $logoUrl'); // Debug print
    }
    
    return ServiceProviderCategory(
      id: json['id'] ?? json['_id']?.toString(),
      name: json['name'] ?? '',
      logo: logoUrl,
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
      if (logo != null) 'logo': logo,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  // Create a copy of this category with updated fields
  ServiceProviderCategory copyWith({
    String? id,
    String? name,
    String? logo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ServiceProviderCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      logo: logo ?? this.logo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'ServiceProviderCategory(id: $id, name: $name, logo: $logo)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ServiceProviderCategory &&
        other.id == id &&
        other.name == name;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode;
  }
}

class ServiceProviderCategoryListResponse {
  final List<ServiceProviderCategory> categories;
  final String message;
  final int status;

  ServiceProviderCategoryListResponse({
    required this.categories,
    required this.message,
    required this.status,
  });

  factory ServiceProviderCategoryListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as List?;
    return ServiceProviderCategoryListResponse(
      categories: data?.map((item) => ServiceProviderCategory.fromJson(item)).toList() ?? [],
      message: json['message'] ?? '',
      status: json['status'] ?? 200,
    );
  }
}

class ServiceProviderCategoryResponse {
  final ServiceProviderCategory? category;
  final String message;
  final int status;

  ServiceProviderCategoryResponse({
    this.category,
    required this.message,
    required this.status,
  });

  factory ServiceProviderCategoryResponse.fromJson(Map<String, dynamic> json) {
    return ServiceProviderCategoryResponse(
      category: json['data'] != null ? ServiceProviderCategory.fromJson(json['data']) : null,
      message: json['message'] ?? '',
      status: json['status'] ?? 200,
    );
  }
}
