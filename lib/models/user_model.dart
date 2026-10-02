import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String role;
  final String? schoolId;
  final String? mobileNumber;
  final String status;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.email,
    required this.role,
    this.schoolId,
    this.mobileNumber,
    this.status = 'active',
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String documentId) {
    DateTime? parsedCreatedAt;
    if (map['createdAt'] != null) {
      if (map['createdAt'] is Timestamp) {
        parsedCreatedAt = (map['createdAt'] as Timestamp).toDate();
      } else if (map['createdAt'] is String) {
        parsedCreatedAt = DateTime.tryParse(map['createdAt']);
      } else if (map['createdAt'] is int) {
        parsedCreatedAt = DateTime.fromMillisecondsSinceEpoch(map['createdAt']);
      }
    }

    return UserModel(
      uid: documentId,
      email: map['email']?.toString() ?? '',
      role: map['role']?.toString() ?? 'student',
      schoolId: map['schoolId']?.toString(),
      mobileNumber: map['mobileNumber']?.toString(),
      status: map['status']?.toString() ?? 'active',
      createdAt: parsedCreatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'role': role,
      if (schoolId != null) 'schoolId': schoolId,
      if (mobileNumber != null) 'mobileNumber': mobileNumber,
      'status': status,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
