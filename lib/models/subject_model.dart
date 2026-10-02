import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  final String subjectId;
  final String schoolId;
  final String classId;
  final String subjectName;
  final String? teacherId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubjectModel({
    required this.subjectId,
    required this.schoolId,
    required this.classId,
    required this.subjectName,
    this.teacherId,
    this.createdAt,
    this.updatedAt,
  });

  factory SubjectModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SubjectModel(
      subjectId: documentId,
      schoolId: map['schoolId'] ?? '',
      classId: map['classId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      teacherId: map['teacherId'],
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'subjectName': subjectName,
      if (teacherId != null) 'teacherId': teacherId,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
