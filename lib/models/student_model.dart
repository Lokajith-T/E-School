import 'package:cloud_firestore/cloud_firestore.dart';

class StudentModel {
  final String studentId;
  final String uid;
  final String schoolId;
  final String admissionNumber;
  final String name;
  final String classId;
  final String section;
  final List<String> parentIds;
  final String email;
  final String phone;
  final String profileImageUrl;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  StudentModel({
    required this.studentId,
    required this.uid,
    required this.schoolId,
    required this.admissionNumber,
    required this.name,
    required this.classId,
    required this.section,
    required this.parentIds,
    required this.email,
    this.phone = '',
    this.profileImageUrl = '',
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory StudentModel.fromMap(Map<String, dynamic> map, String documentId) {
    return StudentModel(
      studentId: documentId,
      uid: map['uid'] ?? '',
      schoolId: map['schoolId'] ?? '',
      admissionNumber: map['admissionNumber'] ?? '',
      name: map['name'] ?? '',
      classId: map['classId'] ?? '',
      section: map['section'] ?? '',
      parentIds: List<String>.from(map['parentIds'] ?? []),
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      profileImageUrl: map['profileImageUrl'] ?? '',
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'schoolId': schoolId,
      'admissionNumber': admissionNumber,
      'name': name,
      'classId': classId,
      'section': section,
      'parentIds': parentIds,
      'email': email,
      'phone': phone,
      'profileImageUrl': profileImageUrl,
      'status': status,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
