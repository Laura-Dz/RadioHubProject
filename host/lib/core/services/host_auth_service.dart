import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'cloud_function_caller.dart';

class HostAuthResult {
  final String sessionId;
  final String programName;
  final String hostName;
  HostAuthResult({
    required this.sessionId,
    required this.programName,
    required this.hostName,
  });
}

class HostAuthService {
  final _auth = FirebaseAuth.instance;
  final _db = FirebaseFirestore.instance;

  Future<HostAuthResult> loginWithCode(String code) async {
    final cleanCode = code.trim().toUpperCase();
    if (cleanCode.isEmpty) {
      throw Exception('Session code required');
    }

    // 1. Try Cloud Function first (for custom token with claims)
    try {
      final data = await CloudFunctionCaller.call(
        'verifySessionCode',
        {'sessionCode': cleanCode},
      );
      if (data['customToken'] != null) {
        await _auth.signInWithCustomToken(data['customToken'] as String);
        return HostAuthResult(
          sessionId: data['sessionId'] as String,
          programName: (data['programName'] ?? '') as String,
          hostName: (data['hostName'] ?? '') as String,
        );
      }
    } catch (e) {
      debugPrint('Cloud Function verifySessionCode failed ($e), falling back to Firestore query...');
    }

    // 2. Direct Firestore fallback (works immediately even before Cloud Functions deployment)
    try {
      final snap = await _db
          .collection('sessions')
          .where('sessionCode', isEqualTo: cleanCode)
          .where('status', whereIn: ['scheduled', 'on_air', 'live'])
          .limit(1)
          .get();

      if (snap.docs.isEmpty) {
        // Also check if any session with this code exists at all
        final anySnap = await _db
            .collection('sessions')
            .where('sessionCode', isEqualTo: cleanCode)
            .limit(1)
            .get();

        if (anySnap.docs.isNotEmpty) {
          final s = anySnap.docs.first.data();
          throw Exception('Session is not active (status: ${s['status'] ?? 'unknown'})');
        }
        throw Exception('Invalid or expired code');
      }

      final doc = snap.docs.first;
      final s = doc.data();

      // Sign in anonymously if not signed in so Firestore rules with request.auth pass
      if (_auth.currentUser == null) {
        try {
          await _auth.signInAnonymously();
        } catch (authErr) {
          debugPrint('Anonymous auth fallback error: $authErr');
        }
      }

      return HostAuthResult(
        sessionId: doc.id,
        programName: (s['programName'] ?? '') as String,
        hostName: (s['hostName'] ?? '') as String,
      );
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception(e.toString());
    }
  }

  Future<void> logout() async => _auth.signOut();

  String? get currentSessionId => _auth.currentUser?.uid.startsWith('host_') == true
      ? _auth.currentUser!.uid.substring(5)
      : null;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
}
