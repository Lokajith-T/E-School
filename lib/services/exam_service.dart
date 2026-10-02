import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/exam_model.dart';
import 'firestore_service.dart';

class ExamService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _collection = 'exams';

  Future<void> addExam(ExamModel exam) async {
    // Check if exam already exists for this class
    final existing = await _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: exam.schoolId)
        .where('classId', isEqualTo: exam.classId)
        .where('examName', isEqualTo: exam.examName)
        .where('academicYear', isEqualTo: exam.academicYear)
        .get();

    if (existing.docs.isNotEmpty) {
      throw Exception('This exam already exists for this class in the specified academic year.');
    }

    String docId = FirebaseFirestore.instance.collection(_collection).doc().id;
    ExamModel newExam = ExamModel(
      examId: docId,
      schoolId: exam.schoolId,
      examName: exam.examName,
      academicYear: exam.academicYear,
      classId: exam.classId,
      subjects: exam.subjects,
      instructions: exam.instructions,
      status: exam.status,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.setDocument(_collection, docId, newExam.toMap());
  }

  Future<void> updateExam(ExamModel exam) async {
    ExamModel updatedExam = ExamModel(
      examId: exam.examId,
      schoolId: exam.schoolId,
      examName: exam.examName,
      academicYear: exam.academicYear,
      classId: exam.classId,
      subjects: exam.subjects,
      instructions: exam.instructions,
      status: exam.status,
      createdAt: exam.createdAt,
      updatedAt: DateTime.now(),
    );
    await _firestoreService.updateDocument(_collection, exam.examId, updatedExam.toMap());
  }

  Future<void> deleteExam(String examId) async {
    await _firestoreService.deleteDocument(_collection, examId);
  }

  Stream<List<ExamModel>> streamExams(String schoolId) {
    return _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ExamModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
