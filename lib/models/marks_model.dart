import 'package:cloud_firestore/cloud_firestore.dart';

class MarksModel {
  final String markId;
  final String schoolId;
  final String classId;
  final String subjectId;
  final String studentId;
  final String examName;
  final int marksObtained;
  final int maxMarks;
  final String teacherId;
  final String status;
  final DateTime? createdAt;

  MarksModel({
    required this.markId,
    required this.schoolId,
    required this.classId,
    required this.subjectId,
    required this.studentId,
    required this.examName,
    required this.marksObtained,
    required this.maxMarks,
    required this.teacherId,
    this.status = 'Draft',
    this.createdAt,
  });

  factory MarksModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MarksModel(
      markId: documentId,
      schoolId: map['schoolId'] ?? '',
      classId: map['classId'] ?? '',
      subjectId: map['subjectId'] ?? '',
      studentId: map['studentId'] ?? '',
      examName: map['examName'] ?? '',
      marksObtained: map['marksObtained'] ?? 0,
      maxMarks: map['maxMarks'] ?? 100,
      teacherId: map['teacherId'] ?? '',
      status: map['status'] ?? 'Draft',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'subjectId': subjectId,
      'studentId': studentId,
      'examName': examName,
      'marksObtained': marksObtained,
      'maxMarks': maxMarks,
      'teacherId': teacherId,
      'status': status,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
