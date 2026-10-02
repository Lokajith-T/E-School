import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/timetable_model.dart';
import 'firestore_service.dart';

class TimetableService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _collection = 'timetable';

  Future<void> addTimetableSlot(TimetableModel slot) async {
    String docId = FirebaseFirestore.instance.collection(_collection).doc().id;
    
    TimetableModel finalSlot = TimetableModel(
      timetableId: docId,
      schoolId: slot.schoolId,
      classId: slot.classId,
      dayOfWeek: slot.dayOfWeek,
      subjectId: slot.subjectId,
      teacherId: slot.teacherId,
      periodNumber: slot.periodNumber,
    );

    await _firestoreService.setDocument(_collection, docId, finalSlot.toMap());
  }

  Future<void> deleteTimetableSlot(String timetableId) async {
    await _firestoreService.deleteDocument(_collection, timetableId);
  }

  Stream<List<TimetableModel>> streamTimetableByTeacher(String schoolId, String teacherId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TimetableModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<TimetableModel>> streamTimetableByClass(String schoolId, String classId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TimetableModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
