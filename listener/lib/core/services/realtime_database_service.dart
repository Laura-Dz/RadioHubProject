import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';

/// Service for Firebase Realtime Database.
///
/// Use cases in RadioHub:
/// - Live comments during shows (per program / session)
/// - Ephemeral program chat
/// - Live listener counts / reactions
/// - Real-time polls and live vote tallies
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

  FirebaseDatabase get _db => database;

  /// Push a new comment into the live chat for a program.
  /// Returns the generated comment key.
  Future<String> addComment({
    required String programId,
    required String userId,
    required String userName,
    required String message,
  }) async {
    final ref = _db.ref('comments/$programId').push();
    final entry = <String, dynamic>{
      'userId': userId,
      'userName': userName,
      'message': message,
      'timestamp': ServerValue.timestamp,
    };
    await ref.set(entry);
    return ref.key ?? '';
  }

  /// Stream all comments for a program, ordered by timestamp.
  /// Emits the full list on every child add/change.
  Stream<List<Map<String, dynamic>>> streamComments(String programId) {
    final ref = _db.ref('comments/$programId').orderByChild('timestamp');
    return ref.onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return <Map<String, dynamic>>[];
      final map = Map<String, dynamic>.from(raw as Map);
      final comments = map.entries.map((e) {
        final m = Map<String, dynamic>.from(e.value as Map);
        m['id'] = e.key;
        return m;
      }).toList();
      comments.sort((a, b) {
        final ta = (a['timestamp'] as num?)?.toInt() ?? 0;
        final tb = (b['timestamp'] as num?)?.toInt() ?? 0;
        return ta.compareTo(tb);
      });
      return comments;
    });
  }

  /// Listen to a single new-comment event.
  Stream<Map<String, dynamic>> onCommentAdded(String programId) {
    return _db
        .ref('comments/$programId')
        .orderByChild('timestamp')
        .startAt(DateTime.now().millisecondsSinceEpoch)
        .onChildAdded
        .map((event) {
      final m = Map<String, dynamic>.from(event.snapshot.value as Map);
      m['id'] = event.snapshot.key;
      return m;
    });
  }

  /// Delete a single comment by its key.
  Future<void> deleteComment({
    required String programId,
    required String commentId,
  }) async {
    await _db.ref('comments/$programId/$commentId').remove();
  }

  /// Update listener count for a program in real time.
  Future<void> updateListenerCount(String programId, int count) async {
    await _db.ref('programs/$programId/listenerCount').set(count);
  }

  /// Listen to listener count changes for a program.
  Stream<int> streamListenerCount(String programId) {
    return _db
        .ref('programs/$programId/listenerCount')
        .onValue
        .map((event) {
      final v = event.snapshot.value;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    });
  }

  /// Push a transient reaction (emoji, like) to a program.
  Future<void> addReaction({
    required String programId,
    required String userId,
    required String emoji,
  }) async {
    final ref = _db.ref('reactions/$programId').push();
    await ref.set({
      'userId': userId,
      'emoji': emoji,
      'timestamp': ServerValue.timestamp,
    });
  }

  /// Stream live reaction counts grouped by emoji for a program.
  Stream<Map<String, int>> streamReactionCounts(String programId) {
    return _db.ref('reactions/$programId').onValue.map((event) {
      final raw = event.snapshot.value;
      if (raw == null) return <String, int>{};
      final map = Map<String, dynamic>.from(raw as Map);
      final counts = <String, int>{};
      for (final entry in map.values) {
        final m = Map<String, dynamic>.from(entry as Map);
        final emoji = m['emoji'] as String? ?? '';
        counts[emoji] = (counts[emoji] ?? 0) + 1;
      }
      return counts;
    });
  }

  /// Generic read at a path.
  Future<DataSnapshot> read(String path) async {
    return _db.ref(path).get();
  }

  /// Generic write at a path.
  Future<void> write(String path, Object value) async {
    await _db.ref(path).set(value);
  }

  /// Generic update at a path (shallow merge).
  Future<void> update(String path, Map<String, dynamic> values) async {
    await _db.ref(path).update(values);
  }

  /// Delete a node.
  Future<void> remove(String path) async {
    await _db.ref(path).remove();
  }
}
