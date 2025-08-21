import 'dart:convert';

class Commission {
  final double amount;
  final DateTime createdAt;
  final String orderId;
  final String status; // pending, paid

  Commission({
    required this.amount,
    required this.createdAt,
    required this.orderId,
    required this.status,
  });

  factory Commission.fromJson(Map<String, dynamic> json) {
    return Commission(
      amount: (json['amount'] ?? 0).toDouble(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      orderId: json['orderId'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'amount': amount,
      'createdAt': createdAt.toIso8601String(),
      'orderId': orderId,
      'status': status,
    };
  }
}

class Salesperson {
  final String? id;
  final String fullName;
  final String email;
  final String phoneNumber;
  final String password;
  final String? image;
  final String? status; // active, inactive
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? companyId;
  final List<Commission>? commissions;
  final double commissionPercent;
  final String? region;
  final String? salesManagerId;
  final double? latitude;
  final double? longitude;
  final double? radius;

  Salesperson({
    this.id,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
    required this.password,
    this.image,
    this.status,
    this.createdAt,
    this.updatedAt,
    this.createdBy,
    this.companyId,
    this.commissions,
    this.commissionPercent = 0.0,
    this.region,
    this.salesManagerId,
    this.latitude,
    this.longitude,
    this.radius,
  });

  factory Salesperson.fromJson(Map<String, dynamic> json) {
    return Salesperson(
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      phoneNumber: json['phoneNumber'] ?? '',
      password: json['password'] ?? '', // Don't expect password in responses
      image: json['Image'] ?? json['image'], // Handle both cases
      status: json['status'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      createdBy: json['createdBy'],
      companyId: json['companyId'],
      commissions: json['commissions'] != null
          ? (json['commissions'] as List).map((i) => Commission.fromJson(i)).toList()
          : null,
      commissionPercent: (json['commissionPercent'] is int)
          ? (json['commissionPercent'] as int).toDouble()
          : (json['commissionPercent'] ?? 0.0),
      region: json['region'],
      salesManagerId: json['salesManagerId'],
      latitude: json['latitude'] != null ? (json['latitude'] as double) : null,
      longitude: json['longitude'] != null ? (json['longitude'] as double) : null,
      radius: json['radius'] != null ? (json['radius'] as double) : null,
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};

    // Always include these fields for updates
    data['fullName'] = fullName;
    data['email'] = email;
    data['phoneNumber'] = phoneNumber;

    // Only include password if it's not empty
    if (password.isNotEmpty) {
      data['password'] = password;
    }

    // Optional fields - only include if not null/empty
    if (id != null && id!.isNotEmpty) data['id'] = id;
    if (image != null && image!.isNotEmpty) data['Image'] = image;
    if (status != null && status!.isNotEmpty) data['status'] = status;
    if (createdAt != null) data['createdAt'] = createdAt!.toIso8601String();
    if (updatedAt != null) data['updatedAt'] = updatedAt!.toIso8601String();
    if (createdBy != null && createdBy!.isNotEmpty) data['createdBy'] = createdBy;
    if (companyId != null && companyId!.isNotEmpty) data['companyId'] = companyId;
    if (commissions != null && commissions!.isNotEmpty) {
      data['commissions'] = commissions!.map((c) => c.toJson()).toList();
    }
    data['commissionPercent'] = commissionPercent;
    if (region != null && region!.isNotEmpty) data['region'] = region;
    if (salesManagerId != null && salesManagerId!.isNotEmpty) data['salesManagerId'] = salesManagerId;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (radius != null) data['radius'] = radius;
    return data;
  }

  // Create a JSON specifically for updates (excludes readonly fields)
  Map<String, dynamic> toUpdateJson() {
    final Map<String, dynamic> data = {};

    // Always include these fields for updates
    data['fullName'] = fullName;
    data['email'] = email;
    data['phoneNumber'] = phoneNumber;

    // Only include password if it's not empty (for updates)
    if (password.isNotEmpty) {
      data['password'] = password;
    }

    // Optional fields that can be updated
    if (image != null && image!.isNotEmpty) data['Image'] = image;
    if (status != null && status!.isNotEmpty) data['status'] = status;
    data['commissionPercent'] = commissionPercent;
    if (region != null && region!.isNotEmpty) data['region'] = region;
    if (salesManagerId != null && salesManagerId!.isNotEmpty) data['salesManagerId'] = salesManagerId;
    if (latitude != null) data['latitude'] = latitude;
    if (longitude != null) data['longitude'] = longitude;
    if (radius != null) data['radius'] = radius;
    return data;
  }

  // Create a copy of this Salesperson with the given field values updated
  Salesperson copyWith({
    String? id,
    String? fullName,
    String? email,
    String? phoneNumber,
    String? password,
    String? image,
    String? territory,
    String? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
    String? companyId,
    List<Commission>? commissions,
    double? commissionPercent,
    String? region,
    String? salesManagerId,
    double? latitude,
    double? longitude,
    double? radius,
  }) {
    return Salesperson(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      password: password ?? this.password,
      image: image ?? this.image,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      companyId: companyId ?? this.companyId,
      commissions: commissions ?? this.commissions,
      commissionPercent: commissionPercent ?? this.commissionPercent,
      region: region ?? this.region,
      salesManagerId: salesManagerId ?? this.salesManagerId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      radius: radius ?? this.radius,
    );
  }
}