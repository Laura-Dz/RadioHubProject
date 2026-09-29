import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RadioAdminCredentials {
  final String uid;
  final String email;
  final String radioId;
  final String radioName;
  RadioAdminCredentials({required this.uid, required this.email, required this.radioId, required this.radioName});
}

class RadioAdminAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<RadioAdminCredentials> login({required String email, required String password}) async {
    final cred = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final uid = cred.user!.uid;
    final userDoc = await _db.collection('users').doc(uid).get();
    String radioId = '';
    String radioName = 'My Radio';
    if (userDoc.exists) {
      final data = userDoc.data()!;
      radioId = data['radioId'] ?? '';
      radioName = data['radioName'] ?? data['displayName'] ?? radioName;
      final role = (data['role'] ?? '').toString().toLowerCase();
      if (role.isNotEmpty && role != 'radioadmin' && role != 'radio_admin' && role != 'director' && role != 'admin') {
        await _auth.signOut();
        throw Exception('Access denied. This account is not a Radio Admin.');
      }
    }

    // If radioId is missing from userDoc, resolve from radios collection where adminId == uid
    if (radioId.isEmpty) {
      final radioQuery = await _db.collection('radios').where('adminId', isEqualTo: uid).limit(1).get();
      if (radioQuery.docs.isNotEmpty) {
        radioId = radioQuery.docs.first.id;
        radioName = radioQuery.docs.first.data()['name'] ?? radioName;
      }
    }

    // Resolve radio name from the radio document itself if available
    if (radioId.isNotEmpty) {
      try {
        final rDoc = await _db.collection('radios').doc(radioId).get();
        if (rDoc.exists) {
          radioName = rDoc.data()?['name'] ?? radioName;
        }
      } catch (_) {}
    }

    return RadioAdminCredentials(uid: uid, email: email, radioId: radioId, radioName: radioName);
  }

  Future<void> sendPasswordReset(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  User? get currentUser => _auth.currentUser;
}
