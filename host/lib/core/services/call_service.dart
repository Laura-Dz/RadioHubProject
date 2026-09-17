import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../models/call.dart';
import 'cloud_function_caller.dart';
import 'realtime_database_service.dart';

class CallService {
  final _db = FirebaseFirestore.instance;
  FirebaseDatabase get _rtdb => RealtimeDatabaseService.database;

  Stream<List<Call>> streamCalls(String sessionId) {
    late StreamController<List<Call>> controller;
    StreamSubscription? firestoreSub;
    StreamSubscription? rtdbSub;

    final Map<String, Call> firestoreCalls = {};
    final Map<String, Call> rtdbCalls = {};

    void emitMerged() {
      if (controller.isClosed) return;
      final merged = <String, Call>{};
      // Firestore calls first
      merged.addAll(firestoreCalls);
      // RTDB calls overlay or add
      for (final entry in rtdbCalls.entries) {
        if (!merged.containsKey(entry.key)) {
          merged[entry.key] = entry.value;
        } else {
          // If RTDB has a more updated status, use it
          final existing = merged[entry.key]!;
          if (entry.value.status != existing.status) {
            merged[entry.key] = entry.value;
          }
        }
      }

      final list = merged.values.toList();
      list.sort((a, b) => a.requestedAt.compareTo(b.requestedAt));
      controller.add(list);
    }

    controller = StreamController<List<Call>>.broadcast(
      onListen: () {
        // 1. Listen to Firestore calls (without orderBy to avoid requiring composite indexes)
        firestoreSub = _db
            .collection('calls')
            .where('sessionId', isEqualTo: sessionId)
            .snapshots()
            .listen((snap) {
          firestoreCalls.clear();
          for (final doc in snap.docs) {
            try {
              firestoreCalls[doc.id] = Call.fromFirestore(doc.data(), doc.id);
            } catch (e) {
              debugPrint('Error parsing firestore call ${doc.id}: $e');
            }
          }
          emitMerged();
        }, onError: (err) {
          debugPrint('CallService firestore stream error: $err');
        });

        // 2. Listen to Realtime Database calls (instant WebSocket updates)
        try {
          rtdbSub = _rtdb.ref('calls/$sessionId').onValue.listen((event) {
            rtdbCalls.clear();
            final val = event.snapshot.value;
            if (val is Map) {
              val.forEach((k, v) {
                if (v is Map) {
                  try {
                    final map = Map<String, dynamic>.from(v);
                    rtdbCalls[k.toString()] = Call.fromMap(map, k.toString());
                  } catch (e) {
                    debugPrint('Error parsing RTDB call $k: $e');
                  }
                }
              });
            }
            emitMerged();
          }, onError: (err) {
            debugPrint('CallService RTDB stream error: $err');
          });
        } catch (e) {
          debugPrint('CallService RTDB init error: $e');
        }
      },
      onCancel: () {
        firestoreSub?.cancel();
        rtdbSub?.cancel();
      },
    );

    return controller.stream;
  }

  Future<void> _updateStatus(
    String callId,
    String status, {
    Map<String, dynamic>? extra,
    String? sessionId,
  }) async {
    // 1. Cloud Function attempt
    try {
      final res = await CloudFunctionCaller.call('updateCallStatus', {
        'callId': callId,
        'status': status,
      });
      if (res['success'] != true) {
        if (res['reason'] == 'another_on_call') {
          throw Exception('End the current call first');
        }
      }
    } catch (e) {
      debugPrint('updateCallStatus cloud function fallback: $e');
    }

    // 2. Direct Firestore update fallback
    try {
      final updateData = <String, dynamic>{'status': status};
      if (status == 'accepted') updateData['acceptedAt'] = FieldValue.serverTimestamp();
      if (status == 'held') {
        updateData['heldAt'] = FieldValue.serverTimestamp();
        updateData['holdCount'] = FieldValue.increment(1);
      }
      if (status == 'ended') updateData['endedAt'] = FieldValue.serverTimestamp();
      if (status == 'declined') updateData['declinedAt'] = FieldValue.serverTimestamp();
      if (extra != null) updateData.addAll(extra);

      await _db.collection('calls').doc(callId).update(updateData);
    } catch (dbErr) {
      debugPrint('Direct firestore call update error: $dbErr');
    }

    // 3. Direct Realtime Database update
    try {
      if (sessionId != null && sessionId.isNotEmpty) {
        final rtdbUpdate = <String, dynamic>{
          'status': status,
          'updatedAt': ServerValue.timestamp,
        };
        if (status == 'accepted') rtdbUpdate['acceptedAt'] = ServerValue.timestamp;
        if (status == 'held') rtdbUpdate['heldAt'] = ServerValue.timestamp;
        if (status == 'ended') rtdbUpdate['endedAt'] = ServerValue.timestamp;

        await _rtdb.ref('calls/$sessionId/$callId').update(rtdbUpdate);
      }
    } catch (rtdbErr) {
      debugPrint('Direct RTDB call update error: $rtdbErr');
    }
  }

  Future<void> accept(String callId, {String? sessionId}) async =>
      _updateStatus(callId, 'accepted', sessionId: sessionId);

  Future<void> hold(String callId, {String? sessionId}) async =>
      _updateStatus(callId, 'held', sessionId: sessionId);

  Future<void> decline(String callId, {String? sessionId}) async =>
      _updateStatus(callId, 'declined', sessionId: sessionId);

  Future<void> end(String callId, {String? sessionId}) async =>
      _updateStatus(callId, 'ended', sessionId: sessionId);
}
