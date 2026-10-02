import 'package:cloud_firestore/cloud_firestore.dart';

class FeeModel {
  final String feeId;
  final String schoolId;
  final String classId; // Can be a specific class doc ID, or 'All'
  final String studentId; // Can be a specific student ID, or 'All'
  final String feeTitle;
  final double amount;
  final DateTime dueDate;
  final DateTime? createdAt;

  FeeModel({
    required this.feeId,
    required this.schoolId,
    required this.classId,
    required this.studentId,
    required this.feeTitle,
    required this.amount,
    required this.dueDate,
    this.createdAt,
  });

  factory FeeModel.fromMap(Map<String, dynamic> map, String documentId) {
    return FeeModel(
      feeId: documentId,
      schoolId: map['schoolId'] ?? '',
      classId: map['classId'] ?? 'All',
      studentId: map['studentId'] ?? 'All',
      feeTitle: map['feeTitle'] ?? '',
      amount: (map['amount'] ?? 0.0).toDouble(),
      dueDate: (map['dueDate'] as Timestamp).toDate(),
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'classId': classId,
      'studentId': studentId,
      'feeTitle': feeTitle,
      'amount': amount,
      'dueDate': Timestamp.fromDate(dueDate),
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
    };
  }
}
