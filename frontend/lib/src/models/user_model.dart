import 'dart:convert';

class User {
  final String id;
  final String email;
  final String fullName;
  final String userType;
  final bool isActive;
  final DateTime? lastActivityAt;
  final String? dateOfBirth;
  final String? gender;
  final String? phone;
  final int points;
  final List<String>? referrals;
  final String? referralCode;
  final List<String>? interestedDeals;
  final Location? location;
  final ServiceProviderInfo? serviceProviderInfo;
  final String? logoPath;
  final String? profilePic;
  final List<String>? favoriteBranches;
  final List<String>? favoriteServiceProviders;
  final String? googleId;
  final String? googleEmail;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userType,
    required this.isActive,
    this.lastActivityAt,
    this.dateOfBirth,
    this.gender,
    this.phone,
    required this.points,
    this.referrals,
    this.referralCode,
    this.interestedDeals,
    this.location,
    this.serviceProviderInfo,
    this.logoPath,
    this.profilePic,
    this.favoriteBranches,
    this.favoriteServiceProviders,
    this.googleId,
    this.googleEmail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      fullName: json['fullName'] ?? '',
      userType: json['userType'] ?? '',
      isActive: json['isActive'] ?? false,
      lastActivityAt: json['lastActivityAt'] != null
          ? DateTime.parse(json['lastActivityAt'])
          : null,
      dateOfBirth: json['dateOfBirth'],
      gender: json['gender'],
      phone: json['phone'],
      points: json['points'] ?? 0,
      referrals: json['referrals'] != null
          ? List<String>.from(json['referrals'] as List)
          : null,
      referralCode: json['referralCode'],
      interestedDeals: json['interestedDeals'] != null
          ? List<String>.from(json['interestedDeals'] as List)
          : null,
      location: json['location'] != null
          ? Location.fromJson(json['location'] as Map<String, dynamic>)
          : null,
      serviceProviderInfo: json['serviceProviderInfo'] != null
          ? ServiceProviderInfo.fromJson(json['serviceProviderInfo'] as Map<String, dynamic>)
          : null,
      logoPath: json['logoPath'],
      profilePic: json['profilePic'],
      favoriteBranches: json['favoriteBranches'] != null
          ? List<String>.from(json['favoriteBranches'] as List)
          : null,
      favoriteServiceProviders: json['favoriteServiceProviders'] != null
          ? List<String>.from(json['favoriteServiceProviders'] as List)
          : null,
      googleId: json['googleId'],
      googleEmail: json['googleEmail'],
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
      'fullName': fullName,
      'userType': userType,
      'isActive': isActive,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
      'dateOfBirth': dateOfBirth,
      'gender': gender,
      'phone': phone,
      'points': points,
      'referralCode': referralCode,
      'location': location?.toJson(),
      'serviceProviderInfo': serviceProviderInfo?.toJson(),
      'logoPath': logoPath,
      'profilePic': profilePic,
      'googleId': googleId,
      'googleEmail': googleEmail,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class Location {
  final String city;
  final String country;
  final String district;
  final String street;
  final String postalCode;
  final double lat;
  final double lng;
  final bool allowed;

  Location({
    required this.city,
    required this.country,
    required this.district,
    required this.street,
    required this.postalCode,
    required this.lat,
    required this.lng,
    required this.allowed,
  });

  factory Location.fromJson(Map<String, dynamic> json) {
    return Location(
      city: json['city'] ?? '',
      country: json['country'] ?? '',
      district: json['district'] ?? '',
      street: json['street'] ?? '',
      postalCode: json['postalCode'] ?? '',
      lat: json['lat']?.toDouble() ?? 0.0,
      lng: json['lng']?.toDouble() ?? 0.0,
      allowed: json['allowed'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'city': city,
      'country': country,
      'district': district,
      'street': street,
      'postalCode': postalCode,
      'lat': lat,
      'lng': lng,
      'allowed': allowed,
    };
  }
}

class SocialLinks {
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? linkedin;
  final String? website;

  SocialLinks({
    this.facebook,
    this.instagram,
    this.twitter,
    this.linkedin,
    this.website,
  });

  factory SocialLinks.fromJson(Map<String, dynamic> json) {
    return SocialLinks(
      facebook: json['facebook'],
      instagram: json['instagram'],
      twitter: json['twitter'],
      linkedin: json['linkedin'],
      website: json['website'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facebook': facebook,
      'instagram': instagram,
      'twitter': twitter,
      'linkedin': linkedin,
      'website': website,
    };
  }
}

class ServiceProviderInfo {
  final String serviceType;
  final String? customServiceType;
  final String? description;
  final dynamic yearsExperience;
  final String? profilePhoto;
  final List<String>? availableHours;
  final List<String>? availableDays;
  final bool? applyToAllMonths;
  final List<String>? availableWeekdays;
  final int rating;
  final String? referralCode;
  final int points;
  final List<String>? referredServiceProviders;
  final SocialLinks? socialLinks;

  ServiceProviderInfo({
    required this.serviceType,
    this.customServiceType,
    this.description,
    this.yearsExperience,
    this.profilePhoto,
    this.availableHours,
    this.availableDays,
    this.applyToAllMonths,
    this.availableWeekdays,
    required this.rating,
    this.referralCode,
    required this.points,
    this.referredServiceProviders,
    this.socialLinks,
  });

  factory ServiceProviderInfo.fromJson(Map<String, dynamic> json) {
    return ServiceProviderInfo(
      serviceType: json['serviceType'] ?? '',
      customServiceType: json['customServiceType'],
      description: json['description'],
      yearsExperience: json['yearsExperience'],
      profilePhoto: json['profilePhoto'],
      availableHours: json['availableHours'] != null
          ? List<String>.from(json['availableHours'])
          : null,
      availableDays: json['availableDays'] != null
          ? List<String>.from(json['availableDays'])
          : null,
      applyToAllMonths: json['applyToAllMonths'],
      availableWeekdays: json['availableWeekdays'] != null
          ? List<String>.from(json['availableWeekdays'])
          : null,
      rating: json['rating'] ?? 0,
      referralCode: json['referralCode'],
      points: json['points'] ?? 0,
      referredServiceProviders: json['referredServiceProviders'] != null
          ? List<String>.from(json['referredServiceProviders'])
          : null,
      socialLinks: json['socialLinks'] != null
          ? SocialLinks.fromJson(json['socialLinks'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceType': serviceType,
      'customServiceType': customServiceType,
      'description': description,
      'yearsExperience': yearsExperience,
      'profilePhoto': profilePhoto,
      'availableHours': availableHours,
      'availableDays': availableDays,
      'applyToAllMonths': applyToAllMonths,
      'availableWeekdays': availableWeekdays,
      'rating': rating,
      'referralCode': referralCode,
      'points': points,
      'socialLinks': socialLinks?.toJson(),
    };
  }
}

class ActiveUser {
  final String id;
  final String email;
  final String fullName;
  final String userType;
  final DateTime? lastActivity;
  final String timeConnected;
  final bool isActive;
  final String? branchStatus;
  final String? salesManagerEmail;
  final String? salespersonEmail;
  final String? status;

  ActiveUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.userType,
    this.lastActivity,
    required this.timeConnected,
    required this.isActive,
    this.branchStatus,
    this.salesManagerEmail,
    this.salespersonEmail,
    this.status,
  });

  factory ActiveUser.fromJson(Map<String, dynamic> json) {
    return ActiveUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      fullName: json['fullName']?.toString() ?? '',
      userType: json['userType']?.toString() ?? '',
      lastActivity: json['lastActivity'] != null
          ? DateTime.tryParse(json['lastActivity'].toString())
          : null,
      timeConnected: json['timeConnected']?.toString() ?? 'unknown',
      isActive: json['isActive'] ?? false,
      branchStatus: json['branchStatus']?.toString(),
      salesManagerEmail: json['salesManagerEmail']?.toString(),
      salespersonEmail: json['salespersonEmail']?.toString(),
      status: json['status']?.toString(),
    );
  }
}