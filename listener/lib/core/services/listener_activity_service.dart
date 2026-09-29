import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class ListenerActivityService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final ListenerActivityService _instance = ListenerActivityService._internal();
  factory ListenerActivityService() => _instance;
  ListenerActivityService._internal();

  /// Logs when a listener presses PLAY to start listening
  Future<void> logPlay({
    required String radioId,
    required String radioName,
    required String userId,
    String? sessionId,
    String? sessionTitle,
    String? programId,
    String? programCategory,
  }) async {
    if (radioId.isEmpty) return;
    try {
      final now = DateTime.now();
      final data = <String, dynamic>{
        'radioId': radioId,
        'radioName': radioName,
        'userId': userId,
        'action': 'play',
        'sessionId': sessionId,
        'sessionTitle': sessionTitle,
        'programId': programId,
        'programCategory': programCategory,
        'timestamp': FieldValue.serverTimestamp(),
        'clientTime': now.toIso8601String(),
        'hour': now.hour,
        'dayOfWeek': now.weekday,
      };

      // 1. Root collection for global and radio-level queries
      await _firestore.collection('listener_activity').add(data);

      // 2. Subcollection under radio document for isolated radio audits
      await _firestore
          .collection('radios')
          .doc(radioId)
          .collection('activity_logs')
          .add(data);

      debugPrint('ListenerActivity: logged PLAY for radio $radioId by $userId');
    } catch (e) {
      debugPrint('ListenerActivityService.logPlay error: $e');
    }
  }

  /// Logs when a listener presses PAUSE
  Future<void> logPause({
    required String radioId,
    required String radioName,
    required String userId,
    required int durationSeconds,
    String? sessionId,
    String? sessionTitle,
    String? programId,
    String? programCategory,
  }) async {
    if (radioId.isEmpty) return;
    try {
      final now = DateTime.now();
      final data = <String, dynamic>{
        'radioId': radioId,
        'radioName': radioName,
        'userId': userId,
        'action': 'pause',
        'durationSeconds': durationSeconds,
        'sessionId': sessionId,
        'sessionTitle': sessionTitle,
        'programId': programId,
        'programCategory': programCategory,
        'timestamp': FieldValue.serverTimestamp(),
        'clientTime': now.toIso8601String(),
        'hour': now.hour,
        'dayOfWeek': now.weekday,
      };

      await _firestore.collection('listener_activity').add(data);
      await _firestore
          .collection('radios')
          .doc(radioId)
          .collection('activity_logs')
          .add(data);

      debugPrint('ListenerActivity: logged PAUSE for radio $radioId ($durationSeconds s)');
    } catch (e) {
      debugPrint('ListenerActivityService.logPause error: $e');
    }
  }

  /// Logs when a listener STOPS or dismisses the player
  Future<void> logStop({
    required String radioId,
    required String radioName,
    required String userId,
    required int durationSeconds,
    String? sessionId,
    String? sessionTitle,
    String? programId,
    String? programCategory,
  }) async {
    if (radioId.isEmpty) return;
    try {
      final now = DateTime.now();
      final data = <String, dynamic>{
        'radioId': radioId,
        'radioName': radioName,
        'userId': userId,
        'action': 'stop',
        'durationSeconds': durationSeconds,
        'sessionId': sessionId,
        'sessionTitle': sessionTitle,
        'programId': programId,
        'programCategory': programCategory,
        'timestamp': FieldValue.serverTimestamp(),
        'clientTime': now.toIso8601String(),
        'hour': now.hour,
        'dayOfWeek': now.weekday,
      };

      await _firestore.collection('listener_activity').add(data);
      await _firestore
          .collection('radios')
          .doc(radioId)
          .collection('activity_logs')
          .add(data);

      debugPrint('ListenerActivity: logged STOP for radio $radioId ($durationSeconds s)');
    } catch (e) {
      debugPrint('ListenerActivityService.logStop error: $e');
    }
  }
}
