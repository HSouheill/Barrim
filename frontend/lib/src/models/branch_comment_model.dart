class BranchComment {
  final String id;
  final String branchId;
  final String userId;
  final int rating;
  final String comment;
  final List<BranchCommentReply>? replies;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Additional fields that might be populated
  final String? userName;
  final String? userEmail;
  final String? userPhone;
  final String? branchName;
  final String? branchType; // "company" or "wholesaler"
  final String? companyName;
  final String? companyId;
  final String? wholesalerName;
  final String? wholesalerId;

  BranchComment({
    required this.id,
    required this.branchId,
    required this.userId,
    required this.rating,
    required this.comment,
    this.replies,
    required this.createdAt,
    required this.updatedAt,
    this.userName,
    this.userEmail,
    this.userPhone,
    this.branchName,
    this.branchType,
    this.companyName,
    this.companyId,
    this.wholesalerName,
    this.wholesalerId,
  });

  factory BranchComment.fromJson(Map<String, dynamic> json) {
    // Helper function to parse DateTime safely
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        String str;
        try {
          str = value.toString();
        } catch (e) {
          print('Error converting value to string: $value, error: $e');
          return null;
        }
        if (str.contains('T') || str.contains('Z')) {
          return DateTime.parse(str);
        }
        if (value is Map && value['\$date'] != null) {
          return DateTime.fromMillisecondsSinceEpoch(value['\$date'] as int);
        }
        return DateTime.parse(str);
      } catch (e) {
        print('Error parsing DateTime: $value, error: $e');
        return null;
      }
    }
    
    // Helper function to extract string from ObjectID or value
    String _extractString(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      try {
        if (value is String) return value;
        if (value is Map) {
          final oid = value['\$oid'];
          if (oid != null) {
            return oid.toString();
          }
          final id = value['_id'];
          if (id != null) {
            return id.toString();
          }
          return value.toString();
        }
        return value.toString();
      } catch (e) {
        print('Error extracting string from value: $value, error: $e');
        return defaultValue;
      }
    }

    // Parse replies if they exist
    List<BranchCommentReply>? parsedReplies;
    if (json['replies'] != null && json['replies'] is List) {
      parsedReplies = (json['replies'] as List)
          .map((reply) => BranchCommentReply.fromJson(reply as Map<String, dynamic>))
          .toList();
    }

    return BranchComment(
      id: _extractString(json['_id'] ?? json['id'], ''),
      branchId: _extractString(json['branchId'], ''),
      userId: _extractString(json['userId'], ''),
      rating: json['rating'] ?? 0,
      comment: json['comment'] ?? '',
      replies: parsedReplies,
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
      updatedAt: _parseDateTime(json['updatedAt']) ?? DateTime.now(),
      userName: json['userName']?.toString(),
      userEmail: json['userEmail']?.toString(),
      userPhone: json['userPhone']?.toString(),
      branchName: json['branchName']?.toString(),
      branchType: json['branchType']?.toString(),
      companyName: json['companyName']?.toString(),
      companyId: json['companyId']?.toString(),
      wholesalerName: json['wholesalerName']?.toString(),
      wholesalerId: json['wholesalerId']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'branchId': branchId,
      'userId': userId,
      'rating': rating,
      'comment': comment,
      'replies': replies?.map((reply) => reply.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'branchName': branchName,
      'branchType': branchType,
      'companyName': companyName,
      'companyId': companyId,
      'wholesalerName': wholesalerName,
      'wholesalerId': wholesalerId,
    };
  }

  BranchComment copyWith({
    String? id,
    String? branchId,
    String? userId,
    int? rating,
    String? comment,
    List<BranchCommentReply>? replies,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? branchName,
    String? branchType,
    String? companyName,
    String? companyId,
    String? wholesalerName,
    String? wholesalerId,
  }) {
    return BranchComment(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      userId: userId ?? this.userId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      replies: replies ?? this.replies,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      branchName: branchName ?? this.branchName,
      branchType: branchType ?? this.branchType,
      companyName: companyName ?? this.companyName,
      companyId: companyId ?? this.companyId,
      wholesalerName: wholesalerName ?? this.wholesalerName,
      wholesalerId: wholesalerId ?? this.wholesalerId,
    );
  }
}

class BranchCommentReply {
  final String id;
  final String comment;
  final String? repliedBy; // Admin or branch manager ID
  final String? repliedByName;
  final DateTime createdAt;

  BranchCommentReply({
    required this.id,
    required this.comment,
    this.repliedBy,
    this.repliedByName,
    required this.createdAt,
  });

  factory BranchCommentReply.fromJson(Map<String, dynamic> json) {
    DateTime? _parseDateTime(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      try {
        String str;
        try {
          str = value.toString();
        } catch (e) {
          print('Error converting value to string: $value, error: $e');
          return null;
        }
        if (str.contains('T') || str.contains('Z')) {
          return DateTime.parse(str);
        }
        if (value is Map && value['\$date'] != null) {
          return DateTime.fromMillisecondsSinceEpoch(value['\$date'] as int);
        }
        return DateTime.parse(str);
      } catch (e) {
        print('Error parsing DateTime: $value, error: $e');
        return null;
      }
    }

    String _extractString(dynamic value, String defaultValue) {
      if (value == null) return defaultValue;
      try {
        if (value is String) return value;
        if (value is Map) {
          final oid = value['\$oid'];
          if (oid != null) {
            return oid.toString();
          }
          final id = value['_id'];
          if (id != null) {
            return id.toString();
          }
          return value.toString();
        }
        return value.toString();
      } catch (e) {
        print('Error extracting string from value: $value, error: $e');
        return defaultValue;
      }
    }

    return BranchCommentReply(
      id: _extractString(json['_id'] ?? json['id'], ''),
      comment: json['comment'] ?? '',
      repliedBy: json['repliedBy']?.toString(),
      repliedByName: json['repliedByName']?.toString(),
      createdAt: _parseDateTime(json['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'comment': comment,
      'repliedBy': repliedBy,
      'repliedByName': repliedByName,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

