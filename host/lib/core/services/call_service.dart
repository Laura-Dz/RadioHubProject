import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/call.dart';
import 'cloud_function_caller.dart';

class CallService {
  final _db = FirebaseFirestore.instance;

  Stream<List<Call>> streamCalls(String sessionId) {
    return _db
        .collection('calls')
        .where('sessionId', isEqualTo: sessionId)
        .orderBy('requestedAt', descending: false)
        .snapshots()
        .map((s) => s.docs.map((d) => Call.fromFirestore(d.data(), d.id)).toList());
  }

  Future<void> _updateStatus(String callId, String status, {Map<String, dynamic>? extra}) async {
    try {
      final res = await CloudFunctionCaller.call('updateCallStatus', {
        'callId': callId,
        'status': status,
      });
      if (res['success'] != true) {
        throw Exception(res['reason'] == 'another_on_call'
            ? 'End the current call first'
            : 'Could not update call');
      }
    } catch (e) {
      debugPrint('updateCallStatus cloud function fallback: $e');
      // Direct Firestore update fallback
      try {
        final updateData = <String, dynamic>{'status': status};
        if (status == 'accepted') updateData['acceptedAt'] = FieldValue.serverTimestamp();
        if (status == 'ended') updateData['endedAt'] = FieldValue.serverTimestamp();
        if (extra != null) updateData.addAll(extra);
        await _db.collection('calls').doc(callId).update(updateData);
      } catch (dbErr) {
        debugPrint('Direct firestore call update error: $dbErr');
        rethrow;
      }
    }
  }

  Future<void> accept(String callId) async => _updateStatus(callId, 'accepted');

  Future<void> hold(String callId) async => _updateStatus(callId, 'held');

  Future<void> decline(String callId) async => _updateStatus(callId, 'declined');

  Future<void> end(String callId) async => _updateStatus(callId, 'ended');
}
