// lib/models/company_model.dart
class Company {
  final String id;
  final String userId;
  final String businessName;
  final String email;
  final String fullname;
  final String category;
  final String? subCategory;
  final String? referralCode;
  final List<String>? referrals;
  final int points;
  final ContactInfo contactInfo;
  final SocialMedia? socialMedia;
  final String? logoUrl;
  final double balance;
  final List<Branch>? branches;
  final DateTime createdAt;
  final DateTime updatedAt;

  Company({
    required this.id,
    required this.userId,
    required this.businessName,
    required this.fullname,
    required this.email,
    required this.category,
    this.subCategory,
    this.referralCode,
    this.referrals,
    required this.points,
    required this.contactInfo,
    this.socialMedia,
    this.logoUrl,
    required this.balance,
    this.branches,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      businessName: json['businessName'] ?? '',
      fullname: json['fullname'] ?? '',
      email: json['email'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      referralCode: json['referralCode'],
      referrals: json['referrals'] != null
          ? List<String>.from(json['referrals'])
          : null,
      points: json['points'] ?? 0,
      contactInfo: ContactInfo.fromJson(json['contactInfo'] ?? {}),
      socialMedia: json['socialMedia'] != null
          ? SocialMedia.fromJson(json['socialMedia'])
          : null,
      logoUrl: json['logoUrl'],
      balance: (json['balance'] ?? 0).toDouble(),
      branches: json['branches'] != null
          ? (json['branches'] as List).map((b) => Branch.fromJson(b)).toList()
          : null,
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
      'userId': userId,
      'businessName': businessName,
      'fullname': fullname,
      'email': email,
      'category': category,
      'subCategory': subCategory,
      'referralCode': referralCode,
      'referrals': referrals,
      'points': points,
      'contactInfo': contactInfo.toJson(),
      'socialMedia': socialMedia?.toJson(),
      'logoUrl': logoUrl,
      'balance': balance,
      'branches': branches?.map((b) => b.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}

class ContactInfo {
  final String phone;
  final String? whatsApp;
  final String? website;
  final Address address;

  ContactInfo({
    required this.phone,
    this.whatsApp,
    this.website,
    required this.address,
  });

  factory ContactInfo.fromJson(Map<String, dynamic> json) {
    return ContactInfo(
      phone: json['phone'] ?? '',
      whatsApp: json['whatsapp'],
      website: json['website'],
      address: Address.fromJson(json['address'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'phone': phone,
      'whatsapp': whatsApp,
      'website': website,
      'address': address.toJson(),
    };
  }
}

class SocialMedia {
  final String? facebook;
  final String? instagram;

  SocialMedia({
    this.facebook,
    this.instagram,
  });

  factory SocialMedia.fromJson(Map<String, dynamic> json) {
    return SocialMedia(
      facebook: json['facebook'],
      instagram: json['instagram'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'facebook': facebook,
      'instagram': instagram,
    };
  }
}

class Address {
  final String country;
  final String district;
  final String city;
  final String street;
  final String postalCode;
  final double lat;
  final double lng;

  Address({
    required this.country,
    required this.district,
    required this.city,
    required this.street,
    required this.postalCode,
    required this.lat,
    required this.lng,
  });

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      country: json['country'] ?? '',
      district: json['district'] ?? '',
      city: json['city'] ?? '',
      street: json['street'] ?? '',
      postalCode: json['postalCode'] ?? '',
      lat: (json['lat'] ?? 0).toDouble(),
      lng: (json['lng'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'country': country,
      'district': district,
      'city': city,
      'street': street,
      'postalCode': postalCode,
      'lat': lat,
      'lng': lng,
    };
  }
}

class Branch {
  final String id;
  final String name;
  final Address location;
  final String phone;
  final String category;
  final String? subCategory;
  final String? description;
  final List<String> images;
  final List<String>? videos;
  final double? costPerCustomer;
  final DateTime createdAt;
  final DateTime updatedAt;

  Branch({
    required this.id,
    required this.name,
    required this.location,
    required this.phone,
    required this.category,
    this.subCategory,
    this.description,
    required this.images,
    this.videos,
    this.costPerCustomer,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      location: Address.fromJson(json['location'] ?? {}),
      phone: json['phone'] ?? '',
      category: json['category'] ?? '',
      subCategory: json['subCategory'],
      description: json['description'],
      images: json['images'] != null
          ? List<String>.from(json['images'])
          : [],
      videos: json['videos'] != null
          ? List<String>.from(json['videos'])
          : null,
      costPerCustomer: json['costPerCustomer'] != null
          ? (json['costPerCustomer']).toDouble()
          : null,
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
      'location': location.toJson(),
      'phone': phone,
      'category': category,
      'subCategory': subCategory,
      'description': description,
      'images': images,
      'videos': videos,
      'costPerCustomer': costPerCustomer,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}