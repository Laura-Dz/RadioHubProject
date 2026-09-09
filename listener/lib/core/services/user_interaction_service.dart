import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_interaction_model.dart';
import '../models/show_model.dart';

class UserInteractionService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<void> toggleStarChannel(String userId, String channelId) async {
    final existing = await _firestore
        .collection('starred_channels')
        .where('userId', isEqualTo: userId)
        .where('channelId', isEqualTo: channelId)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.delete();
      await _firestore.collection('radios').doc(channelId).update({
        'starCount': FieldValue.increment(-1),
      });
    } else {
      await _firestore.collection('starred_channels').add({
        'userId': userId,
        'channelId': channelId,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('radios').doc(channelId).update({
        'starCount': FieldValue.increment(1),
      });
    }
  }

  Future<List<String>> getStarredChannelIds(String userId) async {
    final snapshot = await _firestore
        .collection('starred_channels')
        .where('userId', isEqualTo: userId)
        .get();
    return snapshot.docs.map((doc) => doc.data()['channelId'] as String).toList();
  }

  Future<bool> isChannelStarred(String userId, String channelId) async {
    final snapshot = await _firestore
        .collection('starred_channels')
        .where('userId', isEqualTo: userId)
        .where('channelId', isEqualTo: channelId)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Stream<List<StarredChannel>> streamStarredChannels(String userId) {
    return _firestore
        .collection('starred_channels')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => StarredChannel.fromFirestore(doc))
            .toList());
  }

  Future<void> toggleFollowShow(String userId, String showId) async {
    final existing = await _firestore
        .collection('show_follows')
        .where('userId', isEqualTo: userId)
        .where('showId', isEqualTo: showId)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.delete();
      await _firestore.collection('shows').doc(showId).update({
        'followerCount': FieldValue.increment(-1),
      });
    } else {
      await _firestore.collection('show_follows').add({
        'userId': userId,
        'showId': showId,
        'status': 'active',
        'createdAt': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('shows').doc(showId).update({
        'followerCount': FieldValue.increment(1),
      });
    }
  }

  Future<List<String>> getFollowedShowIds(String userId) async {
    final snapshot = await _firestore
        .collection('show_follows')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .get();
    return snapshot.docs.map((doc) => doc.data()['showId'] as String).toList();
  }

  Future<List<ShowModel>> getFollowedShows(String userId) async {
    final showIds = await getFollowedShowIds(userId);
    if (showIds.isEmpty) return [];
    final snapshot = await _firestore
        .collection('shows')
        .where('id', whereIn: showIds)
        .where('isActive', isEqualTo: true)
        .get();
    return snapshot.docs
        .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  Future<bool> isShowFollowed(String userId, String showId) async {
    final snapshot = await _firestore
        .collection('show_follows')
        .where('userId', isEqualTo: userId)
        .where('showId', isEqualTo: showId)
        .where('status', isEqualTo: 'active')
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Stream<List<ShowFollow>> streamFollowedShows(String userId) {
    return _firestore
        .collection('show_follows')
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShowFollow.fromFirestore(doc))
            .toList());
  }

  Future<void> setShowReminder({
    required String userId,
    required String showId,
    required String programName,
    required DateTime showStartTime,
    int reminderMinutesBefore = 15,
  }) async {
    final existing = await _firestore
        .collection('show_reminders')
        .where('userId', isEqualTo: userId)
        .where('showId', isEqualTo: showId)
        .where('isActive', isEqualTo: true)
        .get();

    if (existing.docs.isNotEmpty) {
      await existing.docs.first.reference.update({
        'reminderMinutesBefore': reminderMinutesBefore,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    await _firestore.collection('show_reminders').add({
      'userId': userId,
      'showId': showId,
      'programName': programName,
      'showStartTime': showStartTime,
      'reminderMinutesBefore': reminderMinutesBefore,
      'isActive': true,
      'isNotified': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> removeShowReminder(String userId, String showId) async {
    final snapshot = await _firestore
        .collection('show_reminders')
        .where('userId', isEqualTo: userId)
        .where('showId', isEqualTo: showId)
        .where('isActive', isEqualTo: true)
        .get();

    for (final doc in snapshot.docs) {
      await doc.reference.update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<List<ShowReminder>> getActiveReminders(String userId) async {
    final snapshot = await _firestore
        .collection('show_reminders')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('showStartTime')
        .get();
    return snapshot.docs
        .map((doc) => ShowReminder.fromFirestore(doc))
        .toList();
  }

  Future<bool> hasReminder(String userId, String showId) async {
    final snapshot = await _firestore
        .collection('show_reminders')
        .where('userId', isEqualTo: userId)
        .where('showId', isEqualTo: showId)
        .where('isActive', isEqualTo: true)
        .limit(1)
        .get();
    return snapshot.docs.isNotEmpty;
  }

  Stream<List<ShowReminder>> streamActiveReminders(String userId) {
    return _firestore
        .collection('show_reminders')
        .where('userId', isEqualTo: userId)
        .where('isActive', isEqualTo: true)
        .orderBy('showStartTime')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ShowReminder.fromFirestore(doc))
            .toList());
  }

  Future<void> createNotification(NotificationModel notification) async {
    await _firestore.collection('notifications').doc(notification.id).set(
      notification.toFirestore(),
    );
  }

  Future<List<NotificationModel>> getNotifications(String userId, {int limit = 20}) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();
    return snapshot.docs
        .map((doc) => NotificationModel.fromFirestore(doc))
        .toList();
  }

  Future<int> getUnreadNotificationCount(String userId) async {
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();
    return snapshot.docs.length;
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore.collection('notifications').doc(notificationId).update({
      'isRead': true,
      'readAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final batch = _firestore.batch();
    final snapshot = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in snapshot.docs) {
      batch.update(doc.reference, {
        'isRead': true,
        'readAt': FieldValue.serverTimestamp(),
      });
    }
    await batch.commit();
  }

  Stream<List<NotificationModel>> streamNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .limit(20)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => NotificationModel.fromFirestore(doc))
            .toList());
  }

  Future<void> sendLiveNotifications(String showId, String programName) async {
    final snapshot = await _firestore
        .collection('show_follows')
        .where('showId', isEqualTo: showId)
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in snapshot.docs) {
      final userId = doc.data()['userId'] as String;
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'showLive',
        'title': '🔴 Live Now!',
        'body': '"$programName" is now live! Tap to listen.',
        'showId': showId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {'showId': showId, 'action': 'listen_now'},
      });
    }
  }

  Future<void> sendUpcomingNotifications(String showId, String programName, DateTime startTime) async {
    final snapshot = await _firestore
        .collection('show_follows')
        .where('showId', isEqualTo: showId)
        .where('status', isEqualTo: 'active')
        .get();

    for (final doc in snapshot.docs) {
      final userId = doc.data()['userId'] as String;
      await _firestore.collection('notifications').add({
        'userId': userId,
        'type': 'showUpcoming',
        'title': '📅 Show Starting Soon',
        'body': '"$programName" starts at ${_formatTime(startTime)}',
        'showId': showId,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
        'data': {'showId': showId, 'startTime': startTime.toIso8601String()},
      });
    }
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}
