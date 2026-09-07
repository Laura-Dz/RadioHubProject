import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/show_model.dart';

class TimetableService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'recurring_shows';

  Future<List<ShowModel>> getRecurringShows({
    String? dayType,
    String? category,
    String? host,
  }) async {
    try {
      Query query = _firestore.collection(_collection);

      if (dayType != null && dayType != 'all') {
        query = query.where('dayType', arrayContains: dayType);
      }

      if (category != null && category != 'all') {
        query = query.where('category', isEqualTo: category);
      }

      if (host != null && host.isNotEmpty) {
        query = query.where('host', isEqualTo: host);
      }

      final snapshot = await query
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting recurring shows: $e');
      return [];
    }
  }

  Future<List<ShowModel>> getRecurringShowsForDay(DateTime date) async {
    try {
      final dayOfWeek = date.weekday;
      final dayType = dayOfWeek >= 1 && dayOfWeek <= 5 ? 'weekday' : 'weekend';

      final snapshot = await _firestore
          .collection(_collection)
          .where('dayType', arrayContains: dayType)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting recurring shows for day: $e');
      return [];
    }
  }

  Future<List<ShowModel>> getWeekdayShows() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('dayType', arrayContains: 'weekday')
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting weekday shows: $e');
      return [];
    }
  }

  Future<List<ShowModel>> getWeekendShows() async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('dayType', arrayContains: 'weekend')
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting weekend shows: $e');
      return [];
    }
  }

  Future<List<ShowModel>> getShowsByHost(String hostName) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('host', isEqualTo: hostName)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting shows by host: $e');
      return [];
    }
  }

  Future<List<ShowModel>> getShowsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting shows by category: $e');
      return [];
    }
  }

  Future<void> followRecurringShow(String showId, bool follow) async {
    try {
      await _firestore.collection(_collection).doc(showId).update({
        'isFollowed': follow,
        'followerCount': follow ? 1 : -1,
      });
    } catch (e) {
      print('Error toggling follow: $e');
    }
  }

  Future<List<ShowModel>> getFollowedRecurringShows(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_collection)
          .where('followers', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting followed recurring shows: $e');
      return [];
    }
  }

  Future<List<String>> getHosts() async {
    try {
      final snapshot = await _firestore.collection(_collection).get();
      final hosts = <String>{};
      for (final doc in snapshot.docs) {
        final host = doc.data()['host'] as String?;
        if (host != null) hosts.add(host);
      }
      return hosts.toList()..sort();
    } catch (e) {
      print('Error getting hosts: $e');
      return [];
    }
  }

  Stream<List<ShowModel>> streamRecurringShows({
    String? dayType,
  }) {
    Query query = _firestore.collection(_collection).where('isActive', isEqualTo: true);

    if (dayType != null && dayType != 'all') {
      query = query.where('dayType', arrayContains: dayType);
    }

    return query
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }
}
