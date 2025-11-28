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
    // Helper function to parse DateTime safely
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        final str = value.toString();
        // Handle ISO 8601 format
        if (str.contains('T') || str.contains('Z')) {
          return DateTime.parse(str);
        }
        // Handle MongoDB date format
        if (value is Map && value['\$date'] != null) {
          return DateTime.fromMillisecondsSinceEpoch(value['\$date'] as int);
        }
        // Try parsing as string
        return DateTime.parse(str);
      } catch (e) {
        print('Error parsing DateTime: $value, error: $e');
        return null;
      }
    }
    
    // Helper function to extract string from ObjectID or value
    String _extractString(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      if (value is String) return value;
      if (value is Map) {
        return value['\$oid']?.toString() ?? value.toString();
      }
      return value.toString();
    }
    
    return Booking(
      id: _extractString(json['_id'] ?? json['id'], ''),
      userId: _extractString(json['userId'], ''),
      serviceProviderId: _extractString(json['serviceProviderId'], ''),
      serviceId: _extractString(json['serviceId'] ?? '', ''), // Default to empty string if missing
      bookingDate: _parseDateTime(json['bookingDate']) ?? DateTime.now(),
      status: json['status']?.toString() ?? 'pending',
      amount: (json['amount'] ?? 0.0).toDouble(),
      notes: json['notes']?.toString() ?? json['details']?.toString(), // Handle 'details' field as well
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      userName: json['userName']?.toString(),
      serviceProviderName: json['serviceProviderName']?.toString(),
      serviceName: json['serviceName']?.toString(),
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
