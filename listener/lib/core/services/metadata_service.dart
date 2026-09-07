import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for reading and writing app-level metadata stored in Firestore
/// under the `app_metadata` collection.
///
/// Use cases:
/// - Remote config (theme defaults, feature flags, version info)
/// - Backend-driven UI settings
class MetadataService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'app_metadata';

  /// Get a single metadata document by its key.
  Future<Map<String, dynamic>?> getMetadata(String key) async {
    final doc = await _firestore.collection(_collection).doc(key).get();
    if (!doc.exists) return null;
    return doc.data();
  }

  /// Set a single metadata document (overwrites).
  Future<void> setMetadata(String key, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(key).set(data);
  }

  /// Update specific fields in a metadata document.
  Future<void> updateMetadata(String key, Map<String, dynamic> data) async {
    await _firestore.collection(_collection).doc(key).update(data);
  }

  /// Listen to a metadata document in real time.
  Stream<Map<String, dynamic>?> watchMetadata(String key) {
    return _firestore.collection(_collection).doc(key).snapshots().map(
      (doc) => doc.exists ? doc.data() : null,
    );
  }

  /// Delete a metadata document.
  Future<void> deleteMetadata(String key) async {
    await _firestore.collection(_collection).doc(key).delete();
  }

  /// Convenience: stream of the remote 'settings' doc for the listener app.
  Stream<Map<String, dynamic>?> watchSettings() => watchMetadata('settings');
}
