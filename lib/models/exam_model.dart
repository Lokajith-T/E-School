import 'package:cloud_firestore/cloud_firestore.dart';

class ExamSubject {
  final String subjectId;
  final String subjectName;
  final DateTime examDate;
  final String startTime; // e.g., '10:00 AM'
  final String endTime;   // e.g., '12:00 PM'
  final int maxMarks;

  ExamSubject({
    required this.subjectId,
    required this.subjectName,
    required this.examDate,
    required this.startTime,
    required this.endTime,
    required this.maxMarks,
  });

  factory ExamSubject.fromMap(Map<String, dynamic> map) {
    return ExamSubject(
      subjectId: map['subjectId'] ?? '',
      subjectName: map['subjectName'] ?? '',
      examDate: (map['examDate'] as Timestamp).toDate(),
      startTime: map['startTime'] ?? '',
      endTime: map['endTime'] ?? '',
      maxMarks: map['maxMarks'] ?? 100,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'subjectId': subjectId,
      'subjectName': subjectName,
      'examDate': Timestamp.fromDate(examDate),
      'startTime': startTime,
      'endTime': endTime,
      'maxMarks': maxMarks,
    };
  }
}

class ExamModel {
  final String examId;
  final String schoolId;
  final String examName;
  final String academicYear;
  final String classId; // For simplicity, one exam doc per class
  final List<ExamSubject> subjects;
  final String instructions;
  final String status; // 'Draft', 'Published', 'Completed'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ExamModel({
    required this.examId,
    required this.schoolId,
    required this.examName,
    required this.academicYear,
    required this.classId,
    required this.subjects,
    this.instructions = '',
    this.status = 'Draft',
    this.createdAt,
    this.updatedAt,
  });

  factory ExamModel.fromMap(Map<String, dynamic> map, String documentId) {
    var list = map['subjects'] as List? ?? [];
    List<ExamSubject> parsedSubjects = list.map((e) => ExamSubject.fromMap(e as Map<String, dynamic>)).toList();

    return ExamModel(
      examId: documentId,
      schoolId: map['schoolId'] ?? '',
      examName: map['examName'] ?? '',
      academicYear: map['academicYear'] ?? '',
      classId: map['classId'] ?? '',
      subjects: parsedSubjects,
      instructions: map['instructions'] ?? '',
      status: map['status'] ?? 'Draft',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'examName': examName,
      'academicYear': academicYear,
      'classId': classId,
      'subjects': subjects.map((e) => e.toMap()).toList(),
      'instructions': instructions,
      'status': status,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
