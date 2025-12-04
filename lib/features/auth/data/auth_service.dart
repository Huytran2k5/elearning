import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../core/constants/app_constants.dart';
import 'user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Getter to get current user
  User? get currentUser => _auth.currentUser;

  // Main login function
  Future<UserModel> signIn(String inputEmail, String password) async {
    String finalEmail = inputEmail.trim();
    String finalPassword = password;

    // Keep old Admin logic as is
    if (inputEmail.trim() == 'admin' && password == 'admin') {
      finalEmail = 'admin@elearning.com';
      finalPassword = 'adminPassword123';
    }

    try {
      // 1. Auth login
      UserCredential userCredential = await _auth.signInWithEmailAndPassword(
        email: finalEmail,
        password: finalPassword,
      );

      String authUid = userCredential.user!.uid;

      // 2. METHOD 1: Find by ID (Priority)
      DocumentSnapshot userDoc = await _firestore
          .collection(AppConstants.collUsers)
          .doc(authUid)
          .get();

      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }

      // 3. METHOD 2: (NEW) If ID not found, search by Email
      // This is a fallback for CSV Import cases
      final queryByEmail = await _firestore
          .collection(AppConstants.collUsers)
          .where('email', isEqualTo: finalEmail)
          .limit(1)
          .get();

      if (queryByEmail.docs.isNotEmpty) {
        return UserModel.fromFirestore(queryByEmail.docs.first);
      }

      // 4. If both methods fail
      throw Exception("User record not found in Database!");

    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception("Incorrect username or password.");
      }
      throw Exception(e.message);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // Function to check if emails already exist (Used for CSV Import)
  Future<List<String>> checkExistingEmails(List<String> emails) async {
    if (emails.isEmpty) return [];

    // Firestore limits 'whereIn' to max 10 elements, so for long lists need to split
    // Here's a simple demo, in practice need batch splitting algorithm
    final List<String> existing = [];

    // Simple way: Get all users to check (acceptable for small scale)
    // Optimal way: Use Cloud Function, but here we use client-side cache
    QuerySnapshot snapshot = await _firestore.collection(AppConstants.collUsers).get();

    for (var doc in snapshot.docs) {
      String dbEmail = doc.get('email') as String;
      if (emails.contains(dbEmail)) {
        existing.add(dbEmail);
      }
    }
    return existing;
  }

  // Create student users in Firestore (Batch write for speed)
  Future<void> createStudentBatch(List<UserModel> students) async {
    WriteBatch batch = _firestore.batch();

    for (var student in students) {
      // Use email as temporary ID or UUID if preferred
      // Here we use random UUID for document ID
      DocumentReference docRef = _firestore.collection(AppConstants.collUsers).doc();

      // Update ID into model
      Map<String, dynamic> data = student.toMap();
      // Default role STUDENT
      data['role'] = AppConstants.roleStudent;
      data['createdAt'] = FieldValue.serverTimestamp();

      batch.set(docRef, data);
    }

    await batch.commit();
  }
}