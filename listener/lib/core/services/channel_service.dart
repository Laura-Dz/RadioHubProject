import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/channel_model.dart';
import '../models/show_model.dart';

class ChannelService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'channels';

  Future<List<ChannelModel>> getChannels({
    String? category,
    String? searchQuery,
    int limit = 20,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.where('name', isGreaterThanOrEqualTo: searchQuery)
            .where('name', isLessThan: searchQuery + '\uf8ff');
      }

      final snapshot = await query
          .orderBy('followerCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ChannelModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting channels: $e');
      return [];
    }
  }

  Future<List<ChannelModel>> getFeaturedChannels({int limit = 5}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('isFeatured', isEqualTo: true)
          .orderBy('followerCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ChannelModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting featured channels: $e');
      return [];
    }
  }

  Future<List<ChannelModel>> getTrendingChannels({int limit = 10}) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .orderBy('listenerCount', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ChannelModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting trending channels: $e');
      return [];
    }
  }

  Future<ChannelModel?> getChannelById(String channelId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(channelId).get();
      if (!doc.exists) return null;
      return ChannelModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
    } catch (e) {
      print('Error getting channel: $e');
      return null;
    }
  }

  Future<List<ShowModel>> getChannelShows(String channelId, {int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('shows')
          .where('channelId', isEqualTo: channelId)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting channel shows: $e');
      return [];
    }
  }

  Future<void> toggleFollowChannel(String channelId, bool follow) async {
    try {
      await _firestore.collection(_collection).doc(channelId).update({
        'isFollowed': follow,
        'followerCount': follow ? 1 : -1,
      });
    } catch (e) {
      print('Error toggling follow: $e');
    }
  }

  Future<List<ChannelModel>> getFollowedChannels(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('followers', arrayContains: userId)
          .get();

      return snapshot.docs
          .map((doc) => ChannelModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      print('Error getting followed channels: $e');
      return [];
    }
  }

  Stream<List<ChannelModel>> streamChannels({
    String? category,
    int limit = 20,
  }) {
    Query query = _firestore.collection(_collection);

    if (category != null && category != 'all') {
      query = query.where('category', isEqualTo: category);
    }

    return query
        .orderBy('followerCount', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChannelModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
            .toList());
  }

  Future<List<String>> getCategories() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final categories = <String>{};
      for (final doc in snapshot.docs) {
        final category = doc.data()['category'] as String?;
        if (category != null) categories.add(category);
      }
      return categories.toList()..sort();
    } catch (e) {
      print('Error getting categories: $e');
      return ['music', 'talk', 'news', 'sports', 'comedy', 'education', 'entertainment'];
    }
  }
}
