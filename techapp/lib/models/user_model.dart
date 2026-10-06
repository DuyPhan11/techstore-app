class UserModel {
  final int id;
  final String email;
  final String? phone;
  final String fullName;
  final String? avatarUrl;
  final String? status;
  final List<String> roles;

  UserModel({
    required this.id,
    required this.email,
    this.phone,
    required this.fullName,
    this.avatarUrl,
    this.status,
    required this.roles,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      email: json['email'] ?? '',
      phone: json['phone'],
      fullName: json['fullName'] ?? '',
      avatarUrl: json['avatarUrl'],
      status: json['status']?.toString(),
      roles: (json['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'status': status,
      'roles': roles,
    };
  }

  bool get isAdmin => roles.contains('ROLE_ADMIN');
  bool get isStaff => roles.contains('ROLE_STAFF');
}

class AuthResponseModel {
  final String token;
  final String tokenType;
  final int? expiresIn;
  final UserModel user;

  AuthResponseModel({
    required this.token,
    required this.tokenType,
    this.expiresIn,
    required this.user,
  });

  factory AuthResponseModel.fromJson(Map<String, dynamic> json) {
    return AuthResponseModel(
      token: json['token'] ?? '',
      tokenType: json['tokenType'] ?? 'Bearer',
      expiresIn: json['expiresIn'],
      user: UserModel.fromJson(json['user'] ?? {}),
    );
  }
}
