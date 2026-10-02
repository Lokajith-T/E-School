import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherModel {
  final String teacherId;
  final String uid;
  final String schoolId;
  final String name;
  final String mobileNumber;
  final String? email;
  final String employeeId;
  final List<String> assignedClasses;
  final List<String> subjects;
  final String status;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TeacherModel({
    required this.teacherId,
    required this.uid,
    required this.schoolId,
    required this.name,
    required this.mobileNumber,
    this.email,
    required this.employeeId,
    required this.assignedClasses,
    required this.subjects,
    this.status = 'active',
    this.createdAt,
    this.updatedAt,
  });

  factory TeacherModel.fromMap(Map<String, dynamic> map, String documentId) {
    return TeacherModel(
      teacherId: documentId,
      uid: map['uid'] ?? '',
      schoolId: map['schoolId'] ?? '',
      name: map['name'] ?? '',
      mobileNumber: map['mobileNumber'] ?? '',
      email: map['email'],
      employeeId: map['employeeId'] ?? '',
      assignedClasses: List<String>.from(map['assignedClasses'] ?? []),
      subjects: List<String>.from(map['subjects'] ?? []),
      status: map['status'] ?? 'active',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'schoolId': schoolId,
      'name': name,
      'mobileNumber': mobileNumber,
      if (email != null) 'email': email,
      'employeeId': employeeId,
      'assignedClasses': assignedClasses,
      'subjects': subjects,
      'status': status,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
