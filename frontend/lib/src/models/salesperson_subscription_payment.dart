String _safeString(dynamic value, {String defaultValue = ''}) {
  if (value == null) return defaultValue;
  if (value is String) return value;
  return value.toString();
}

double _toDouble(dynamic value) {
  if (value == null) return 0.0;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0.0;
  return 0.0;
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) {
    return DateTime.tryParse(value);
  }
  return null;
}

class EntitySalespersonInfo {
  final String salespersonId;
  final String fullName;
  final String email;
  final String phoneNumber;

  const EntitySalespersonInfo({
    required this.salespersonId,
    required this.fullName,
    required this.email,
    required this.phoneNumber,
  });

  factory EntitySalespersonInfo.fromJson(Map<String, dynamic> json) {
    return EntitySalespersonInfo(
      salespersonId: _safeString(json['salespersonId'] ?? json['salespersonID'] ?? json['_id']),
      fullName: _safeString(json['fullName']),
      email: _safeString(json['email']),
      phoneNumber: _safeString(json['phoneNumber']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'salespersonId': salespersonId,
      'fullName': fullName,
      'email': email,
      'phoneNumber': phoneNumber,
    };
  }
}

class CompanySubscriptionPayment {
  final String companyId;
  final String companyName;
  final String branchId;
  final String branchName;
  final String planId;
  final String planTitle;
  final double planPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime requestedAt;
  final DateTime? paidAt;
  final EntitySalespersonInfo? salesperson;
  final String subscriptionType; // "plan" or "sponsorship"
  final String? sponsorshipId;
  final String? sponsorshipTitle;
  final double? sponsorshipPrice;

  CompanySubscriptionPayment({
    required this.companyId,
    required this.companyName,
    required this.branchId,
    required this.branchName,
    required this.planId,
    required this.planTitle,
    required this.planPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.requestedAt,
    this.paidAt,
    this.salesperson,
    this.subscriptionType = 'plan',
    this.sponsorshipId,
    this.sponsorshipTitle,
    this.sponsorshipPrice,
  });

  factory CompanySubscriptionPayment.fromJson(Map<String, dynamic> json) {
    return CompanySubscriptionPayment(
      companyId: _safeString(json['companyId']),
      companyName: _safeString(json['companyName']),
      branchId: _safeString(json['branchId']),
      branchName: _safeString(json['branchName']),
      planId: _safeString(json['planId']),
      planTitle: _safeString(json['planTitle']),
      planPrice: _toDouble(json['planPrice']),
      paymentMethod: _safeString(json['paymentMethod']),
      paymentStatus: _safeString(json['paymentStatus']),
      status: _safeString(json['status'], defaultValue: 'pending'),
      requestedAt: _parseDate(json['requestedAt']) ?? DateTime.now(),
      paidAt: _parseDate(json['paidAt']),
      salesperson: json['salesperson'] != null && json['salesperson'] is Map<String, dynamic>
          ? EntitySalespersonInfo.fromJson(json['salesperson'] as Map<String, dynamic>)
          : null,
      subscriptionType: _safeString(json['subscriptionType'], defaultValue: 'plan'),
      sponsorshipId: json['sponsorshipId'] != null ? _safeString(json['sponsorshipId']) : null,
      sponsorshipTitle: json['sponsorshipTitle'] != null ? _safeString(json['sponsorshipTitle']) : null,
      sponsorshipPrice: json['sponsorshipPrice'] != null ? _toDouble(json['sponsorshipPrice']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companyId': companyId,
      'companyName': companyName,
      'branchId': branchId,
      'branchName': branchName,
      'planId': planId,
      'planTitle': planTitle,
      'planPrice': planPrice,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      if (salesperson != null) 'salesperson': salesperson!.toJson(),
      'subscriptionType': subscriptionType,
      if (sponsorshipId != null) 'sponsorshipId': sponsorshipId,
      if (sponsorshipTitle != null) 'sponsorshipTitle': sponsorshipTitle,
      if (sponsorshipPrice != null) 'sponsorshipPrice': sponsorshipPrice,
    };
  }

  bool get isSponsorship => subscriptionType == 'sponsorship';
  bool get isPlan => subscriptionType == 'plan';
  bool get hasNoSubscription => status == 'no_subscription';
}

class WholesalerSubscriptionPayment {
  final String wholesalerId;
  final String wholesalerName;
  final String branchId;
  final String branchName;
  final String planId;
  final String planTitle;
  final double planPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime requestedAt;
  final DateTime? paidAt;
  final EntitySalespersonInfo? salesperson;
  final String subscriptionType; // "plan" or "sponsorship"
  final String? sponsorshipId;
  final String? sponsorshipTitle;
  final double? sponsorshipPrice;

  WholesalerSubscriptionPayment({
    required this.wholesalerId,
    required this.wholesalerName,
    required this.branchId,
    required this.branchName,
    required this.planId,
    required this.planTitle,
    required this.planPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.requestedAt,
    this.paidAt,
    this.salesperson,
    this.subscriptionType = 'plan',
    this.sponsorshipId,
    this.sponsorshipTitle,
    this.sponsorshipPrice,
  });

  factory WholesalerSubscriptionPayment.fromJson(Map<String, dynamic> json) {
    return WholesalerSubscriptionPayment(
      wholesalerId: _safeString(json['wholesalerId']),
      wholesalerName: _safeString(json['wholesalerName']),
      branchId: _safeString(json['branchId']),
      branchName: _safeString(json['branchName']),
      planId: _safeString(json['planId']),
      planTitle: _safeString(json['planTitle']),
      planPrice: _toDouble(json['planPrice']),
      paymentMethod: _safeString(json['paymentMethod']),
      paymentStatus: _safeString(json['paymentStatus']),
      status: _safeString(json['status'], defaultValue: 'pending'),
      requestedAt: _parseDate(json['requestedAt']) ?? DateTime.now(),
      paidAt: _parseDate(json['paidAt']),
      salesperson: json['salesperson'] != null && json['salesperson'] is Map<String, dynamic>
          ? EntitySalespersonInfo.fromJson(json['salesperson'] as Map<String, dynamic>)
          : null,
      subscriptionType: _safeString(json['subscriptionType'], defaultValue: 'plan'),
      sponsorshipId: json['sponsorshipId'] != null ? _safeString(json['sponsorshipId']) : null,
      sponsorshipTitle: json['sponsorshipTitle'] != null ? _safeString(json['sponsorshipTitle']) : null,
      sponsorshipPrice: json['sponsorshipPrice'] != null ? _toDouble(json['sponsorshipPrice']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wholesalerId': wholesalerId,
      'wholesalerName': wholesalerName,
      'branchId': branchId,
      'branchName': branchName,
      'planId': planId,
      'planTitle': planTitle,
      'planPrice': planPrice,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      if (salesperson != null) 'salesperson': salesperson!.toJson(),
      'subscriptionType': subscriptionType,
      if (sponsorshipId != null) 'sponsorshipId': sponsorshipId,
      if (sponsorshipTitle != null) 'sponsorshipTitle': sponsorshipTitle,
      if (sponsorshipPrice != null) 'sponsorshipPrice': sponsorshipPrice,
    };
  }

  bool get isSponsorship => subscriptionType == 'sponsorship';
  bool get isPlan => subscriptionType == 'plan';
}

class ServiceProviderSubscriptionPayment {
  final String serviceProviderId;
  final String businessName;
  final String planId;
  final String planTitle;
  final double planPrice;
  final String paymentMethod;
  final String paymentStatus;
  final String status;
  final DateTime requestedAt;
  final DateTime? paidAt;
  final EntitySalespersonInfo? salesperson;
  final String subscriptionType; // "plan" or "sponsorship"
  final String? sponsorshipId;
  final String? sponsorshipTitle;
  final double? sponsorshipPrice;

  ServiceProviderSubscriptionPayment({
    required this.serviceProviderId,
    required this.businessName,
    required this.planId,
    required this.planTitle,
    required this.planPrice,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.status,
    required this.requestedAt,
    this.paidAt,
    this.salesperson,
    this.subscriptionType = 'plan',
    this.sponsorshipId,
    this.sponsorshipTitle,
    this.sponsorshipPrice,
  });

  factory ServiceProviderSubscriptionPayment.fromJson(Map<String, dynamic> json) {
    return ServiceProviderSubscriptionPayment(
      serviceProviderId: _safeString(json['serviceProviderId']),
      businessName: _safeString(json['businessName']),
      planId: _safeString(json['planId']),
      planTitle: _safeString(json['planTitle']),
      planPrice: _toDouble(json['planPrice']),
      paymentMethod: _safeString(json['paymentMethod']),
      paymentStatus: _safeString(json['paymentStatus']),
      status: _safeString(json['status'], defaultValue: 'pending'),
      requestedAt: _parseDate(json['requestedAt']) ?? DateTime.now(),
      paidAt: _parseDate(json['paidAt']),
      salesperson: json['salesperson'] != null && json['salesperson'] is Map<String, dynamic>
          ? EntitySalespersonInfo.fromJson(json['salesperson'] as Map<String, dynamic>)
          : null,
      subscriptionType: _safeString(json['subscriptionType'], defaultValue: 'plan'),
      sponsorshipId: json['sponsorshipId'] != null ? _safeString(json['sponsorshipId']) : null,
      sponsorshipTitle: json['sponsorshipTitle'] != null ? _safeString(json['sponsorshipTitle']) : null,
      sponsorshipPrice: json['sponsorshipPrice'] != null ? _toDouble(json['sponsorshipPrice']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceProviderId': serviceProviderId,
      'businessName': businessName,
      'planId': planId,
      'planTitle': planTitle,
      'planPrice': planPrice,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'status': status,
      'requestedAt': requestedAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      if (salesperson != null) 'salesperson': salesperson!.toJson(),
      'subscriptionType': subscriptionType,
      if (sponsorshipId != null) 'sponsorshipId': sponsorshipId,
      if (sponsorshipTitle != null) 'sponsorshipTitle': sponsorshipTitle,
      if (sponsorshipPrice != null) 'sponsorshipPrice': sponsorshipPrice,
    };
  }

  bool get isSponsorship => subscriptionType == 'sponsorship';
  bool get isPlan => subscriptionType == 'plan';
}

class SalespersonCreatedEntitiesResponse {
  final List<CompanySubscriptionPayment> companies;
  final List<WholesalerSubscriptionPayment> wholesalers;
  final List<ServiceProviderSubscriptionPayment> serviceProviders;

  const SalespersonCreatedEntitiesResponse({
    required this.companies,
    required this.wholesalers,
    required this.serviceProviders,
  });

  const SalespersonCreatedEntitiesResponse.empty()
      : companies = const [],
        wholesalers = const [],
        serviceProviders = const [];

  factory SalespersonCreatedEntitiesResponse.fromJson(Map<String, dynamic> json) {
    return SalespersonCreatedEntitiesResponse(
      companies: (json['companies'] as List<dynamic>?)
              ?.map((e) => CompanySubscriptionPayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      wholesalers: (json['wholesalers'] as List<dynamic>?)
              ?.map((e) => WholesalerSubscriptionPayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      serviceProviders: (json['serviceProviders'] as List<dynamic>?)
              ?.map((e) => ServiceProviderSubscriptionPayment.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'companies': companies.map((e) => e.toJson()).toList(),
      'wholesalers': wholesalers.map((e) => e.toJson()).toList(),
      'serviceProviders': serviceProviders.map((e) => e.toJson()).toList(),
    };
  }

  int get totalUsers => companies.length + wholesalers.length + serviceProviders.length;
  bool get hasData => totalUsers > 0;
}

