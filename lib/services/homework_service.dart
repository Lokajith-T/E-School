import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/homework_model.dart';
import 'firestore_service.dart';

class HomeworkService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _collection = 'homework';

  Future<void> addHomework(HomeworkModel homework) async {
    String docId = FirebaseFirestore.instance.collection(_collection).doc().id;
    
    HomeworkModel finalHomework = HomeworkModel(
      homeworkId: docId,
      schoolId: homework.schoolId,
      classId: homework.classId,
      subjectId: homework.subjectId,
      teacherId: homework.teacherId,
      title: homework.title,
      description: homework.description,
      assignedDate: homework.assignedDate,
      dueDate: homework.dueDate,
      createdAt: DateTime.now(),
    );

    await _firestoreService.setDocument(_collection, docId, finalHomework.toMap());
  }

  Future<void> deleteHomework(String homeworkId) async {
    await _firestoreService.deleteDocument(_collection, homeworkId);
  }

  Stream<List<HomeworkModel>> streamHomeworkByTeacher(String schoolId, String teacherId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('teacherId', isEqualTo: teacherId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => HomeworkModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          list.sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }

  Stream<List<HomeworkModel>> streamHomeworkByClass(String schoolId, String classId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .where('classId', isEqualTo: classId)
        .snapshots()
        .map((snapshot) {
          final list = snapshot.docs
              .map((doc) => HomeworkModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
              .toList();
          list.sort((a, b) {
            final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
          return list;
        });
  }
}
