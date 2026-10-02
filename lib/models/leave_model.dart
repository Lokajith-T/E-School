import 'package:cloud_firestore/cloud_firestore.dart';

class LeaveModel {
  final String leaveId;
  final String schoolId;
  final String classId;
  final String studentId;
  final String studentName;
  final DateTime fromDate;
  final DateTime toDate;
  final String reason;
  final String status; // 'Pending', 'Approved', 'Rejected'
  final DateTime? appliedAt;
  final String? handledBy; // Teacher name or ID

  LeaveModel({
    required this.leaveId,
    required this.schoolId,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.fromDate,
    required this.toDate,
    required this.reason,
    this.status = 'Pending',
    this.appliedAt,
    this.handledBy,
  });

  factory LeaveModel.fromMap(Map<String, dynamic> map, String documentId) {
    return LeaveModel(
      leaveId: documentId,
      schoolId: map['schoolId'] ?? '',
      classId: map['classId'] ?? '',
      studentId: map['studentId'] ?? '',
      studentName: map['studentName'] ?? '',
      fromDate: (map['fromDate'] as Timestamp).toDate(),
      toDate: (map['toDate'] as Timestamp).toDate(),
      reason: map['reason'] ?? '',
      status: map['status'] ?? 'Pending',
      appliedAt: map['appliedAt'] != null ? (map['appliedAt'] as Timestamp).toDate() : null,
      handledBy: map['handledBy'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'studentId': studentId,
      'studentName': studentName,
      'fromDate': Timestamp.fromDate(fromDate),
      'toDate': Timestamp.fromDate(toDate),
      'reason': reason,
      'status': status,
      if (appliedAt != null) 'appliedAt': Timestamp.fromDate(appliedAt!),
      if (handledBy != null) 'handledBy': handledBy,
    };
  }
}
