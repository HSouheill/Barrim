
class Admin {
  final String id;
  final String email;
  final String? password;
  final String? profilePicture;
  final DateTime createdAt;
  final DateTime updatedAt;

  Admin({
    required this.id,
    required this.email,
    this.password,
    this.profilePicture,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Admin.fromJson(Map<String, dynamic> json) {
    return Admin(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      password: json['password'],
      profilePicture: json['profilePicture'],
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
      'email': email,
      'password': password,
      'profilePicture': profilePicture,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

  class BranchRequest {
  final String id;
  final String companyId;
  final Branch branchData;
  final String status; // "pending", "approved", "rejected"
  final String? adminId;
  final String? adminNote;
  final DateTime submittedAt;
  final DateTime? processedAt;

  BranchRequest({
    String? id,
  required this.companyId,
  required this.branchData,
  required this.status,
  this.adminId,
  this.adminNote,
  DateTime? submittedAt,
  this.processedAt,
  }) :
  this.id = id ?? '',
  this.submittedAt = submittedAt ?? DateTime.now();

  factory BranchRequest.fromJson(Map<String, dynamic> json) {
  return BranchRequest(
    id: json['id'] ?? '',
  companyId: json['companyId'] ?? '',
  branchData: Branch.fromJson(json['branchData']),
  status: json['status'] ?? 'pending',
  adminId: json['adminId'] ?? '',

  adminNote: json['adminNote'],
  submittedAt: json['submittedAt'] != null
  ? json['submittedAt'] is DateTime
  ? json['submittedAt']
      : DateTime.parse(json['submittedAt'])
      : DateTime.now(),
  processedAt: json['processedAt'] != null
  ? json['processedAt'] is DateTime
  ? json['processedAt']
      : DateTime.parse(json['processedAt'])
      : null,
  );
  }

  Map<String, dynamic> toJson() {
  return {
  '_id': id,
  'companyId': companyId,
  'branchData': branchData.toJson(),
  'status': status,
  'adminId': adminId,
  'adminNote': adminNote,
  'submittedAt': submittedAt,
  'processedAt': processedAt,
  };
  }
  }

// AdminDashboardStats represents statistics for the admin dashboard
  class AdminDashboardStats {
  final int totalUsers;
  final int activeUsers;
  final int totalCompanies;
  final int activeCompanies;
  final int inactiveCompanies;
  final int totalBranches;
  final int pendingBranches;
  final int totalCategories;

  AdminDashboardStats({
  required this.totalUsers,
  required this.activeUsers,
  required this.totalCompanies,
  required this.activeCompanies,
  required this.inactiveCompanies,
  required this.totalBranches,
  required this.pendingBranches,
  required this.totalCategories,
  });

  factory AdminDashboardStats.fromJson(Map<String, dynamic> json) {
  return AdminDashboardStats(
  totalUsers: json['totalUsers'] ?? 0,
  activeUsers: json['activeUsers'] ?? 0,
  totalCompanies: json['totalCompanies'] ?? 0,
  activeCompanies: json['activeCompanies'] ?? 0,
  inactiveCompanies: json['inactiveCompanies'] ?? 0,
  totalBranches: json['totalBranches'] ?? 0,
  pendingBranches: json['pendingBranches'] ?? 0,
  totalCategories: json['totalCategories'] ?? 0,
  );
  }

  Map<String, dynamic> toJson() {
  return {
  'totalUsers': totalUsers,
  'activeUsers': activeUsers,
  'totalCompanies': totalCompanies,
  'activeCompanies': activeCompanies,
  'inactiveCompanies': inactiveCompanies,
  'totalBranches': totalBranches,
  'pendingBranches': pendingBranches,
  'totalCategories': totalCategories,
  };
  }
  }

// CompanyFilter represents filters for company listing
  class CompanyFilter {
  final String? status;
  final String? category;
  final Location? location;
  final DateTime? startDate;
  final DateTime? endDate;
  final String? searchTerm;

  CompanyFilter({
  this.status,
  this.category,
  this.location,
  this.startDate,
  this.endDate,
  this.searchTerm,
  });

  Map<String, dynamic> toJson() {
  return {
  'status': status,
  'category': category,
  'location': location?.toJson(),
  'startDate': startDate?.toIso8601String(),
  'endDate': endDate?.toIso8601String(),
  'searchTerm': searchTerm,
  };
  }
  }

// BranchApprovalRequest represents the request body for approving/rejecting branches
  class BranchApprovalRequest {
  final String status; // "approved" or "rejected"
  final String? adminNote;

  BranchApprovalRequest({
  required this.status,
  this.adminNote,
  });

  Map<String, dynamic> toJson() {
  return {
  'status': status,
  'adminNote': adminNote,
  };
  }
  }

// AdminResponse represents the response structure for admin operations
  class AdminResponse<T> {
  final int status;
  final String message;
  final T? data;

  AdminResponse({
  required this.status,
  required this.message,
  this.data,
  });

  factory AdminResponse.fromJson(Map<String, dynamic> json, T Function(Map<String, dynamic>)? fromJsonT) {
  return AdminResponse(
  status: json['status'] ?? 0,
  message: json['message'] ?? '',
  data: json['data'] != null && fromJsonT != null ? fromJsonT(json['data']) : null,
  );
  }
  }

// Placeholder classes needed for the models above
  class Branch {
  // Add appropriate fields based on your Branch model

  Branch();

  factory Branch.fromJson(Map<String, dynamic> json) {
  return Branch();
  }

  Map<String, dynamic> toJson() {
  return {};
  }
  }

  class Company {
  // Add appropriate fields based on your Company model

  Company();

  factory Company.fromJson(Map<String, dynamic> json) {
  return Company();
  }

  Map<String, dynamic> toJson() {
  return {};
  }
  }

  class Location {
  // Add appropriate fields based on your Location model

  Location();

  factory Location.fromJson(Map<String, dynamic> json) {
  return Location();
  }

  Map<String, dynamic> toJson() {
  return {};
  }
  }

  class Category {
  // Add appropriate fields based on your Category model

  Category();

  factory Category.fromJson(Map<String, dynamic> json) {
  return Category();
  }

  Map<String, dynamic> toJson() {
  return {};
  }
  }
