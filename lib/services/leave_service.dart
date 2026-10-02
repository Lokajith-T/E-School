import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/leave_model.dart';
import 'firestore_service.dart';

class LeaveService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _collection = 'leaves';

  Future<void> submitLeaveRequest(LeaveModel leave) async {
    String docId = FirebaseFirestore.instance.collection(_collection).doc().id;
    LeaveModel newLeave = LeaveModel(
      leaveId: docId,
      schoolId: leave.schoolId,
      classId: leave.classId,
      studentId: leave.studentId,
      studentName: leave.studentName,
      fromDate: leave.fromDate,
      toDate: leave.toDate,
      reason: leave.reason,
      status: 'Pending',
      appliedAt: DateTime.now(),
    );
    await _firestoreService.setDocument(_collection, docId, newLeave.toMap());
  }

  Future<void> updateLeaveStatus(String leaveId, String status, String handledBy) async {
    await _firestoreService.updateDocument(_collection, leaveId, {
      'status': status,
      'handledBy': handledBy,
    });
  }

  Stream<List<LeaveModel>> streamStudentLeaves(String schoolId, String studentId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => LeaveModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          list.sort((a, b) => (b.appliedAt ?? DateTime.now()).compareTo(a.appliedAt ?? DateTime.now()));
          return list;
        });
  }

  Stream<List<LeaveModel>> streamClassLeaves(String schoolId, String classId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => LeaveModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          list.sort((a, b) => (b.appliedAt ?? DateTime.now()).compareTo(a.appliedAt ?? DateTime.now()));
          return list;
        });
  }
}
