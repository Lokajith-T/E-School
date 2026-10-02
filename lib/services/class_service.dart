import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/class_model.dart';
import 'firestore_service.dart';

class ClassService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _collection = 'classes';

  Future<String> addClass(ClassModel classModel) async {
    // Check for duplicate class name + section in the same school
    QuerySnapshot query = await _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: classModel.schoolId)
        .where('className', isEqualTo: classModel.className)
        .where('section', isEqualTo: classModel.section)
        .get();
        
    if (query.docs.isNotEmpty) {
      throw Exception('This class and section already exists.');
    }
    
    String docId = FirebaseFirestore.instance.collection(_collection).doc().id;
    
    ClassModel finalClass = ClassModel(
      classId: docId,
      schoolId: classModel.schoolId,
      className: classModel.className,
      section: classModel.section,
      classTeacherId: classModel.classTeacherId,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.setDocument(_collection, docId, finalClass.toMap());
    return docId;
  }

  Future<void> deleteClass(String classId) async {
    await _firestoreService.deleteDocument(_collection, classId);
  }

  Future<void> updateClass(String classId, Map<String, dynamic> data) async {
    await _firestoreService.updateDocument(_collection, classId, data);
  }

  Stream<List<ClassModel>> streamClasses(String schoolId) {
    return _firestoreService.streamCollection(_collection, schoolId: schoolId)
        .map((snapshot) => snapshot.docs
            .map((doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<List<ClassModel>> getClassesOnce(String schoolId) async {
    final snapshot = await _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .get();
    return snapshot.docs
        .map((doc) => ClassModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
