// lib/models/user.dart

class User {
  final String id;
  final String fullName;
  final String email;
  final String role;
  final String? studentId; // ← THÊM
  final String?
      studentClass; // ← THÊM ("class" là từ khóa reserved nên dùng studentClass)

  User({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.studentId,
    this.studentClass,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['_id'] ?? json['id'],
      fullName: json['fullName'],
      email: json['email'],
      role: json['role'],
      studentId: json['studentId'],
      studentClass: json['class'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'fullName': fullName,
      'email': email,
      'role': role,
      'studentId': studentId,
      'class': studentClass,
    };
  }
}
