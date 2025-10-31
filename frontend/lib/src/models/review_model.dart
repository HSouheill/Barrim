class Review {
  final String id;
  final String serviceProviderId;
  final String userId;
  final int rating;
  final String comment;
  final bool isVerified;
  final String? mediaURL;
  final String? thumbnailURL;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields that might be populated
  final String? userName;
  final String? serviceProviderName;

  Review({
    required this.id,
    required this.serviceProviderId,
    required this.userId,
    required this.rating,
    required this.comment,
    required this.isVerified,
    this.mediaURL,
    this.thumbnailURL,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.serviceProviderName,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    return Review(
      id: json['_id'] ?? json['id'] ?? '',
      serviceProviderId: json['serviceProviderId'] ?? '',
      userId: json['userId'] ?? '',
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      isVerified: json['isVerified'] ?? false,
      mediaURL: json['mediaURL'],
      thumbnailURL: json['thumbnailURL'],
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      userName: json['userName'],
      serviceProviderName: json['serviceProviderName'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'serviceProviderId': serviceProviderId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'isVerified': isVerified,
      'mediaURL': mediaURL,
      'thumbnailURL': thumbnailURL,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userName': userName,
      'serviceProviderName': serviceProviderName,
    };
  }

  Review copyWith({
    String? id,
    String? serviceProviderId,
    String? userId,
    int? rating,
    String? comment,
    bool? isVerified,
    String? mediaURL,
    String? thumbnailURL,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? serviceProviderName,
  }) {
    return Review(
      id: id ?? this.id,
      serviceProviderId: serviceProviderId ?? this.serviceProviderId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      isVerified: isVerified ?? this.isVerified,
      mediaURL: mediaURL ?? this.mediaURL,
      thumbnailURL: thumbnailURL ?? this.thumbnailURL,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      serviceProviderName: serviceProviderName ?? this.serviceProviderName,
    );
  }
}
