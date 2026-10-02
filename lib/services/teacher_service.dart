import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_model.dart';
import 'firestore_service.dart';
import 'auth_service.dart';

class TeacherService {
  final FirestoreService _firestoreService = FirestoreService();
  final String _collection = 'teachers';

  Future<String> addTeacher(TeacherModel teacher) async {
    QuerySnapshot query = await _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: teacher.schoolId)
        .where('mobileNumber', isEqualTo: teacher.mobileNumber)
        .get();
        
    if (query.docs.isNotEmpty) {
      throw Exception('A teacher with this mobile number already exists.');
    }
    
    // Check employee ID
    QuerySnapshot idQuery = await _firestoreService.getCollectionQuery(_collection)
        .where('schoolId', isEqualTo: teacher.schoolId)
        .where('employeeId', isEqualTo: teacher.employeeId)
        .get();
        
    if (idQuery.docs.isNotEmpty) {
      throw Exception('A teacher with this employee ID already exists in this school.');
    }

    String teacherDocId = teacher.uid;
    if (teacherDocId.isEmpty) {
      if (teacher.mobileNumber.isNotEmpty) {
        teacherDocId = await AuthService().provisionUserAuth(teacher.mobileNumber, role: 'teacher');
      } else {
        teacherDocId = FirebaseFirestore.instance.collection(_collection).doc().id;
      }
    }
    
    // Provision Teacher User for SIM Login
    if (teacher.mobileNumber.isNotEmpty) {
      await FirebaseFirestore.instance.collection('users').doc(teacherDocId).set({
        'uid': teacherDocId,
        'role': 'teacher',
        'schoolId': teacher.schoolId,
        'mobileNumber': teacher.mobileNumber,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Save Teacher Model
    TeacherModel finalTeacher = TeacherModel(
      teacherId: teacher.teacherId.isEmpty ? teacherDocId : teacher.teacherId,
      uid: teacherDocId,
      schoolId: teacher.schoolId,
      name: teacher.name,
      mobileNumber: teacher.mobileNumber,
      email: teacher.email,
      employeeId: teacher.employeeId,
      assignedClasses: teacher.assignedClasses,
      subjects: teacher.subjects,
      status: teacher.status,
      createdAt: teacher.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
    );

    await _firestoreService.setDocument(_collection, teacherDocId, finalTeacher.toMap());
    return teacherDocId;
  }

  Future<void> deleteTeacherData(TeacherModel teacher) async {
    await _firestoreService.deleteDocument(_collection, teacher.teacherId);
    await _firestoreService.deleteDocument('users', teacher.uid);
  }

  Future<TeacherModel?> getTeacher(String teacherId) async {
    DocumentSnapshot doc = await _firestoreService.getDocument(_collection, teacherId);
    if (doc.exists && doc.data() != null) {
      return TeacherModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
    }
    return null;
  }

  Future<void> updateTeacher(String teacherId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestoreService.updateDocument(_collection, teacherId, data);
    
    // Also update mobile number or status in users collection if changed
    if (data.containsKey('status') || data.containsKey('mobileNumber')) {
      Map<String, dynamic> userUpdates = {};
      if (data.containsKey('status')) userUpdates['status'] = data['status'];
      if (data.containsKey('mobileNumber')) userUpdates['mobileNumber'] = data['mobileNumber'];
      
      TeacherModel? teacher = await getTeacher(teacherId);
      if (teacher != null && teacher.uid.isNotEmpty) {
        await _firestoreService.updateDocument('users', teacher.uid, userUpdates);
      }
    }
  }

  Future<void> deactivateTeacher(String teacherId) async {
    await updateTeacher(teacherId, {'status': 'inactive'});
  }
  
  Future<void> activateTeacher(String teacherId) async {
    await updateTeacher(teacherId, {'status': 'active'});
  }

  Stream<List<TeacherModel>> streamTeachers(String schoolId) {
    return _firestoreService.streamCollection(_collection, schoolId: schoolId)
        .map((snapshot) => snapshot.docs
            .map((doc) => TeacherModel.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }
}
