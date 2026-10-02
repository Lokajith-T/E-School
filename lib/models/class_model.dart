import 'package:cloud_firestore/cloud_firestore.dart';

class ClassModel {
  final String classId;
  final String schoolId;
  final String className;
  final String section;
  final String? classTeacherId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ClassModel({
    required this.classId,
    required this.schoolId,
    required this.className,
    required this.section,
    this.classTeacherId,
    this.createdAt,
    this.updatedAt,
  });

  factory ClassModel.fromMap(Map<String, dynamic> map, String documentId) {
    return ClassModel(
      classId: documentId,
      schoolId: map['schoolId'] ?? '',
      className: map['className'] ?? '',
      section: map['section'] ?? '',
      classTeacherId: map['classTeacherId'],
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'className': className,
      'section': section,
      if (classTeacherId != null) 'classTeacherId': classTeacherId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
