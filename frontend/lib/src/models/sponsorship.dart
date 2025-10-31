import 'dart:convert';

// Duration constants for common sponsorship periods
class DurationConstants {
  static const int minDurationDays = 1;      // Minimum duration in days
  static const int maxDurationDays = 365;    // Maximum duration in days (1 year)
  static const int defaultDuration = 30;     // Default duration in days
  
  // Common duration presets
  static const int durationWeek = 7;         // 1 week
  static const int durationMonth = 30;       // 1 month
  static const int durationQuarter = 90;     // 3 months
  static const int durationHalfYear = 180;   // 6 months
  static const int durationYear = 365;       // 1 year
}

// Duration validation errors
class DurationValidationErrors {
  static const String durationTooShort = 'Duration must be at least 1 day';
  static const String durationTooLong = 'Duration cannot exceed 365 days';
  static const String invalidDuration = 'Duration must be a positive integer';
}

// DurationUnit represents the unit of duration
enum DurationUnit { days, weeks, months, years }

// DurationInfo provides additional information about the duration
class DurationInfo {
  final int days;
  final int weeks;
  final int months;
  final int years;
  final DurationUnit unit;
  final bool isValid;

  DurationInfo({
    required this.days,
    required this.weeks,
    required this.months,
    required this.years,
    required this.unit,
    required this.isValid,
  });

  factory DurationInfo.fromJson(Map<String, dynamic> json) {
    return DurationInfo(
      days: json['days'] ?? 0,
      weeks: json['weeks'] ?? 0,
      months: json['months'] ?? 0,
      years: json['years'] ?? 0,
      unit: _parseDurationUnit(json['unit'] ?? 'days'),
      isValid: json['isValid'] ?? false,
    );
  }

  static DurationUnit _parseDurationUnit(String unit) {
    switch (unit) {
      case 'years':
        return DurationUnit.years;
      case 'months':
        return DurationUnit.months;
      case 'weeks':
        return DurationUnit.weeks;
      default:
        return DurationUnit.days;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'days': days,
      'weeks': weeks,
      'months': months,
      'years': years,
      'unit': unit.name,
      'isValid': isValid,
    };
  }

  // Get a human-readable description of the duration
  String get durationDescription {
    if (!isValid) return 'Invalid duration';

    switch (unit) {
      case DurationUnit.years:
        return years == 1 ? '1 year' : '$years years';
      case DurationUnit.months:
        return months == 1 ? '1 month' : '$months months';
      case DurationUnit.weeks:
        return weeks == 1 ? '1 week' : '$weeks weeks';
      case DurationUnit.days:
        return days == 1 ? '1 day' : '$days days';
    }
  }

  // Calculate duration info from days
  static DurationInfo calculateFromDays(int days) {
    if (days < DurationConstants.minDurationDays || days > DurationConstants.maxDurationDays) {
      return DurationInfo(
        days: days,
        weeks: 0,
        months: 0,
        years: 0,
        unit: DurationUnit.days,
        isValid: false,
      );
    }

    final weeks = days ~/ 7;
    final months = days ~/ 30;
    final years = days ~/ 365;

    DurationUnit unit = DurationUnit.days;
    if (days >= 365) {
      unit = DurationUnit.years;
    } else if (days >= 30) {
      unit = DurationUnit.months;
    } else if (days >= 7) {
      unit = DurationUnit.weeks;
    }

    return DurationInfo(
      days: days,
      weeks: weeks,
      months: months,
      years: years,
      unit: unit,
      isValid: true,
    );
  }

  // Get recommended duration options
  static List<int> get recommendedDurations => [
    DurationConstants.durationWeek,     // 7 days
    DurationConstants.durationMonth,    // 30 days
    DurationConstants.durationQuarter,  // 90 days
    DurationConstants.durationHalfYear, // 180 days
    DurationConstants.durationYear,     // 365 days
  ];
}

class Sponsorship {
  final String? id;
  final String title;
  final String description;
  final double price;
  final int duration; // Duration in days
  final DurationInfo? durationInfo; // Calculated duration breakdown
  final double? discount; // Discount percentage (optional)
  final String code; // Unique sponsorship code
  final int maxUses; // Maximum number of times this sponsorship can be used
  final int usedCount; // Current usage count
  final DateTime startDate;
  final DateTime endDate;
  final bool isActive;
  final String type; // Type of sponsorship: 'serviceProvider' or 'companyWholesaler'
  final String? createdBy; // Admin ID who created this sponsorship
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Sponsorship({
    this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    this.durationInfo,
    this.discount,
    required this.code,
    required this.maxUses,
    this.usedCount = 0,
    required this.startDate,
    required this.endDate,
    this.isActive = true,
    required this.type,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory Sponsorship.fromJson(Map<String, dynamic> json) {
    return Sponsorship(
      id: json['id'] ?? json['_id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      price: (json['price'] ?? 0).toDouble(),
      duration: json['duration'] ?? 0,
      durationInfo: json['durationInfo'] != null ? DurationInfo.fromJson(json['durationInfo']) : null,
      discount: (json['discount'] ?? 0).toDouble(),
      code: json['code'] ?? '',
      maxUses: json['maxUses'] ?? 0,
      usedCount: json['usedCount'] ?? 0,
      startDate: DateTime.tryParse(json['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(json['endDate'] ?? '') ?? DateTime.now(),
      isActive: json['isActive'] ?? true,
      type: _determineSponsorshipType(json), // Determine type from data or fallback to title prefix
      createdBy: json['createdBy'],
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
      'title': title,
      'description': description,
      'price': price,
      'duration': duration,
      if (durationInfo != null) 'durationInfo': durationInfo!.toJson(),
      'discount': discount,
      'code': code,
      'maxUses': maxUses,
      'usedCount': usedCount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'isActive': isActive,
      'type': type,
      if (createdBy != null) 'createdBy': createdBy,
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
    };
  }

  String get durationText {
    if (durationInfo != null) {
      return durationInfo!.durationDescription;
    }
    
    // Fallback to basic duration display
    if (duration == 1) return '1 Day';
    if (duration < 7) return '$duration Days';
    if (duration < 30) return '${duration ~/ 7} Weeks';
    if (duration < 365) return '${duration ~/ 30} Months';
    return '${duration ~/ 365} Years';
  }

  String get formattedPrice {
    return '\$${price.toStringAsFixed(2)}';
  }

  String get formattedDiscount {
    if (discount == null) return 'No discount';
    return '${discount!.toStringAsFixed(1)}%';
  }

  bool get isExpired => endDate.isBefore(DateTime.now());
  bool get isAvailable => isActive && !isExpired && usedCount < maxUses;
  int get remainingUses => maxUses - usedCount;

  // Helper method to determine sponsorship type from data or title prefix
  static String _determineSponsorshipType(Map<String, dynamic> json) {
    // First, try to get the type from the json
    if (json['type'] != null && json['type'].toString().isNotEmpty) {
      return json['type'].toString();
    }
    
    // Fallback: determine type from title prefix for existing sponsorships
    final title = json['title']?.toString() ?? '';
    if (title.startsWith('Service Provider:')) {
      return 'serviceProvider';
    } else if (title.startsWith('Company/Wholesaler:')) {
      return 'companyWholesaler';
    }
    
    // Default fallback
    return 'companyWholesaler';
  }
}

class SponsorshipRequest {
  final String title; // Required - user provides custom title
  final double price;
  final int duration; // Duration in days
  final DateTime startDate;
  final DateTime endDate;
  final String type; // Type of sponsorship: 'serviceProvider' or 'companyWholesaler'
  final double? discount; // Optional discount percentage

  SponsorshipRequest({
    required this.title,
    required this.price,
    required this.duration,
    required this.startDate,
    required this.endDate,
    required this.type,
    this.discount,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'price': price,
      'duration': duration,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'type': type,
      if (discount != null) 'discount': discount,
    };
  }
}

class SponsorshipUpdateRequest {
  final String? title;
  final String? description;
  final double? price;
  final int? duration;
  final double? discount; // Already optional
  final int? maxUses;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool? isActive;

  SponsorshipUpdateRequest({
    this.title,
    this.description,
    this.price,
    this.duration,
    this.discount,
    this.maxUses,
    this.startDate,
    this.endDate,
    this.isActive,
  });

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    if (title != null) data['title'] = title;
    if (description != null) data['description'] = description;
    if (price != null) data['price'] = price;
    if (duration != null) data['duration'] = duration;
    if (discount != null) data['discount'] = discount;
    if (maxUses != null) data['maxUses'] = maxUses;
    if (startDate != null) data['startDate'] = startDate!.toIso8601String();
    if (endDate != null) data['endDate'] = endDate!.toIso8601String();
    if (isActive != null) data['isActive'] = isActive;
    return data;
  }
}

class SponsorshipApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final String? error;

  SponsorshipApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory SponsorshipApiResponse.fromJson(Map<String, dynamic> json) {
    return SponsorshipApiResponse<T>(
      success: json['success'] ?? false,
      message: json['message'] ?? '',
      data: json['data'] ?? json['sponsorship'],
      error: json['error'],
    );
  }

  bool get isSuccess => success;
}

class SponsorshipListResponse {
  final List<Sponsorship> sponsorships;
  final SponsorshipPagination pagination;

  SponsorshipListResponse({
    required this.sponsorships,
    required this.pagination,
  });

  factory SponsorshipListResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? {};
    return SponsorshipListResponse(
      sponsorships: (data['sponsorships'] as List?)
          ?.map((s) => Sponsorship.fromJson(s))
          .toList() ?? [],
      pagination: SponsorshipPagination.fromJson(data['pagination'] ?? {}),
    );
  }
}

class SponsorshipPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  SponsorshipPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory SponsorshipPagination.fromJson(Map<String, dynamic> json) {
    return SponsorshipPagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
    );
  }
}

// Sponsorship Subscription Request Models
class SponsorshipSubscriptionRequest {
  final String? id;
  final String entityType; // "company", "wholesaler", "service_provider"
  final String entityId;
  final String sponsorshipId;
  final String status; // "pending", "approved", "rejected"
  final DateTime requestedAt;
  final String? adminId;
  final String? adminNote;
  final DateTime? processedAt;
  final bool? adminApproved;
  final String? approvedBy;
  final DateTime? approvedAt;
  final String? rejectedBy;
  final DateTime? rejectedAt;
  final Sponsorship? sponsorship;
  final Map<String, dynamic>? entity;

  SponsorshipSubscriptionRequest({
    this.id,
    required this.entityType,
    required this.entityId,
    required this.sponsorshipId,
    required this.status,
    required this.requestedAt,
    this.adminId,
    this.adminNote,
    this.processedAt,
    this.adminApproved,
    this.approvedBy,
    this.approvedAt,
    this.rejectedBy,
    this.rejectedAt,
    this.sponsorship,
    this.entity,
  });

  factory SponsorshipSubscriptionRequest.fromJson(Map<String, dynamic> json) {
    print('DEBUG: SponsorshipSubscriptionRequest.fromJson called with: $json');
    
    // Handle the nested structure where request data is in a 'request' field
    Map<String, dynamic> requestData;
    Map<String, dynamic>? entityData;
    Map<String, dynamic>? sponsorshipData;
    
    if (json['request'] != null && json['request'] is Map<String, dynamic>) {
      // This is the new structure with nested request data
      requestData = json['request'] as Map<String, dynamic>;
      entityData = json['entityDetails'] as Map<String, dynamic>?;
      sponsorshipData = json['sponsorship'] as Map<String, dynamic>?;
      print('DEBUG: Using nested structure');
    } else {
      // This is the old structure with flat data
      requestData = json;
      entityData = json['entity'] as Map<String, dynamic>?;
      sponsorshipData = json['sponsorship'] as Map<String, dynamic>?;
      print('DEBUG: Using flat structure');
    }
    
    final id = requestData['id'] ?? requestData['_id'];
    print('DEBUG: Parsed ID: $id');
    
    return SponsorshipSubscriptionRequest(
      id: id,
      entityType: requestData['entityType'] ?? '',
      entityId: requestData['entityId'] ?? '',
      sponsorshipId: requestData['sponsorshipId'] ?? '',
      status: requestData['status'] ?? 'pending',
      requestedAt: DateTime.tryParse(requestData['requestedAt'] ?? '') ?? DateTime.now(),
      adminId: requestData['adminId'],
      adminNote: requestData['adminNote'],
      processedAt: requestData['processedAt'] != null
          ? DateTime.tryParse(requestData['processedAt'])
          : null,
      adminApproved: requestData['adminApproved'],
      approvedBy: requestData['approvedBy'],
      approvedAt: requestData['approvedAt'] != null
          ? DateTime.tryParse(requestData['approvedAt'])
          : null,
      rejectedBy: requestData['rejectedBy'],
      rejectedAt: requestData['rejectedAt'] != null
          ? DateTime.tryParse(requestData['rejectedAt'])
          : null,
      sponsorship: sponsorshipData != null
          ? Sponsorship.fromJson(sponsorshipData)
          : null,
      entity: entityData,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'entityType': entityType,
      'entityId': entityId,
      'sponsorshipId': sponsorshipId,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      if (adminId != null) 'adminId': adminId,
      if (adminNote != null) 'adminNote': adminNote,
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
      if (adminApproved != null) 'adminApproved': adminApproved,
      if (approvedBy != null) 'approvedBy': approvedBy,
      if (approvedAt != null) 'approvedAt': approvedAt!.toIso8601String(),
      if (rejectedBy != null) 'rejectedBy': rejectedBy,
      if (rejectedAt != null) 'rejectedAt': rejectedAt!.toIso8601String(),
      if (sponsorship != null) 'sponsorship': sponsorship!.toJson(),
      if (entity != null) 'entity': entity,
    };
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
}

class SponsorshipSubscriptionApprovalRequest {
  final String status; // "approved" or "rejected"
  final String? adminNote;

  SponsorshipSubscriptionApprovalRequest({
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

class SponsorshipSubscriptionListResponse {
  final List<SponsorshipSubscriptionRequest> requests;
  final SponsorshipSubscriptionPagination pagination;

  SponsorshipSubscriptionListResponse({
    required this.requests,
    required this.pagination,
  });

  factory SponsorshipSubscriptionListResponse.fromJson(Map<String, dynamic> json) {
    print('DEBUG: SponsorshipSubscriptionListResponse.fromJson called with: $json');
    
    // Try different possible structures
    List<dynamic>? requestsList;
    Map<String, dynamic>? paginationData;
    
    if (json['data'] != null && json['data'] is Map<String, dynamic>) {
      final data = json['data'] as Map<String, dynamic>;
      requestsList = data['requests'] as List?;
      paginationData = data['pagination'] as Map<String, dynamic>?;
      print('DEBUG: Found data structure with ${requestsList?.length ?? 0} requests');
    } else if (json['requests'] != null && json['requests'] is List) {
      requestsList = json['requests'] as List;
      paginationData = json['pagination'] as Map<String, dynamic>?;
      print('DEBUG: Found direct requests structure with ${requestsList.length} requests');
    } else {
      print('DEBUG: No recognizable structure found');
    }
    
    final requests = requestsList?.map((r) => SponsorshipSubscriptionRequest.fromJson(r)).toList() ?? [];
    
    return SponsorshipSubscriptionListResponse(
      requests: requests,
      pagination: SponsorshipSubscriptionPagination.fromJson(paginationData ?? {}),
    );
  }
}

class SponsorshipSubscriptionPagination {
  final int page;
  final int limit;
  final int total;
  final int pages;

  SponsorshipSubscriptionPagination({
    required this.page,
    required this.limit,
    required this.total,
    required this.pages,
  });

  factory SponsorshipSubscriptionPagination.fromJson(Map<String, dynamic> json) {
    return SponsorshipSubscriptionPagination(
      page: json['page'] ?? 1,
      limit: json['limit'] ?? 10,
      total: json['total'] ?? 0,
      pages: json['pages'] ?? 0,
    );
  }
}
