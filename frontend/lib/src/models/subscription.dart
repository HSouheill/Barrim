// models/subscription_models.dart
import 'dart:convert';

class SubscriptionPlan {
  final String? id;
  final String title;
  final String description;
  final double price;
  final int duration; // Duration in months
  final String type; // "company", "wholesaler", "service_provider"
  final List<Benefit> benefits;
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionPlan({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.type,
    required this.benefits,
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlan.fromJson(Map<String, dynamic> json) {
    return SubscriptionPlan(
      id: json['id'] ?? json['_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      type: json['type'] ?? '',
      benefits: _parseBenefits(json['benefits']),
      isActive: json['isActive'] ?? true,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
    );
  }

  // Helper method to parse benefits from the nested structure
  static List<Benefit> _parseBenefits(dynamic benefitsData) {
    if (benefitsData == null) return [];
    
    if (benefitsData is List) {
      List<Benefit> benefits = [];
      for (var item in benefitsData) {
        if (item is List) {
          // Handle nested array structure like [[{Key: title, Value: subscription}, {Key: description, Value: }]]
          for (var subItem in item) {
            if (subItem is Map<String, dynamic>) {
              String title = '';
              String description = '';
              
              for (var entry in subItem.entries) {
                if (entry.key == 'Key' && entry.value == 'title') {
                  title = subItem['Value'] ?? '';
                } else if (entry.key == 'Key' && entry.value == 'description') {
                  description = subItem['Value'] ?? '';
                }
              }
              
              if (title.isNotEmpty) {
                benefits.add(Benefit(title: title, description: description));
              }
            }
          }
        } else if (item is Map<String, dynamic>) {
          // Handle direct benefit object
          benefits.add(Benefit.fromJson(item));
        }
      }
      return benefits;
    }
    
    return [];
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'title': title,
      'description': description,
      'price': price,
      'duration': duration,
      'type': type,
      'benefits': benefits.map((b) => b.toJson()).toList(),
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  String get durationText {
    switch (duration) {
      case 1:
        return 'Monthly';
      case 6:
        return '6 Months';
      case 12:
        return 'Yearly';
      default:
        return '$duration Months';
    }
  }

  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }
}

class Benefit {
  final String title;
  final String description;

  Benefit({
    required this.title,
    required this.description,
  });

  factory Benefit.fromJson(Map<String, dynamic> json) {
    return Benefit(
      title: json['title'] ?? '',
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
    };
  }
}

class SubscriptionRequest {
  final String? id;
  final String companyId;
  final String planId;
  final String status; // "pending", "approved", "rejected"
  final DateTime requestedAt;
  final String? adminId;
  final String? adminNote;
  final DateTime? processedAt;
  final CompanyInfo? company;
  final WholesalerInfo? wholesaler;
  final ServiceProviderInfo? serviceProvider;
  final SubscriptionPlan? plan;

  SubscriptionRequest({
    this.id,
    required this.companyId,
    required this.planId,
    required this.status,
    required this.requestedAt,
    this.adminId,
    this.adminNote,
    this.processedAt,
    this.company,
    this.wholesaler,
    this.serviceProvider,
    this.plan,
  });

  factory SubscriptionRequest.fromJson(Map<String, dynamic> json) {
    // Handle nested structure from API response
    // The API returns objects with 'plan', 'request', and 'wholesaler' properties
    final requestData = json['request'] ?? json;
    final planData = json['plan'];
    final wholesalerData = json['wholesaler'];
    final companyData = json['company'];
    final serviceProviderData = json['serviceProvider'];

    return SubscriptionRequest(
      id: requestData['id'] ?? requestData['_id'],
      companyId: requestData['companyId'] ?? requestData['wholesalerId'] ?? requestData['serviceProviderId'] ?? '',
      planId: requestData['planId'] ?? '',
      status: requestData['status'] ?? 'pending',
      requestedAt: DateTime.tryParse(requestData['requestedAt'] ?? '') ?? DateTime.now(),
      adminId: requestData['adminId'],
      adminNote: requestData['adminNote'],
      processedAt: requestData['processedAt'] != null
          ? DateTime.tryParse(requestData['processedAt'])
          : null,
      company: companyData != null
          ? CompanyInfo.fromJson(companyData)
          : null,
      wholesaler: wholesalerData != null
          ? WholesalerInfo.fromJson(wholesalerData)
          : null,
      serviceProvider: serviceProviderData != null
          ? ServiceProviderInfo.fromJson(serviceProviderData)
          : null,
      plan: planData != null
          ? SubscriptionPlan.fromJson(planData)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'companyId': companyId,
      'planId': planId,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      if (adminId != null) 'adminId': adminId,
      if (adminNote != null) 'adminNote': adminNote,
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
      if (company != null) 'company': company!.toJson(),
      if (wholesaler != null) 'wholesaler': wholesaler!.toJson(),
      if (serviceProvider != null) 'serviceProvider': serviceProvider!.toJson(),
      if (plan != null) 'plan': plan!.toJson(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  
  // Helper getter to get business name from company, wholesaler, or service provider
  String? get businessName {
    return company?.businessName ?? wholesaler?.businessName ?? serviceProvider?.businessName;
  }
  
  // Helper getter to get category from company, wholesaler, or service provider
  String? get category {
    return company?.category ?? wholesaler?.category ?? serviceProvider?.category;
  }
}

class CompanyInfo {
  final String? id;
  final String businessName;
  final String category;

  CompanyInfo({
    this.id,
    required this.businessName,
    required this.category,
  });

  factory CompanyInfo.fromJson(Map<String, dynamic> json) {
    return CompanyInfo(
      id: json['id'] ?? json['_id'],
      businessName: json['businessName'] ?? '',
      category: json['category'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'businessName': businessName,
      'category': category,
    };
  }
}

class WholesalerInfo {
  final String? id;
  final String businessName;
  final String category;
  final String? phone;

  WholesalerInfo({
    this.id,
    required this.businessName,
    required this.category,
    this.phone,
  });

  factory WholesalerInfo.fromJson(Map<String, dynamic> json) {
    return WholesalerInfo(
      id: json['id'] ?? json['_id'],
      businessName: json['businessName'] ?? '',
      category: json['category'] ?? '',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'businessName': businessName,
      'category': category,
      if (phone != null) 'phone': phone,
    };
  }
}

class ServiceProviderInfo {
  final String? id;
  final String businessName;
  final String category;
  final String? phone;

  ServiceProviderInfo({
    this.id,
    required this.businessName,
    required this.category,
    this.phone,
  });

  factory ServiceProviderInfo.fromJson(Map<String, dynamic> json) {
    return ServiceProviderInfo(
      id: json['id'] ?? json['_id'],
      businessName: json['businessName'] ?? '',
      category: json['category'] ?? '',
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'businessName': businessName,
      'category': category,
      if (phone != null) 'phone': phone,
    };
  }
}

class CompanySubscription {
  final String? id;
  final String companyId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // "active", "cancelled", "expired", "paused"
  final bool autoRenew;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final SubscriptionPlan? plan;

  CompanySubscription({
    this.id,
    required this.companyId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.autoRenew = false,
    this.createdAt,
    this.updatedAt,
    this.plan,
  });

  factory CompanySubscription.fromJson(Map<String, dynamic> json) {
    // Handle nested structure from API response
    final subscriptionData = json['subscription'] ?? json;

    return CompanySubscription(
      id: subscriptionData['id'] ?? subscriptionData['_id'],
      companyId: subscriptionData['companyId'] ?? '',
      planId: subscriptionData['planId'] ?? '',
      startDate: DateTime.tryParse(subscriptionData['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(subscriptionData['endDate'] ?? '') ?? DateTime.now(),
      status: subscriptionData['status'] ?? 'active',
      autoRenew: subscriptionData['autoRenew'] ?? false,
      createdAt: subscriptionData['createdAt'] != null
          ? DateTime.tryParse(subscriptionData['createdAt'])
          : null,
      updatedAt: subscriptionData['updatedAt'] != null
          ? DateTime.tryParse(subscriptionData['updatedAt'])
          : null,
      plan: json['plan'] != null
          ? SubscriptionPlan.fromJson(json['plan'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'companyId': companyId,
      'planId': planId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'autoRenew': autoRenew,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (plan != null) 'plan': plan!.toJson(),
    };
  }

  bool get isActive => status == 'active' && endDate.isAfter(DateTime.now());
  bool get isExpired => endDate.isBefore(DateTime.now());
  bool get isCancelled => status == 'cancelled';

  int get remainingDays {
    if (isExpired) return 0;
    return endDate.difference(DateTime.now()).inDays;
  }
}

class SubscriptionApprovalRequest {
  final String status; // "approved" or "rejected"
  final String? adminNote;

  SubscriptionApprovalRequest({
    required this.status,
    this.adminNote,
  });

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      if (adminNote != null && adminNote!.isNotEmpty) 'adminNote': adminNote,
    };
  }
}

class CreateSubscriptionPlanRequest {
  final String title;
  final String description;
  final double price;
  final int duration;
  final String type;
  final List<Benefit> benefits;
  final bool isActive;

  CreateSubscriptionPlanRequest({
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.type,
    required this.benefits,
    this.isActive = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'price': price,
      'duration': duration,
      'type': type,
      'benefits': benefits.map((b) => b.toJson()).toList(),
      'isActive': isActive,
    };
  }
}

// API Response wrapper
class SubscriptionApiResponse<T> {
  final int status;
  final String message;
  final T? data;

  SubscriptionApiResponse({
    required this.status,
    required this.message,
    this.data,
  });

  factory SubscriptionApiResponse.fromJson(
      Map<String, dynamic> json,
      T Function(dynamic)? fromJsonT,
      ) {
    return SubscriptionApiResponse<T>(
      status: json['status'] ?? 200,
      message: json['message'] ?? '',
      data: json['data'] != null && fromJsonT != null
          ? fromJsonT(json['data'])
          : json['data'],
    );
  }

  bool get isSuccess => status >= 200 && status < 300;
}

// Enriched Branch Subscription Request model for the new endpoint
class EnrichedBranchSubscriptionRequest {
  final BranchSubscriptionRequestData request;
  final SubscriptionPlan plan;
  final CompanyDetails company;
  final BranchDetails branch;

  EnrichedBranchSubscriptionRequest({
    required this.request,
    required this.plan,
    required this.company,
    required this.branch,
  });

  factory EnrichedBranchSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return EnrichedBranchSubscriptionRequest(
      request: BranchSubscriptionRequestData.fromJson(json['request'] ?? {}),
      plan: SubscriptionPlan.fromJson(json['plan'] ?? {}),
      company: CompanyDetails.fromJson(json['company'] ?? {}),
      branch: BranchDetails.fromJson(json['branch'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request': request.toJson(),
      'plan': plan.toJson(),
      'company': company.toJson(),
      'branch': branch.toJson(),
    };
  }

  // Helper getters for easy access
  String? get id => request.id;
  String get businessName => company.businessName;
  String get branchName => branch.name;
  String get planTitle => plan.title;
  String get status => request.status;
  bool get isPending => request.isPending;
}

// Branch Subscription Request Data model
class BranchSubscriptionRequestData {
  final String? id;
  final String branchId;
  final String planId;
  final String status;
  final DateTime? requestedAt;
  final String? adminId;
  final String? adminNote;
  final DateTime? processedAt;

  BranchSubscriptionRequestData({
    this.id,
    required this.branchId,
    required this.planId,
    required this.status,
    this.requestedAt,
    this.adminId,
    this.adminNote,
    this.processedAt,
  });

  factory BranchSubscriptionRequestData.fromJson(Map<String, dynamic> json) {
    return BranchSubscriptionRequestData(
      id: json['id'] ?? json['_id'],
      branchId: json['branchId'] ?? '',
      planId: json['planId'] ?? '',
      status: json['status'] ?? 'pending',
      requestedAt: json['requestedAt'] != null
          ? DateTime.tryParse(json['requestedAt'])
          : null,
      adminId: json['adminId'],
      adminNote: json['adminNote'],
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'branchId': branchId,
      'planId': planId,
      'status': status,
      if (requestedAt != null) 'requestedAt': requestedAt!.toIso8601String(),
      if (adminId != null) 'adminId': adminId,
      if (adminNote != null) 'adminNote': adminNote,
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

// Company Details model for enriched response
class CompanyDetails {
  final String? id;
  final String businessName;
  final String phone;
  final String whatsapp;
  final String website;

  CompanyDetails({
    this.id,
    required this.businessName,
    required this.phone,
    required this.whatsapp,
    required this.website,
  });

  factory CompanyDetails.fromJson(Map<String, dynamic> json) {
    return CompanyDetails(
      id: json['id'] ?? json['_id'],
      businessName: json['businessName'] ?? '',
      phone: json['phone'] ?? '',
      whatsapp: json['whatsapp'] ?? '',
      website: json['website'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'businessName': businessName,
      'phone': phone,
      'whatsapp': whatsapp,
      'website': website,
    };
  }
}

// Branch Details model for enriched response
class BranchDetails {
  final String? id;
  final String name;
  final BranchLocation? location;
  final String phone;
  final String category;
  final String description;
  final String status;

  BranchDetails({
    this.id,
    required this.name,
    this.location,
    required this.phone,
    required this.category,
    required this.description,
    required this.status,
  });

  factory BranchDetails.fromJson(Map<String, dynamic> json) {
    return BranchDetails(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? '',
      location: json['location'] != null 
          ? BranchLocation.fromJson(json['location'])
          : null,
      phone: json['phone'] ?? '',
      category: json['category'] ?? '',
      description: json['description'] ?? '',
      status: json['status'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'name': name,
      if (location != null) 'location': location!.toJson(),
      'phone': phone,
      'category': category,
      'description': description,
      'status': status,
    };
  }

  // Helper getter for location display
  String get locationDisplay {
    if (location == null) return '';
    return '${location!.city}, ${location!.country}';
  }
}

// Branch Location model
class BranchLocation {
  final String country;
  final String district;
  final String city;
  final String street;
  final String postalCode;
  final double? lat;
  final double? lng;

  BranchLocation({
    required this.country,
    required this.district,
    required this.city,
    required this.street,
    required this.postalCode,
    this.lat,
    this.lng,
  });

  factory BranchLocation.fromJson(Map<String, dynamic> json) {
    return BranchLocation(
      country: json['country'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      street: json['street'] ?? '',
      postalCode: json['postalCode'] ?? '',
      lat: json['lat']?.toDouble(),
      lng: json['lng']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'district': district,
      'city': city,
      'street': street,
      'postalCode': postalCode,
      if (lat != null) 'lat': lat,
      if (lng != null) 'lng': lng,
    };
  }
}

class EnrichedWholesalerSubscriptionRequest {
  final SubscriptionRequest request;
  final WholesalerInfo wholesaler;
  final SubscriptionPlan plan;

  EnrichedWholesalerSubscriptionRequest({
    required this.request,
    required this.wholesaler,
    required this.plan,
  });

  factory EnrichedWholesalerSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return EnrichedWholesalerSubscriptionRequest(
      request: SubscriptionRequest.fromJson(json['request'] ?? {}),
      wholesaler: WholesalerInfo.fromJson(json['wholesaler'] ?? {}),
      plan: SubscriptionPlan.fromJson(json['plan'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'request': request.toJson(),
      'wholesaler': wholesaler.toJson(),
      'plan': plan.toJson(),
    };
  }

  // Helper getters for easier access
  String? get id => request.id;
  String get businessName => wholesaler.businessName;
  String get category => wholesaler.category;
  String? get phone => wholesaler.phone;
  String get planTitle => plan.title;
  double get planPrice => plan.price;
  int get planDuration => plan.duration;
  DateTime get requestedAt => request.requestedAt;
}

// Wholesaler Branch Subscription Request Models
class WholesalerBranchSubscriptionRequest {
  final String? id;
  final String branchId;
  final String planId;
  final String status; // "pending", "approved", "rejected"
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? processedAt;
  final String? adminNote;
  final DateTime? approvedAt;
  final String? approvedBy;
  final DateTime? rejectedAt;
  final String? rejectedBy;

  WholesalerBranchSubscriptionRequest({
    this.id,
    required this.branchId,
    required this.planId,
    this.status = 'pending',
    this.createdAt,
    this.updatedAt,
    this.processedAt,
    this.adminNote,
    this.approvedAt,
    this.approvedBy,
    this.rejectedAt,
    this.rejectedBy,
  });

  factory WholesalerBranchSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return WholesalerBranchSubscriptionRequest(
      id: json['id'] ?? json['_id'],
      branchId: json['branchId'] ?? json['branch_id'] ?? '',
      planId: json['planId'] ?? json['plan_id'] ?? '',
      status: json['status'] ?? 'pending',
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'])
          : json['requestedAt'] != null
              ? DateTime.tryParse(json['requestedAt'])
              : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.tryParse(json['updatedAt'])
          : null,
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'])
          : null,
      adminNote: json['adminNote'] ?? json['admin_note'],
      approvedAt: json['approvedAt'] != null
          ? DateTime.tryParse(json['approvedAt'])
          : null,
      approvedBy: json['approvedBy'] ?? json['approved_by'],
      rejectedAt: json['rejectedAt'] != null
          ? DateTime.tryParse(json['rejectedAt'])
          : null,
      rejectedBy: json['rejectedBy'] ?? json['rejected_by'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'branchId': branchId,
      'planId': planId,
      'status': status,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
      if (adminNote != null) 'adminNote': adminNote,
      if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
      if (approvedBy != null) 'approvedBy': approvedBy,
      if (rejectedAt != null) 'rejectedAt': rejectedAt!.toIso8601String(),
      if (rejectedBy != null) 'rejectedBy': rejectedBy,
    };
  }
}

class EnrichedWholesalerBranchSubscriptionRequest {
  final WholesalerBranchSubscriptionRequest request;
  final Map<String, dynamic> branch;
  final Map<String, dynamic> wholesaler;
  final SubscriptionPlan plan;

  EnrichedWholesalerBranchSubscriptionRequest({
    required this.request,
    required this.branch,
    required this.wholesaler,
    required this.plan,
  });

  factory EnrichedWholesalerBranchSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    return EnrichedWholesalerBranchSubscriptionRequest(
      request: WholesalerBranchSubscriptionRequest.fromJson(json['request'] ?? {}),
      branch: json['branch'] ?? {},
      wholesaler: json['wholesaler'] ?? {},
      plan: SubscriptionPlan.fromJson(json['plan'] ?? {}),
    );
  }

  // Convenience getters
  String get id => request.id ?? '';
  String get status => request.status;
  String get branchName => branch['name'] ?? '';
  String get businessName => wholesaler['businessName'] ?? '';
  String get planTitle => plan.title;
  String get category => wholesaler['category'] ?? '';
  String get location {
    final locationData = branch['location'];
    if (locationData is Map<String, dynamic>) {
      final city = locationData['city'] ?? '';
      final district = locationData['district'] ?? '';
      final street = locationData['street'] ?? '';
      if (city.isNotEmpty && district.isNotEmpty) {
        return '$city, $district';
      } else if (city.isNotEmpty) {
        return city;
      } else if (district.isNotEmpty) {
        return district;
      } else if (street.isNotEmpty) {
        return street;
      }
    }
    return '';
  }
  String get phone => branch['phone'] ?? '';
  DateTime? get createdAt => request.createdAt;

  Map<String, dynamic> toJson() {
    return {
      'request': request.toJson(),
      'branch': branch,
      'wholesaler': wholesaler,
      'plan': plan.toJson(),
    };
  }
}

class WholesalerBranchSubscription {
  final String? id;
  final String branchId;
  final String planId;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // "active", "expired", "cancelled"
  final bool autoRenew;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  WholesalerBranchSubscription({
    this.id,
    required this.branchId,
    required this.planId,
    required this.startDate,
    required this.endDate,
    this.status = 'active',
    this.autoRenew = false,
    this.createdAt,
    this.updatedAt,
  });

  factory WholesalerBranchSubscription.fromJson(Map<String, dynamic> json) {
    return WholesalerBranchSubscription(
      id: json['id'] ?? json['_id'],
      branchId: json['branchId'] ?? json['branch_id'] ?? '',
      planId: json['planId'] ?? json['plan_id'] ?? '',
      startDate: DateTime.tryParse(json['startDate'] ?? json['start_date'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? json['end_date'] ?? '') ?? DateTime.now(),
      status: json['status'] ?? 'active',
      autoRenew: json['autoRenew'] ?? json['auto_renew'] ?? false,
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
      'branchId': branchId,
      'planId': planId,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'status': status,
      'autoRenew': autoRenew,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }
}