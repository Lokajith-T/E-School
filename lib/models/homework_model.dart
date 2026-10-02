import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkModel {
  final String homeworkId;
  final String schoolId;
  final String classId;
  final String subjectId;
  final String teacherId;
  final String title;
  final String description;
  final DateTime assignedDate;
  final DateTime dueDate;
  final DateTime? createdAt;

  HomeworkModel({
    required this.homeworkId,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.teacherId,
    required this.title,
    required this.description,
    required this.assignedDate,
    required this.dueDate,
    this.createdAt,
  });

  factory HomeworkModel.fromMap(Map<String, dynamic> map, String documentId) {
    return HomeworkModel(
      homeworkId: documentId,
      schoolId: map['schoolId'] ?? '',
      classId: map['classId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      teacherId: map['teacherId'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      assignedDate: (map['assignedDate'] as Timestamp).toDate(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'subjectId': subjectId,
      'teacherId': teacherId,
      'title': title,
      'description': description,
      'assignedDate': Timestamp.fromDate(assignedDate),
      'dueDate': Timestamp.fromDate(dueDate),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
