import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Add document
  Future<String> addDocument(String collectionPath, Map<String, dynamic> data) async {
    data['createdAt'] = FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    DocumentReference docRef = await _firestore.collection(collectionPath).add(data);
    return docRef.id;
  }

  // Set document (with custom ID)
  Future<void> setDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    data['createdAt'] = data['createdAt'] ?? FieldValue.serverTimestamp();
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(collectionPath).doc(documentId).set(data, SetOptions(merge: true));
  }

  // Update document
  Future<void> updateDocument(String collectionPath, String documentId, Map<String, dynamic> data) async {
    data['updatedAt'] = FieldValue.serverTimestamp();
    await _firestore.collection(collectionPath).doc(documentId).update(data);
  }

  // Get document
  Future<DocumentSnapshot> getDocument(String collectionPath, String documentId) async {
    return await _firestore.collection(collectionPath).doc(documentId).get();
  }

  // Delete/Deactivate document (Soft delete preferred)
  Future<void> deactivateDocument(String collectionPath, String documentId) async {
    await updateDocument(collectionPath, documentId, {'status': 'inactive'});
  }
  
  // Hard delete
  Future<void> deleteDocument(String collectionPath, String documentId) async {
    await _firestore.collection(collectionPath).doc(documentId).delete();
  }
  
  // Stream collection
  Stream<QuerySnapshot> streamCollection(String collectionPath, {
    String? schoolId,
    String? orderByField,
    bool descending = false,
  }) {
    Query query = _firestore.collection(collectionPath);
    if (schoolId != null) {
      query = query.where('schoolId', isEqualTo: schoolId);
    }
    if (orderByField != null) {
      query = query.orderBy(orderByField, descending: descending);
    }
    return query.snapshots();
  }

  // Generic query builder for specific where clauses
  Query getCollectionQuery(String collectionPath) {
    return _firestore.collection(collectionPath);
  }
}
