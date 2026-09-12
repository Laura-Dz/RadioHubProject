import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffContext {
  final String userId;
  final String radioId;
  final String radioName;
  final String role; // 'host' | 'technician'
  final String displayName;

  StaffContext({
    required this.userId,
    required this.radioId,
    required this.radioName,
    required this.role,
    required this.displayName,
  });
}

class StaffContextService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<StaffContext?> load() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;

    final doc = await _db.collection('users').doc(uid).get();
    if (!doc.exists) return null;

    final d = doc.data()!;
    final radioId = d['radioId'] as String?;
    if (radioId == null) return null;

    // Fetch the radio profile
    final radioDoc = await _db.collection('radios').doc(radioId).get();
    final radioName = radioDoc.exists ? (radioDoc.data()?['name'] ?? 'Radio') : (d['radioName'] ?? 'Radio');

    return StaffContext(
      userId: uid,
      radioId: radioId,
      radioName: radioName,
      role: d['role'] ?? '',
      displayName: d['displayName'] ?? d['name'] ?? '',
    );
  }
}
