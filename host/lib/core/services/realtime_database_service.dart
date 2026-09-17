import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service for Firebase Realtime Database in Host app.
class RealtimeDatabaseService {
  static const String databaseUrl =
      'https://radiohub12-default-rtdb.europe-west1.firebasedatabase.app';

  static FirebaseDatabase get database {
    try {
      return FirebaseDatabase.instanceFor(
        app: Firebase.app(),
        databaseURL: databaseUrl,
      );
    } catch (_) {
      return FirebaseDatabase.instance;
    }
  }
}
