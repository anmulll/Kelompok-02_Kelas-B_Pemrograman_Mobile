import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  student('student'),
  admin('admin');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String? raw) {
    return UserRole.values.firstWhere(
      (role) => role.value == raw,
      orElse: () => UserRole.student,
    );
  }
}

class UserModel {
  const UserModel({
    required this.uid,
    required this.name,
    required this.email,
    this.phone,
    this.role = UserRole.student,
    this.photoUrl,
    this.isActive = true,
    required this.createdAt,
    required this.updatedAt,
  });

  final String uid;
  final String name;
  final String email;
  final String? phone;
  final UserRole role;
  final String? photoUrl;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isAdmin => role == UserRole.admin;

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return UserModel(
      uid: (map['uid'] as String?) ?? docId ?? '',
      name: (map['name'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      phone: map['phone'] as String?,
      role: UserRole.fromString(map['role'] as String?),
      photoUrl: map['photoUrl'] as String?,
      isActive: (map['isActive'] as bool?) ?? true,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt']),
    );
  }

  /// Catatan keamanan (BR-002): role tidak boleh diubah ke admin dari sisi klien.
  Map<String, dynamic> toClientProfileUpdateMap() {
    return {
      'name': name,
      'phone': phone,
      'photoUrl': photoUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  static DateTime _parseDateTime(Object? value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.fromMillisecondsSinceEpoch(0);
    }
    return DateTime.fromMillisecondsSinceEpoch(0);
  }
}
