class ServiceProviderInfo {
  final String? status;
  final String? category;

  ServiceProviderInfo({this.status, this.category});

  factory ServiceProviderInfo.fromJson(Map<String, dynamic> json) {
    return ServiceProviderInfo(
      status: json['status'],
      category: json['category'],
    );
  }
}

class ServiceProvider {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String userType;
  final ServiceProviderInfo? serviceProviderInfo;
  final String? profileImage;

  ServiceProvider({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.userType,
    this.serviceProviderInfo,
    this.profileImage,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? json['businessName'] ?? '',
      email: json['email'] ?? '',
      phone: json['phone'] ?? '',
      userType: json['userType'] ?? '',
      profileImage: json['profileImage'],
      serviceProviderInfo: json['serviceProviderInfo'] != null
          ? ServiceProviderInfo.fromJson(json['serviceProviderInfo'])
          : null,
    );
  }
} 