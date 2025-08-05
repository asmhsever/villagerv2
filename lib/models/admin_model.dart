class AdminModel {
  final int adminId;
  final String username;
  final String password;

  AdminModel({
    required this.adminId,
    required this.username,
    required this.password,
  });

  // Convert from JSON
  factory AdminModel.fromJson(Map<String, dynamic> json) {
    return AdminModel(
      adminId: json['admin_id'] ?? 0,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
    );
  }

  // Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'admin_id': adminId,
      'username': username,
      'password': password,
    };
  }

  // Copy with method for updating specific fields
  AdminModel copyWith({
    int? adminId,
    String? username,
    String? password,
  }) {
    return AdminModel(
      adminId: adminId ?? this.adminId,
      username: username ?? this.username,
      password: password ?? this.password,
    );
  }

  // Override toString for debugging
  @override
  String toString() {
    return 'AdminModel(adminId: $adminId, username: $username)';
  }

  // Override equality operators
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminModel &&
        other.adminId == adminId &&
        other.username == username;
  }

  @override
  int get hashCode => adminId.hashCode ^ username.hashCode;
}