class UserModel {
  final int userId;
  final String username;
  final String password;
  final String role;

  UserModel({
    required this.userId,
    required this.username,
    required this.password,
    required this.role,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      userId: json['user_id'] ?? 0,
      username: json['username'] ?? '',
      password: json['password'] ?? '',
      role: json['role'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'username': username,
      'password': password,
      'role': role,
    };
  }
}
