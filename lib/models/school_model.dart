import 'package:cloud_firestore/cloud_firestore.dart';

class SchoolModel {
  final String schoolId;
  final String name;
  final String address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SchoolModel({
    required this.schoolId,
    required this.name,
    required this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory SchoolModel.fromMap(Map<String, dynamic> map, String documentId) {
    return SchoolModel(
      schoolId: documentId,
      name: map['name'] ?? '',
      address: map['address'] ?? '',
      createdAt: map['createdAt'] != null ? (map['createdAt'] as Timestamp).toDate() : null,
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'schoolId': schoolId,
      'name': name,
      'address': address,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
    };
  }
}
