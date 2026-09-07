import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/schedule_model.dart';
import '../models/flash_model.dart';

class ScheduleService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'schedule';

  Future<List<ScheduleItem>> getScheduleForDate(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      final snapshot = await _firestore
          .collection(_collection)
          .where('startTime', isGreaterThanOrEqualTo: startOfDay)
          .where('startTime', isLessThan: endOfDay)
          .orderBy('startTime')
          .get();

      return snapshot.docs
          .map((doc) => ScheduleItem.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting schedule: $e');
      return [];
    }
  }

  Future<Map<DateTime, List<ScheduleItem>>> getScheduleForWeek(
    DateTime startDate,
  ) async {
    try {
      final endDate = startDate.add(const Duration(days: 7));
      final snapshot = await _firestore
          .collection(_collection)
          .where('startTime', isGreaterThanOrEqualTo: startDate)
          .where('startTime', isLessThan: endDate)
          .orderBy('startTime')
          .get();

      final Map<DateTime, List<ScheduleItem>> schedule = {};
      for (final doc in snapshot.docs) {
        final item = ScheduleItem.fromFirestore(doc.data(), doc.id);
        final day = DateTime(item.startTime.year, item.startTime.month, item.startTime.day);
        schedule.putIfAbsent(day, () => []).add(item);
      }
      return schedule;
    } catch (e) {
      print('Error getting week schedule: $e');
      return {};
    }
  }

  Future<ScheduleItem?> getNowPlaying() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('startTime', isLessThanOrEqualTo: now)
          .where('endTime', isGreaterThanOrEqualTo: now)
          .orderBy('startTime', descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return ScheduleItem.fromFirestore(snapshot.docs.first.data(), snapshot.docs.first.id);
    } catch (e) {
      print('Error getting now playing: $e');
      return null;
    }
  }

  Future<List<ScheduleItem>> getUpcomingShows({int limit = 10}) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('startTime', isGreaterThanOrEqualTo: now)
          .where('type', isNotEqualTo: 'flash')
          .orderBy('startTime')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ScheduleItem.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting upcoming shows: $e');
      return [];
    }
  }

  Future<List<ScheduleItem>> getSpecialEvents({int limit = 10}) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('startTime', isGreaterThanOrEqualTo: now)
          .where('type', isEqualTo: 'special')
          .orderBy('startTime')
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => ScheduleItem.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting special events: $e');
      return [];
    }
  }

  Future<List<FlashProgram>> getActiveFlashes() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('flashes')
          .where('isActive', isEqualTo: true)
          .where('expiresAt', isGreaterThan: now)
          .orderBy('createdAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => FlashProgram.fromFirestore(doc.data(), doc.id))
          .toList();
    } catch (e) {
      print('Error getting active flashes: $e');
      return [];
    }
  }

  Stream<List<ScheduleItem>> streamTodaySchedule() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _firestore
        .collection(_collection)
        .where('startTime', isGreaterThanOrEqualTo: startOfDay)
        .where('startTime', isLessThan: endOfDay)
        .orderBy('startTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ScheduleItem.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  Future<void> addScheduleItem(ScheduleItem item) async {
    try {
      await _firestore.collection(_collection).doc(item.id).set({
        'title': item.title,
        'host': item.host,
        'guest': item.guest,
        'guestTitle': item.guestTitle,
        'guestBio': item.guestBio,
        'guestImageUrl': item.guestImageUrl,
        'startTime': item.startTime,
        'endTime': item.endTime,
        'type': item.type.toString().split('.').last,
        'description': item.description,
        'imageUrl': item.imageUrl,
        'listenerCount': item.listenerCount,
        'isLive': item.isLive,
        'isInteractive': item.isInteractive,
        'channelId': item.channelId,
        'channelName': item.channelName,
        'flashId': item.flashId,
        'tags': item.tags,
        'recordingUrl': item.recordingUrl,
      });
    } catch (e) {
      print('Error adding schedule item: $e');
    }
  }

  Future<void> updateScheduleItem(String id, Map<String, dynamic> data) async {
    try {
      await _firestore.collection(_collection).doc(id).update(data);
    } catch (e) {
      print('Error updating schedule item: $e');
    }
  }
}
