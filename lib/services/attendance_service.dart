import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/attendance_model.dart';
import 'firestore_service.dart';

class AttendanceService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _collection = 'attendance';

  /// Saves a batch of attendance records. Uses studentId_date as custom docId to prevent duplicates.
  Future<void> saveAttendanceBatch(List<AttendanceModel> records) async {
    final batch = FirebaseFirestore.instance.batch();
    final colRef = FirebaseFirestore.instance.collection(_collection);

    for (var record in records) {
      // Create a predictable document ID: studentId_date
      final docId = '${record.studentId}_${record.date}';
      final docRef = colRef.doc(docId);
      
      batch.set(docRef, record.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Stream<List<AttendanceModel>> streamAttendanceByClassAndDate(String schoolId, String classId, String date) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .where('date', isEqualTo: date)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<AttendanceModel>> streamStudentAttendance(String schoolId, String studentId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AttendanceModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
