import 'dart:convert';

class Withdrawal {
  final String? id;
  final String userId;
  final String userType; // "salesperson" or "sales_manager"
  final double amount;
  final String status; // "pending", "approved", "rejected"
  final String? adminId;
  final String? adminNote;
  final DateTime createdAt;
  final DateTime? processedAt;

  Withdrawal({
    this.id,
    required this.userId,
    required this.userType,
    required this.amount,
    required this.status,
    this.adminId,
    this.adminNote,
    required this.createdAt,
    this.processedAt,
  });

  factory Withdrawal.fromJson(Map<String, dynamic> json) {
    return Withdrawal(
      id: json['id'] ?? json['_id'],
      userId: json['userId'] ?? json['user_id'] ?? '',
      userType: json['userType'] ?? json['user_type'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      status: json['status'] ?? 'pending',
      adminId: json['adminId'] ?? json['admin_id'],
      adminNote: json['adminNote'] ?? json['admin_note'],
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt']) ?? DateTime.now()
          : DateTime.now(),
      processedAt: json['processedAt'] != null
          ? DateTime.tryParse(json['processedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'userId': userId,
      'userType': userType,
      'amount': amount,
      'status': status,
      if (adminId != null) 'adminId': adminId,
      if (adminNote != null) 'adminNote': adminNote,
      'createdAt': createdAt.toIso8601String(),
      if (processedAt != null) 'processedAt': processedAt!.toIso8601String(),
    };
  }

  Withdrawal copyWith({
    String? id,
    String? userId,
    String? userType,
    double? amount,
    String? status,
    String? adminId,
    String? adminNote,
    DateTime? createdAt,
    DateTime? processedAt,
  }) {
    return Withdrawal(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      adminId: adminId ?? this.adminId,
      adminNote: adminNote ?? this.adminNote,
      createdAt: createdAt ?? this.createdAt,
      processedAt: processedAt ?? this.processedAt,
    );
  }
}

class EnrichedWithdrawal {
  final Withdrawal withdrawal;
  final Map<String, dynamic> user;

  EnrichedWithdrawal({
    required this.withdrawal,
    required this.user,
  });

  factory EnrichedWithdrawal.fromJson(Map<String, dynamic> json) {
    return EnrichedWithdrawal(
      withdrawal: Withdrawal.fromJson(json['withdrawal'] ?? {}),
      user: json['user'] ?? {},
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'withdrawal': withdrawal.toJson(),
      'user': user,
    };
  }
}

class WithdrawalApprovalRequest {
  final String adminNote;

  WithdrawalApprovalRequest({required this.adminNote});

  Map<String, dynamic> toJson() {
    return {
      'adminNote': adminNote,
    };
  }
}

class WithdrawalRejectionRequest {
  final String adminNote;

  WithdrawalRejectionRequest({required this.adminNote});

  Map<String, dynamic> toJson() {
    return {
      'adminNote': adminNote,
    };
  }
}
