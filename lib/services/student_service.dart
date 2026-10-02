import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_model.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class StudentService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _collection = 'students';

  Future<String> addStudent(StudentModel student) async {
    QuerySnapshot query = await _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: student.schoolId)
        .where('admissionNumber', isEqualTo: student.admissionNumber)
        .get();
        
    if (query.docs.isNotEmpty) {
      throw Exception('A student with this admission number already exists.');
    }
    
    // We use the uid as document ID if provided. Otherwise, provision Auth account to get UID.
    String studentDocId = student.uid;
    if (studentDocId.isEmpty) {
      if (student.phone.isNotEmpty) {
        studentDocId = await AuthService().provisionUserAuth(student.phone, role: 'student');
      } else {
        studentDocId = FirebaseFirestore.instance.collection(_collection).doc().id;
      }
    }
    
    // Provision Student User for SIM Login
    if (student.phone.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(studentDocId).set({
        'uid': studentDocId,
        'role': 'student',
        'schoolId': student.schoolId,
        'mobileNumber': student.phone,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Provision Parent Users for SIM Login
    for (String parentId in student.parentIds) {
      // The parentId passed in here is going to be their mobile number for simplicity during creation,
      // or we can handle it in the AddStudentScreen. We'll assume AddStudentScreen provisions the parent
      // and passes the actual parent UIDs in `parentIds`.
    }

    // Save Student Model
    Map<String, dynamic> studentData = student.toMap();
    studentData['uid'] = studentDocId;
    await _firestoreService.setDocument(_collection, studentDocId, studentData);
    return studentDocId;
  }

  Future<void> deleteStudentData(StudentModel student) async {
    // Delete student document
    await _firestoreService.deleteDocument(_collection, student.studentId);
    // Delete student user account
    await _firestoreService.deleteDocument('users', student.uid);
  }

  Future<StudentModel?> getStudent(String studentId) async {
    DocumentSnapshot doc = await _firestoreService.getDocument(_collection, studentId);
    if (doc.exists && doc.data() != null) {
      return StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateStudent(String studentId, Map<String, dynamic> data) async {
    await _firestoreService.updateDocument(_collection, studentId, data);
  }

  Future<void> deactivateStudent(String studentId) async {
    await _firestoreService.deactivateDocument(_collection, studentId);
  }

  Stream<List<StudentModel>> streamStudents(String schoolId) {
    return _firestoreService.streamCollection(_collection, schoolId: schoolId)
        .map((snapshot) => snapshot.docs
            .map((doc) => StudentModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
