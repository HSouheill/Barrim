import 'company_model.dart';
import 'service_provider_model.dart';

class EnrichedCompany {
  final Company company;
  final String salespersonName;
  final String salespersonEmail;

  EnrichedCompany({
    required this.company,
    required this.salespersonName,
    required this.salespersonEmail,
  });

  factory EnrichedCompany.fromJson(Map<String, dynamic> json) {
    return EnrichedCompany(
      company: Company.fromJson(json['company']),
      salespersonName: json['salesperson']?['fullName'] ?? '',
      salespersonEmail: json['salesperson']?['email'] ?? '',
    );
  }
}

class EnrichedServiceProvider {
  final ServiceProvider serviceProvider;
  final String salespersonName;
  final String salespersonEmail;

  EnrichedServiceProvider({
    required this.serviceProvider,
    required this.salespersonName,
    required this.salespersonEmail,
  });

  factory EnrichedServiceProvider.fromJson(Map<String, dynamic> json) {
    return EnrichedServiceProvider(
      serviceProvider: ServiceProvider.fromJson(json['serviceProvider']),
      salespersonName: json['salesperson']?['fullName'] ?? '',
      salespersonEmail: json['salesperson']?['email'] ?? '',
    );
  }
}

class EnrichedWholesaler {
  final dynamic wholesaler;
  final String salespersonName;
  final String salespersonEmail;

  EnrichedWholesaler({
    required this.wholesaler,
    required this.salespersonName,
    required this.salespersonEmail,
  });

  factory EnrichedWholesaler.fromJson(Map<String, dynamic> json) {
    return EnrichedWholesaler(
      wholesaler: json['wholesaler'],
      salespersonName: json['salesperson']?['fullName'] ?? '',
      salespersonEmail: json['salesperson']?['email'] ?? '',
    );
  }
} 