import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/fee_model.dart';

class FeeService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add a new fee allocation
  Future<void> addFee(FeeModel fee) async {
    final data = fee.toMap();
    data['createdAt'] = FieldValue.serverTimestamp();
    await _firestore.collection('fees').add(data);
  }

  // Stream fees for a specific school (Admin View)
  Stream<List<FeeModel>> streamAllFees(String schoolId) {
    return _firestore
        .collection('fees')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => FeeModel.fromMap(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime); // Descending
      });
      return list;
    });
  }

  // Stream fees for a specific student (Parent/Student View)
  // Fees can be assigned to 'All' students in a class, or a specific student.
  Stream<List<FeeModel>> streamFeesForStudent(String schoolId, String classId, String studentId) {
    return _firestore
        .collection('fees')
        .where('schoolId', isEqualTo: schoolId)
        .snapshots()
        .map((snapshot) {
      final allFees = snapshot.docs
          .map((doc) => FeeModel.fromMap(doc.data(), doc.id))
          .toList();
          
      // Filter logically on the client since Firestore 'OR' queries can be complex
      final studentFees = allFees.where((fee) {
        // Fee assigned directly to this student
        if (fee.studentId == studentId) return true;
        // Fee assigned to the entire class
        if (fee.classId == classId && fee.studentId == 'All') return true;
        // Fee assigned to the entire school
        if (fee.classId == 'All' && fee.studentId == 'All') return true;
        
        return false;
      }).toList();
      
      studentFees.sort((a, b) => a.dueDate.compareTo(b.dueDate)); // Sort by due date
      return studentFees;
    });
  }

  // Delete a fee allocation
  Future<void> deleteFee(String feeId) async {
    await _firestore.collection('fees').doc(feeId).delete();
  }
}
