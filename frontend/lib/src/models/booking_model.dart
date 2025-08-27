class Booking {
  final String id;
  final String userId;
  final String serviceProviderId;
  final String serviceId;
  final DateTime bookingDate;
  final String status; // pending, confirmed, completed, cancelled
  final double amount;
  final String? notes;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields that might be populated
  final String? userName;
  final String? serviceProviderName;
  final String? serviceName;

  Booking({
    required this.id,
    required this.userId,
    required this.serviceProviderId,
    required this.serviceId,
    required this.bookingDate,
    required this.status,
    required this.amount,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.serviceProviderName,
    this.serviceName,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['_id'] ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      serviceProviderId: json['serviceProviderId'] ?? '',
      serviceId: json['serviceId'] ?? '',
      bookingDate: json['bookingDate'] != null 
          ? DateTime.parse(json['bookingDate'].toString())
          : DateTime.now(),
      status: json['status'] ?? 'pending',
      amount: (json['amount'] ?? 0.0).toDouble(),
      notes: json['notes'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      userName: json['userName'],
      serviceProviderName: json['serviceProviderName'],
      serviceName: json['serviceName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'serviceProviderId': serviceProviderId,
      'serviceId': serviceId,
      'bookingDate': bookingDate.toIso8601String(),
      'status': status,
      'amount': amount,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userName': userName,
      'serviceProviderName': serviceProviderName,
      'serviceName': serviceName,
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? serviceProviderId,
    String? serviceId,
    DateTime? bookingDate,
    String? status,
    double? amount,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? serviceProviderName,
    String? serviceName,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      serviceId: serviceId ?? this.serviceId,
      bookingDate: bookingDate ?? this.bookingDate,
      status: status ?? this.status,
      amount: amount ?? this.amount,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      serviceProviderName: serviceProviderName ?? this.serviceProviderName,
      serviceName: serviceName ?? this.serviceName,
    );
  }
}
