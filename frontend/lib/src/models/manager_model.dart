class Manager {
  final String id;
  final String fullName;
  final String email;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> rolesAccess;

  Manager({
    required this.id,
    required this.fullName,
    required this.email,
    required this.createdAt,
    required this.updatedAt,
    required this.rolesAccess,
  });

  factory Manager.fromJson(Map<String, dynamic> json) {
    return Manager(
      id: json['id'].toString(),
      fullName: json['fullName'],
      email: json['email'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      rolesAccess: List<String>.from(json['rolesAccess'] ?? []),
    );
  }
} 