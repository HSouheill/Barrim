class AdminWallet {
  final double totalIncome;
  final double totalCommissions;
  final double netProfit;
  final Map<String, dynamic> incomeBreakdown;
  final Map<String, dynamic> commissionBreakdown;
  final DateTime lastUpdated;

  AdminWallet({
    required this.totalIncome,
    required this.totalCommissions,
    required this.netProfit,
    required this.incomeBreakdown,
    required this.commissionBreakdown,
    required this.lastUpdated,
  });

  factory AdminWallet.fromJson(Map<String, dynamic> json) {
    return AdminWallet(
      totalIncome: (json['totalIncome'] ?? 0).toDouble(),
      totalCommissions: (json['totalCommissions'] ?? 0).toDouble(),
      netProfit: (json['netProfit'] ?? 0).toDouble(),
      incomeBreakdown: json['incomeBreakdown'] ?? {},
      commissionBreakdown: json['commissionBreakdown'] ?? {},
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.tryParse(json['lastUpdated']) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalIncome': totalIncome,
      'totalCommissions': totalCommissions,
      'netProfit': netProfit,
      'incomeBreakdown': incomeBreakdown,
      'commissionBreakdown': commissionBreakdown,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }
}

class IncomeBreakdown {
  final double income;
  final String? error;

  IncomeBreakdown({
    required this.income,
    this.error,
  });

  factory IncomeBreakdown.fromJson(Map<String, dynamic> json) {
    return IncomeBreakdown(
      income: (json['income'] ?? 0).toDouble(),
      error: json['error'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'income': income,
      'error': error,
    };
  }
}

class CommissionBreakdown {
  final double commission;
  final double percentage;

  CommissionBreakdown({
    required this.commission,
    required this.percentage,
  });

  factory CommissionBreakdown.fromJson(Map<String, dynamic> json) {
    return CommissionBreakdown(
      commission: (json['commission'] ?? 0).toDouble(),
      percentage: (json['percentage'] ?? 0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'commission': commission,
      'percentage': percentage,
    };
  }
}
