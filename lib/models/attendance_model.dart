import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceModel {
  final String attendanceId;
  final String schoolId;
  final String classId;
  final String studentId;
  final String date; // YYYY-MM-DD
  final String status; // 'present', 'absent', 'late'
  final String markedByTeacherId;
  final DateTime? timestamp;

  AttendanceModel({
    required this.attendanceId,
    required this.schoolId,
    required this.classId,
    required this.studentId,
    required this.date,
    required this.status,
    required this.markedByTeacherId,
    this.timestamp,
  });

  factory AttendanceModel.fromMap(Map<String, dynamic> map, String documentId) {
    return AttendanceModel(
      attendanceId: documentId,
      schoolId: map['schoolId'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      date: map['date'] ?? '',
      status: map['status'] ?? 'present',
      markedByTeacherId: map['markedByTeacherId'] ?? '',
      timestamp: map['timestamp'] != null ? (map['timestamp'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'studentId': studentId,
      'date': date,
      'status': status,
      'markedByTeacherId': markedByTeacherId,
      if (timestamp != null) 'timestamp': Timestamp.fromDate(timestamp!),
    };
  }
}
