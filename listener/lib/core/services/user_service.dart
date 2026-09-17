import 'dart:async';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../models/user_profile.dart';
import '../models/user_preferences.dart';

class UserService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _storage = FirebaseStorage.instance;
  final _fns = FirebaseFunctions.instanceFor(region: 'europe-west1');

  String? get uid => _auth.currentUser?.uid;

  // ---------- PROFILE ----------

  Stream<UserProfile?> streamProfile(String uid) {
    if (uid.trim().isEmpty) return Stream.value(null);
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromFirestore(doc.data()!, doc.id);
    });
  }

  Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    await _db.collection('users').doc(uid).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<String> uploadAvatar({
    required String uid,
    required Uint8List bytes,
    required String extension,
    void Function(double)? onProgress,
  }) async {
    if (bytes.length > 5 * 1024 * 1024) {
      throw Exception('Image is too large (max 5 MB).');
    }
    final ext = extension.toLowerCase().replaceAll('.', '');
    final path =
        'users/$uid/avatar_${DateTime.now().millisecondsSinceEpoch}.$ext';
    final ref = _storage.ref(path);
    final task = ref.putData(
      bytes,
      SettableMetadata(
        contentType: ext == 'png' ? 'image/png' : 'image/jpeg',
        cacheControl: 'public, max-age=31536000',
      ),
    );
    final sub = task.snapshotEvents.listen((s) {
      if (s.totalBytes > 0) onProgress?.call(s.bytesTransferred / s.totalBytes);
    });
    try {
      final snap = await task;
      return await snap.ref.getDownloadURL();
    } finally {
      await sub.cancel();
    }
  }

  // ---------- PREFERENCES ----------

  Stream<UserPreferences> streamPreferences(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (!doc.exists) return UserPreferences();
      final data = doc.data()!;
      final prefs = data['preferences'];
      if (prefs is Map<String, dynamic>) {
        return UserPreferences.fromFirestore(prefs);
      }
      return UserPreferences();
    });
  }

  Future<void> updatePreferences(
      String uid, UserPreferences preferences) async {
    await _db.collection('users').doc(uid).update({
      'preferences': preferences.toFirestore(),
    });
  }

  // ---------- ACCOUNT ----------

  Future<void> changePassword(String currentPassword, String newPassword) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw Exception('Not signed in');

    // Re-authenticate first
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    await user.updatePassword(newPassword);
  }

  Future<void> deleteAccount() async {
    final callable = _fns.httpsCallable('deleteListenerAccount');
    await callable.call();
    await _auth.signOut();
  }

  Future<void> signOut() async => _auth.signOut();
}
