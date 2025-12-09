class User {
  final String fullName;
  final String studentId;
  final String email;
  final String password;

  User({
    required this.fullName,
    required this.studentId,
    required this.email,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      "full_name": fullName,
      "student_id": studentId,
      "email": email,
      "password": password,
    };
  }
}
