import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marks_model.dart';
import 'firestore_service.dart';

class MarksService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _collection = 'marks';

  Future<void> saveMarksBatch(List<MarksModel> records) async {
    final batch = FirebaseFirestore.instance.batch();
    final colRef = FirebaseFirestore.instance.collection(_collection);

    for (var record in records) {
      // Use composite ID so we can overwrite an existing mark for the same student/subject/exam
      final docId = '${record.studentId}_${record.subjectId}_${record.examName.replaceAll(" ", "_")}';
      final docRef = colRef.doc(docId);
      
      batch.set(docRef, record.toMap(), SetOptions(merge: true));
    }

    await batch.commit();
  }

  Stream<List<MarksModel>> streamMarksByClassAndExam(String schoolId, String classId, String subjectId, String examName) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .where('subjectId', isEqualTo: subjectId)
        .where('examName', isEqualTo: examName)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarksModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Stream<List<MarksModel>> streamStudentMarks(String schoolId, String studentId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('studentId', isEqualTo: studentId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => MarksModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
