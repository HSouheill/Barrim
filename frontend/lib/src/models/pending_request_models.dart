import 'package:flutter/foundation.dart';

@immutable
class PendingCompanyRequest {
  final String id;
  final String salesPersonId;
  final Company company;
  final String email;
  final String password;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PendingCompanyRequest({
    required this.id,
    required this.salesPersonId,
    required this.company,
    required this.email,
    required this.password,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PendingCompanyRequest.fromJson(Map<String, dynamic> json) {
    return PendingCompanyRequest(
      id: json['_id'] ?? json['id'] ?? '',
      salesPersonId: json['salesPersonId'] ?? '',
      company: Company.fromJson(json['company'] ?? {}),
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      status: json['status'] ?? 'pending',
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
      '_id': id,
      'salesPersonId': salesPersonId,
      'company': company.toJson(),
      'email': email,
      'password': password,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

@immutable
class PendingWholesalerRequest {
  final String id;
  final String salesPersonId;
  final Wholesaler wholesaler;
  final String email;
  final String password;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PendingWholesalerRequest({
    required this.id,
    required this.salesPersonId,
    required this.wholesaler,
    required this.email,
    required this.password,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PendingWholesalerRequest.fromJson(Map<String, dynamic> json) {
    return PendingWholesalerRequest(
      id: json['_id'] ?? json['id'] ?? '',
      salesPersonId: json['salesPersonId'] ?? '',
      wholesaler: Wholesaler.fromJson(json['wholesaler'] ?? {}),
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      status: json['status'] ?? 'pending',
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
      '_id': id,
      'salesPersonId': salesPersonId,
      'wholesaler': wholesaler.toJson(),
      'email': email,
      'password': password,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

@immutable
class PendingServiceProviderRequest {
  final String id;
  final String salesPersonId;
  final ServiceProvider serviceProvider;
  final String email;
  final String password;
  final String creationRequestStatus;
  final DateTime createdAt;
  final DateTime updatedAt;

  const PendingServiceProviderRequest({
    required this.id,
    required this.salesPersonId,
    required this.serviceProvider,
    required this.email,
    required this.password,
    required this.creationRequestStatus,
    required this.createdAt,
    required this.updatedAt,
  });

  factory PendingServiceProviderRequest.fromJson(Map<String, dynamic> json) {
    return PendingServiceProviderRequest(
      id: json['_id'] ?? json['id'] ?? '',
      salesPersonId: json['salesPersonId'] ?? '',
      serviceProvider: ServiceProvider.fromJson(json['serviceProvider'] ?? {}),
      email: json['email'] ?? '',
      password: json['password'] ?? '',
      creationRequestStatus: json['creationRequestStatus'] ?? 'pending',
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
      '_id': id,
      'salesPersonId': salesPersonId,
      'serviceProvider': serviceProvider.toJson(),
      'email': email,
      'password': password,
      'creationRequestStatus': creationRequestStatus,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

// Simplified models for display purposes
@immutable
class Company {
  final String id;
  final String businessName;
  final String fullname;
  final String email;
  final String category;
  final String? subCategory;
  final ContactInfo contactInfo;

  const Company({
    required this.id,
    required this.businessName,
    required this.fullname,
    required this.email,
    required this.category,
    this.subCategory,
    required this.contactInfo,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['_id'] ?? json['id'] ?? '',
      businessName: json['businessName'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      contactInfo: ContactInfo.fromJson(json['contactInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessName': businessName,
      'fullname': fullname,
      'email': email,
      'category': category,
      'subCategory': subCategory,
      'contactInfo': contactInfo.toJson(),
    };
  }
}

@immutable
class Wholesaler {
  final String id;
  final String businessName;
  final String fullname;
  final String email;
  final String category;
  final String? subCategory;
  final ContactInfo contactInfo;

  const Wholesaler({
    required this.id,
    required this.businessName,
    required this.fullname,
    required this.email,
    required this.category,
    this.subCategory,
    required this.contactInfo,
  });

  factory Wholesaler.fromJson(Map<String, dynamic> json) {
    return Wholesaler(
      id: json['_id'] ?? json['id'] ?? '',
      businessName: json['businessName'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      contactInfo: ContactInfo.fromJson(json['contactInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessName': businessName,
      'fullname': fullname,
      'email': email,
      'category': category,
      'subCategory': subCategory,
      'contactInfo': contactInfo.toJson(),
    };
  }
}

@immutable
class ServiceProvider {
  final String id;
  final String businessName;
  final String fullname;
  final String email;
  final String category;
  final String? subCategory;
  final ContactInfo contactInfo;

  const ServiceProvider({
    required this.id,
    required this.businessName,
    required this.fullname,
    required this.email,
    required this.category,
    this.subCategory,
    required this.contactInfo,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['_id'] ?? json['id'] ?? '',
      businessName: json['businessName'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      contactInfo: ContactInfo.fromJson(json['contactInfo'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'businessName': businessName,
      'fullname': fullname,
      'email': email,
      'category': category,
      'subCategory': subCategory,
      'contactInfo': contactInfo.toJson(),
    };
  }
}

@immutable
class ContactInfo {
  final String phone;
  final String? whatsApp;
  final String? website;
  final Address address;

  const ContactInfo({
    required this.phone,
    this.whatsApp,
    this.website,
    required this.address,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: json['phone'] ?? '',
      whatsApp: json['whatsApp'],
      website: json['website'],
      address: Address.fromJson(json['address'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'whatsApp': whatsApp,
      'website': website,
      'address': address.toJson(),
    };
  }
}

@immutable
class Address {
  final String street;
  final String city;
  final String state;
  final String country;
  final String? postalCode;

  const Address({
    required this.street,
    required this.city,
    required this.state,
    required this.country,
    this.postalCode,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      street: json['street'] ?? '',
      city: json['city'] ?? '',
      state: json['state'] ?? '',
      country: json['country'] ?? '',
      postalCode: json['postalCode'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'street': street,
      'city': city,
      'state': state,
      'country': country,
      'postalCode': postalCode,
    };
  }
}
