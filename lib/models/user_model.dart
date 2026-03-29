

class UserModel {
  final String uid;
  final String role; // "passenger", "driver", "admin"
  final String name;
  final String email;

  UserModel({
    required this.uid,
    required this.role,
    required this.name,
    required this.email,
  });

  factory UserModel.fromMap(Map<String, dynamic> data, String documentId) {
    return UserModel(
      uid: documentId,
      role: data['role'] ?? 'passenger',
      name: data['name'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'role': role,
      'name': name,
      'email': email,
    };
  }
}
