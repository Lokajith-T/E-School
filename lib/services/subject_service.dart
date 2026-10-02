import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/subject_model.dart';
import 'firestore_service.dart';

class SubjectService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _collection = 'subjects';

  Future<String> addSubject(SubjectModel subject) async {
    // Check for duplicate subject in the same class
    QuerySnapshot query = await _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: subject.schoolId)
        .where('classId', isEqualTo: subject.classId)
        .where('subjectName', isEqualTo: subject.subjectName)
        .get();
        
    if (query.docs.isNotEmpty) {
      throw Exception('This subject already exists for this class.');
    }
    
    String docId = FirebaseFirestore.instance.collection(_collection).doc().id;
    
    SubjectModel finalSubject = SubjectModel(
      subjectId: docId,
      schoolId: subject.schoolId,
      classId: subject.classId,
      subjectName: subject.subjectName,
      teacherId: subject.teacherId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.setDocument(_collection, docId, finalSubject.toMap());
    return docId;
  }

  Future<void> deleteSubject(String subjectId) async {
    await _firestoreService.deleteDocument(_collection, subjectId);
  }

  Future<void> updateSubject(String subjectId, Map<String, dynamic> data) async {
    await _firestoreService.updateDocument(_collection, subjectId, data);
  }

  Stream<List<SubjectModel>> streamSubjectsByClass(String schoolId, String classId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubjectModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
  Stream<List<SubjectModel>> streamSubjectsByTeacher(String schoolId, String teacherId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => SubjectModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
