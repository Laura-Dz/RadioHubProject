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
          .map((doc) => ScheduleItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
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
          .orderBy('startTime', descending: true)
          .limit(10)
          .get();

      for (final doc in snapshot.docs) {
        final item = ScheduleItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id);
        if (item.endTime.isAfter(now)) {
          return item;
        }
      }
      return null;
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
          .orderBy('startTime')
          .limit(limit * 2)
          .get();

      return snapshot.docs
          .map((doc) => ScheduleItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((item) => item.type.toString().split('.').last != 'flash')
          .take(limit)
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
          .where('type', isEqualTo: 'special')
          .get();

      final items = snapshot.docs
          .map((doc) => ScheduleItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((item) => item.startTime.isAfter(now))
          .toList();
      items.sort((a, b) => a.startTime.compareTo(b.startTime));
      return items.take(limit).toList();
    } catch (e) {
      print('Error getting special events: $e');
      return [];
    }
  }

  Future<ScheduleItem?> getCurrentProgram(String radioId) async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection(_collection)
          .where('channelId', isEqualTo: radioId)
          .get();

      final items = snapshot.docs
          .map((doc) => ScheduleItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();

      for (final item in items) {
        if (item.startTime.isBefore(now) && item.endTime.isAfter(now)) {
          return item;
        }
      }

      final past = items.where((item) => item.startTime.isBefore(now)).toList();
      if (past.isNotEmpty) {
        past.sort((a, b) => b.startTime.compareTo(a.startTime));
        return past.first;
      }
      return null;
    } catch (e) {
      print('Error getting current program: $e');
      return null;
    }
  }

  Future<List<ScheduleItem>> getUpcomingPrograms(String radioId) async {
    try {
      final now = DateTime.now();
      final tomorrow = now.add(const Duration(hours: 24));
      final snapshot = await _firestore
          .collection(_collection)
          .where('channelId', isEqualTo: radioId)
          .get();

      final items = snapshot.docs
          .map((doc) => ScheduleItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((item) => item.startTime.isAfter(now) && item.startTime.isBefore(tomorrow))
          .toList();
      items.sort((a, b) => a.startTime.compareTo(b.startTime));
      return items;
    } catch (e) {
      print('Error getting upcoming programs: $e');
      return [];
    }
  }

  Stream<List<ScheduleItem>> streamScheduleForRadio(String radioId) {
    return _firestore
        .collection(_collection)
        .where('channelId', isEqualTo: radioId)
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();
          final tomorrow = now.add(const Duration(hours: 24));
          final items = snapshot.docs
              .map((doc) => ScheduleItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
              .where((item) => item.startTime.isAfter(now) && item.startTime.isBefore(tomorrow))
              .toList();
          items.sort((a, b) => a.startTime.compareTo(b.startTime));
          return items;
        });
  }

  Stream<List<Comment>> streamComments(String programId) {
    return _firestore
        .collection('comments')
        .where('programId', isEqualTo: programId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
             .map((doc) => Comment.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
             .toList());
  }

  Future<List<FlashProgram>> getActiveFlashes() async {
    try {
      final now = DateTime.now();
      final snapshot = await _firestore
          .collection('flashes')
          .where('isActive', isEqualTo: true)
          .limit(25)
          .get();

      final list = snapshot.docs
          .map((doc) => FlashProgram.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .where((f) => f.expiresAt == null || f.expiresAt!.isAfter(now))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
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
            .map((doc) => ScheduleItem.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
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

  Future<void> addComment(String programId, String userId, String userName, String text) async {
    try {
      await _firestore.collection('comments').add({
        'programId': programId,
        'userId': userId,
        'userName': userName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error adding comment: $e');
      rethrow;
    }
  }
}

class Comment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;

  Comment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
  });

  factory Comment.fromFirestore(Map<String, dynamic> data, String id) {
    return Comment(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      text: data['text'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }
}
