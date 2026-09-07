import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../models/user_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  Future<UserModel> loginWithEmail(String email, String password) async {
    try {
      final userCredential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Login failed');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) throw Exception('User not found in database');

      return UserModel.fromFirestore(doc.data()!, user.uid);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserModel> registerWithEmail(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = userCredential.user;
      if (user == null) throw Exception('Registration failed');

      final userModel = UserModel(
        id: user.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
        isVerified: user.emailVerified,
      );

      await _firestore.collection('users').doc(user.uid).set(
        userModel.toFirestore(),
      );

      return userModel;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserModel> signInAnonymously() async {
    try {
      final userCredential = await _auth.signInAnonymously();
      final user = userCredential.user;
      if (user == null) throw Exception('Guest login failed');

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        return UserModel.fromFirestore(doc.data()!, user.uid);
      }

      final guestUser = UserModel(
        id: user.uid,
        email: 'guest_${user.uid.substring(0, 8)}@temp.com',
        displayName: 'Guest User',
        createdAt: DateTime.now(),
        isGuest: true,
      );

      await _firestore.collection('users').doc(user.uid).set(
        guestUser.toFirestore(),
      );

      return guestUser;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<UserModel?> getCurrentUser() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('users').doc(user.uid).get();
    if (!doc.exists) return null;

    return UserModel.fromFirestore(doc.data()!, user.uid);
  }

  Future<List<Map<String, dynamic>>> getActiveShows() async {
    final snapshot = await _firestore
        .collection('shows')
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => doc.data()).toList();
  }

  Future<String?> getEncryptionKey(String showId) async {
    final doc = await _firestore.collection('shows').doc(showId).get();
    if (!doc.exists) return null;
    return doc.data()?['encryptionKey'];
  }

  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return Exception('No user found with this email');
      case 'wrong-password':
        return Exception('Incorrect password');
      case 'email-already-in-use':
        return Exception('Email already registered');
      case 'invalid-email':
        return Exception('Invalid email address');
      case 'weak-password':
        return Exception('Password is too weak');
      case 'network-request-failed':
        return Exception('Network error. Check your connection');
      default:
        return Exception(e.message ?? 'Authentication failed');
    }
  }
}
