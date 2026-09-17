import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/radio_model.dart';

class SearchEntry {
  final String id;
  final String query;
  final DateTime searchedAt;
  SearchEntry({required this.id, required this.query, required this.searchedAt});
}

class ChannelsService {
  final _db = FirebaseFirestore.instance;

  // ---------- RADIOS ----------

  /// All radios. Safe against missing composite indexes and documents missing isActive.
  Stream<List<RadioModel>> streamAllRadios({String currentUserId = ''}) {
    return _db
        .collection('radios')
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => d.data()['isActive'] != false)
            .map((d) {
              final data = d.data();
              final followers = (data['followers'] as List?) ?? [];
              final isFollowed = currentUserId.isNotEmpty && followers.contains(currentUserId);
              return RadioModel.fromFirestore(data, d.id).copyWith(isFollowed: isFollowed);
            })
            .toList());
  }

  /// Radios this user follows. Uses single-field index (no composite index required).
  Stream<List<RadioModel>> streamFollowed(String uid) {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return Stream.value(<RadioModel>[]);

    return _db
        .collection('radios')
        .where('followers', arrayContains: cleanUid)
        .snapshots()
        .map((snap) => snap.docs
            .where((d) => d.data()['isActive'] != false)
            .map((d) => RadioModel.fromFirestore(d.data(), d.id).copyWith(isFollowed: true))
            .toList());
  }

  Future<void> toggleFollow(String radioId, String uid, bool follow) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty || radioId.trim().isEmpty) return;

    await _db.collection('radios').doc(radioId).update({
      'followers': follow
          ? FieldValue.arrayUnion([cleanUid])
          : FieldValue.arrayRemove([cleanUid]),
      'followerCount': FieldValue.increment(follow ? 1 : -1),
    });
  }

  // ---------- SEARCH HISTORY ----------

  Stream<List<SearchEntry>> streamSearchHistory(String uid, {int limit = 8}) {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return Stream.value(<SearchEntry>[]);

    return _db
        .collection('users')
        .doc(cleanUid)
        .collection('search_history')
        .orderBy('searchedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((d) {
              final data = d.data();
              return SearchEntry(
                id: d.id,
                query: (data['query'] ?? '').toString(),
                searchedAt:
                    (data['searchedAt'] as Timestamp?)?.toDate().toLocal() ??
                        DateTime.now(),
              );
            }).toList());
  }

  Future<void> addSearchQuery(String uid, String query) async {
    final cleanUid = uid.trim();
    final clean = query.trim();
    if (cleanUid.isEmpty || clean.isEmpty) return;

    final col = _db.collection('users').doc(cleanUid).collection('search_history');

    // Skip if the same query was already the most recent
    final recent = await col
        .orderBy('searchedAt', descending: true)
        .limit(1)
        .get();
    if (recent.docs.isNotEmpty &&
        (recent.docs.first.data()['query'] ?? '') == clean) {
      return;
    }

    // Remove any previous entry with this exact query
    final dup = await col.where('query', isEqualTo: clean).get();
    for (final d in dup.docs) {
      await d.reference.delete();
    }

    await col.add({
      'query': clean,
      'searchedAt': FieldValue.serverTimestamp(),
    });

    // Cap at 20 entries
    final all = await col.orderBy('searchedAt', descending: true).get();
    if (all.docs.length > 20) {
      for (final d in all.docs.skip(20)) {
        await d.reference.delete();
      }
    }
  }

  Future<void> removeSearchEntry(String uid, String entryId) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return;

    await _db
        .collection('users')
        .doc(cleanUid)
        .collection('search_history')
        .doc(entryId)
        .delete();
  }

  Future<void> clearSearchHistory(String uid) async {
    final cleanUid = uid.trim();
    if (cleanUid.isEmpty) return;

    final col = _db.collection('users').doc(cleanUid).collection('search_history');
    final snap = await col.get();
    for (final d in snap.docs) {
      await d.reference.delete();
    }
  }
}
