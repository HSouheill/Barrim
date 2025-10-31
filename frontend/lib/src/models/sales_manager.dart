// Updated SalesManager model - add territory field to match Go model
import 'package:intl/intl.dart';

class SalesManager {
  final String id;
  final String fullName;
  final String email;
  String? password;
  final String phoneNumber;
  String? image;
  final String status; // active, inactive
  final String createdBy; // Admin ID
  final List<String> salespersons;
  // final List<String> rolesAccess;
  final DateTime createdAt;
  final DateTime updatedAt;
  final double commissionPercent;

  SalesManager({
    required this.id,
    required this.fullName,
    required this.email,
    this.password,
    required this.phoneNumber,
    this.image,
    required this.status,
    required this.createdBy,
    required this.salespersons,
    // required this.rolesAccess,
    required this.createdAt,
    required this.updatedAt,
    required this.commissionPercent,
  });

  factory SalesManager.fromJson(Map<String, dynamic> json) {
    return SalesManager(
      id: json['id'] ?? '',
      fullName: json['fullName'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      phoneNumber: json['phoneNumber'] ?? '',
      image: json['image'],
      status: json['status'] ?? 'inactive',
      createdBy: json['createdBy'] ?? '',
      salespersons: json['salespersons'] != null
          ? List<String>.from(json['salespersons'])
          : [],
        // rolesAccess: json['rolesAccess'] != null
        //     ? List<String>.from(json['rolesAccess'])
        //     : [],
      createdAt: json['createdAt'] != null
          ? json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : json['createdAt']
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? json['updatedAt'] is String
          ? DateTime.parse(json['updatedAt'])
          : json['updatedAt']
          : DateTime.now(),
      commissionPercent: (json['commissionPercent'] is int)
          ? (json['commissionPercent'] as int).toDouble()
          : (json['commissionPercent'] ?? 0.0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'fullName': fullName,
      'email': email,
      if (password != null) 'password': password,
      'phoneNumber': phoneNumber,
      if (image != null) 'image': image,
      'status': status,
      'createdBy': createdBy,
      'salespersons': salespersons,
      // 'rolesAccess': rolesAccess,
      'commissionPercent': commissionPercent,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Helper method to format dates for display
  String get formattedCreatedAt {
    return DateFormat('MM dd, yyyy').format(createdAt);
  }

  // Create a copy with updated fields
  SalesManager copyWith({
    String? id,
    String? fullName,
    String? email,
    String? password,
    String? phoneNumber,
    String? image,
    String? status,
    String? createdBy,
    List<String>? salespersons,
    // List<String>? rolesAccess,
    DateTime? createdAt,
    DateTime? updatedAt,
    double? commissionPercent,
  }) {
    return SalesManager(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      password: password ?? this.password,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      image: image ?? this.image,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      salespersons: salespersons ?? this.salespersons,
      // rolesAccess: rolesAccess ?? this.rolesAccess,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      commissionPercent: commissionPercent ?? this.commissionPercent,
    );
  }
}