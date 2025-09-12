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
  final String? targetUserId;
  final String? targetUserType;
  final bool? isGlobal;

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
    this.targetUserId,
    this.targetUserType,
    this.isGlobal,
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
      targetUserId: json['targetUserId'],
      targetUserType: json['targetUserType'],
      isGlobal: json['isGlobal'],
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
      'targetUserId': targetUserId,
      'targetUserType': targetUserType,
      'isGlobal': isGlobal,
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
    String? targetUserId,
    String? targetUserType,
    bool? isGlobal,
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
      targetUserId: targetUserId ?? this.targetUserId,
      targetUserType: targetUserType ?? this.targetUserType,
      isGlobal: isGlobal ?? this.isGlobal,
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

class UserTypeVoucherRequest {
  final String name;
  final String description;
  final int points;
  final String imageUrl;
  final String targetUserType;

  UserTypeVoucherRequest({
    required this.name,
    required this.description,
    required this.points,
    required this.imageUrl,
    required this.targetUserType,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'points': points,
      'image': imageUrl,
      'targetUserType': targetUserType,
    };
  }

  factory UserTypeVoucherRequest.fromJson(Map<String, dynamic> json) {
    return UserTypeVoucherRequest(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      points: json['points'] ?? 0,
      imageUrl: json['image'] ?? '',
      targetUserType: json['targetUserType'] ?? '',
    );
  }
}
