// lib/src/models/voucher_model.dart
class Voucher {
  final String id;
  final String name;
  final String description;
  final String? image;
  final int points;
  final bool isActive;
  final String createdBy;
  final DateTime createdAt;
  final DateTime updatedAt;

  Voucher({
    required this.id,
    required this.name,
    required this.description,
    this.image,
    required this.points,
    required this.isActive,
    required this.createdBy,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Voucher.fromJson(Map<String, dynamic> json) {
    return Voucher(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      image: json['image'],
      points: json['points'] ?? 0,
      isActive: json['isActive'] ?? true,
      createdBy: json['createdBy'] ?? '',
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'points': points,
      'isActive': isActive,
      'createdBy': createdBy,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Voucher copyWith({
    String? id,
    String? name,
    String? description,
    String? image,
    int? points,
    bool? isActive,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Voucher(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      image: image ?? this.image,
      points: points ?? this.points,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class VoucherRequest {
  final String name;
  final String description;
  final int points;

  VoucherRequest({
    required this.name,
    required this.description,
    required this.points,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'points': points,
    };
  }

  factory VoucherRequest.fromJson(Map<String, dynamic> json) {
    return VoucherRequest(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
    );
  }
}

class VoucherResponse {
  final int count;
  final List<Voucher> vouchers;

  VoucherResponse({
    required this.count,
    required this.vouchers,
  });

  factory VoucherResponse.fromJson(Map<String, dynamic> json) {
    return VoucherResponse(
      count: json['count'] ?? 0,
      vouchers: json['vouchers'] != null
          ? (json['vouchers'] as List)
              .map((v) => Voucher.fromJson(v))
              .toList()
          : [],
    );
  }
}
