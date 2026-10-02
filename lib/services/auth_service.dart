import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  Future<UserModel?> signIn(String identifier, String password) async {
    try {
      UserCredential credential = await _auth.signInWithEmailAndPassword(
        email: identifier.trim(),
        password: password,
      );
      
      if (credential.user != null) {
        UserModel? userModel = await getUserData(credential.user!.uid);
        if (userModel == null) {
          await signOut();
          throw Exception("User profile not found in database. Please contact the administrator.");
        }
        if (userModel.status != 'active') {
          await signOut();
          throw Exception("Account is deactivated.");
        }
        return userModel;
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> verifyUserByPhone(String mobileNumber, String role) async {
    try {
      // 1. Try the new role-prefixed derived email (supports shared family numbers)
      String derivedEmail = '${role.toLowerCase()}_$mobileNumber@eschool.local';
      
      UserCredential credential;
      try {
        credential = await _auth.signInWithEmailAndPassword(
          email: derivedEmail,
          password: mobileNumber,
        );
      } on FirebaseAuthException catch (e) {
        if (e.code == 'user-not-found' || e.code == 'invalid-credential') {
          // 2. Fallback to the old non-prefixed email for backward compatibility
          String oldDerivedEmail = '$mobileNumber@eschool.local';
          credential = await _auth.signInWithEmailAndPassword(
            email: oldDerivedEmail,
            password: mobileNumber,
          );
        } else {
          rethrow;
        }
      }
      
      if (credential.user != null) {
        UserModel? userModel = await getUserData(credential.user!.uid);
        if (userModel == null) {
          await signOut();
          throw Exception("This mobile number is not registered. Please contact your school administrator.");
        }
        if (userModel.status != 'active') {
          await signOut();
          throw Exception("Account is deactivated.");
        }
        return userModel;
      }
      return null;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("This mobile number is not registered. Please contact your school administrator.");
      }
      throw Exception(e.message ?? "Authentication failed.");
    } catch (e) {
      rethrow;
    }
  }

  /// Securely provisions a new user in Firebase Auth without logging out the Admin
  /// Returns the newly generated Auth UID.
  Future<String> provisionUserAuth(String mobileNumber, {String role = ''}) async {
    String derivedEmail = role.isNotEmpty 
        ? '${role.toLowerCase()}_$mobileNumber@eschool.local' 
        : '$mobileNumber@eschool.local';
    
    // Create a temporary Firebase app instance to avoid signing out the current Admin
    FirebaseApp tempApp = await Firebase.initializeApp(
      name: 'tempAuth_${DateTime.now().millisecondsSinceEpoch}', 
      options: Firebase.app().options
    );
    
    try {
      UserCredential cred = await FirebaseAuth.instanceFor(app: tempApp).createUserWithEmailAndPassword(
        email: derivedEmail,
        password: mobileNumber,
      );
      return cred.user!.uid;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        // The auth account exists but might have been deleted from Firestore.
        // We can just log in to recover its UID and re-link it to the new Firestore record!
        try {
          UserCredential existingCred = await FirebaseAuth.instanceFor(app: tempApp).signInWithEmailAndPassword(
            email: derivedEmail,
            password: mobileNumber,
          );
          return existingCred.user!.uid;
        } catch (innerE) {
          throw Exception('A user with this mobile number already exists and recovery failed.');
        }
      }
      throw Exception('Failed to provision auth: ${e.message}');
    } finally {
      await tempApp.delete();
    }
  }

  Future<UserModel?> getUserData(String uid) async {
    try {
      DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
      
      if (!doc.exists) {
        print('Diagnostic: No document found in users collection with ID $uid');
        return null;
      }
      if (doc.data() == null) {
        print('Diagnostic: Document $uid exists but has no data');
        return null;
      }
      if (doc.id != uid) {
        print('Diagnostic: Document ID mismatch. Requested $uid but got ${doc.id}');
        return null;
      }

      try {
        return UserModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } catch (e) {
        print('Diagnostic: Error parsing UserModel for $uid: $e');
        return null;
      }
    } catch (e) {
      print('Diagnostic: Firestore read error for user $uid: $e');
      if (e is FirebaseException && e.code == 'permission-denied') {
        throw Exception("Permission denied. Check Firestore security rules.");
      }
      return null;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
