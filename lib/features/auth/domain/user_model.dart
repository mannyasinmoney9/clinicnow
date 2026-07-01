enum UserRole { patient, staff, admin }

class UserModel {
  const UserModel({
    required this.userId,
    required this.fullName,
    required this.email,
    required this.role,
    required this.token,
  });

  final int userId;
  final String fullName;
  final String email;
  final UserRole role;
  final String token;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        userId: (json['userId'] as num).toInt(),
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        role: _roleFrom(json['role'] as String? ?? 'PATIENT'),
        token: json['token'] as String? ?? '',
      );

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'fullName': fullName,
        'email': email,
        'role': role.name.toUpperCase(),
        'token': token,
      };

  static UserRole _roleFrom(String s) {
    switch (s.toUpperCase()) {
      case 'STAFF':
        return UserRole.staff;
      case 'ADMIN':
        return UserRole.admin;
      default:
        return UserRole.patient;
    }
  }

  bool get isStaffOrAdmin => role == UserRole.staff || role == UserRole.admin;
  String get firstName => fullName.split(' ').first;
}
