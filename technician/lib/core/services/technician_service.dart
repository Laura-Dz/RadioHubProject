import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/technician/session_model.dart';
import '../models/technician/timetable_slot_model.dart';
import '../models/technician/program_model.dart';
import '../models/technician/program_category_model.dart';
import '../models/technician/host_model.dart';
import '../models/technician/media_item_model.dart';

class TechnicianService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============ PROGRAM CATEGORIES ============

  Stream<List<ProgramCategory>> streamCategories(String radioId) {
    return _db
        .collection('program_categories')
        .where('radioId', isEqualTo: radioId)
        .orderBy('name')
        .snapshots()
        .map((s) => s.docs
            .map((d) => ProgramCategory.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Seeds the default catalog if the radio has none yet.
  Future<void> ensureDefaultCategories(String radioId) async {
    final existing = await _db
        .collection('program_categories')
        .where('radioId', isEqualTo: radioId)
        .limit(1)
        .get();
    if (existing.docs.isNotEmpty) return;

    final batch = _db.batch();
    for (final name in ProgramCategory.defaultNames) {
      final ref = _db.collection('program_categories').doc();
      batch.set(ref, ProgramCategory(
        id: ref.id,
        radioId: radioId,
        name: name,
        isCustom: false,
        createdAt: DateTime.now(),
      ).toFirestore());
    }
    await batch.commit();
  }

  Future<String> createCategory(String radioId, String name) async {
    final clean = name.trim().toLowerCase();
    final dup = await _db
        .collection('program_categories')
        .where('radioId', isEqualTo: radioId)
        .where('name', isEqualTo: clean)
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) return dup.docs.first.id;

    final ref = await _db.collection('program_categories').add({
      'radioId': radioId,
      'name': clean,
      'isCustom': true,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ============ PAST SESSIONS FOR A PROGRAM (rediffusion picker) ============

  Future<List<Session>> getPastSessionsForProgram(
    String radioId,
    String programId,
  ) async {
    final snap = await _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('programId', isEqualTo: programId)
        .where('status', isEqualTo: 'ended')
        .where('isRediffusion', isEqualTo: false)
        .orderBy('scheduledStart', descending: true)
        .limit(50)
        .get();
    return snap.docs.map((d) => Session.fromFirestore(d.data(), d.id)).toList();
  }

  // ============ SESSION FOR SLOT ============

  /// Returns the session occupying a given timetable slot for a given date, if any.
  Future<Session?> getSessionForSlot(
    String radioId,
    String timetableSlotId,
    DateTime date,
  ) async {
    final dayStart = DateTime(date.year, date.month, date.day);
    final dayEnd = dayStart.add(const Duration(days: 1));
    final snap = await _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('timetableSlotId', isEqualTo: timetableSlotId)
        .where('scheduledStart',
            isGreaterThanOrEqualTo: Timestamp.fromDate(dayStart))
        .where('scheduledStart', isLessThan: Timestamp.fromDate(dayEnd))
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return Session.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
  }

  /// Creates a scheduled session bound to a timetable slot.
  /// Does NOT start it — the technician starts it later via startSession().
  Future<String> initializeSessionForSlot({
    required TimetableSlot slot,
    required DateTime date,
    required String hostId,
    required String hostName,
    List<String> coHostIds = const [],
    List<String> coHostNames = const [],
    String? guestName,
    String? guestRole,
    String? thematic,
  }) async {
    final start = slot.dateFor(date);
    final end = slot.endDateFor(date);

    final ref = _db.collection('sessions').doc();
    await ref.set({
      'radioId': slot.radioId,
      'timetableSlotId': slot.id,
      'programId': slot.programId,
      'programName': slot.programName,
      'hostId': hostId,
      'hostName': hostName,
      'coHostIds': coHostIds,
      'coHostNames': coHostNames,
      'guestName': guestName,
      'guestRole': guestRole,
      'thematic': thematic,
      'scheduledStart': Timestamp.fromDate(start),
      'scheduledEnd': Timestamp.fromDate(end),
      'status': 'scheduled',
      'isRediffusion': false,
      'sessionCode': null,
      'allowCalls': true,
      'listenerCount': 0,
      'completionRate': 0,
      'engagementCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    return ref.id;
  }

  /// Schedule a rediffusion bound to a slot.
  Future<String> rediffuseSlot({
    required TimetableSlot slot,
    required DateTime date,
    required Session source,
  }) async {
    final start = slot.dateFor(date);
    final end = slot.endDateFor(date);
    final ref = _db.collection('sessions').doc();
    await ref.set({
      'radioId': slot.radioId,
      'timetableSlotId': slot.id,
      'programId': slot.programId,
      'programName': slot.programName,
      'hostId': source.hostId,
      'hostName': source.hostName,
      'thematic': source.thematic,
      'description': source.description,
      'scheduledStart': Timestamp.fromDate(start),
      'scheduledEnd': Timestamp.fromDate(end),
      'status': 'scheduled',
      'isRediffusion': true,
      'sourceSessionId': source.id,
      'recordingUrl': source.recordingUrl,
      'allowCalls': false,
      'listenerCount': 0,
      'completionRate': 0,
      'engagementCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  // ============ SESSIONS ============

  Stream<List<Session>> streamSessions(String radioId) {
    return _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .orderBy('scheduledStart', descending: true)
        .limit(200)
        .snapshots()
        .map((s) => s.docs.map((d) => Session.fromFirestore(d.data(), d.id)).toList());
  }

  Stream<List<Session>> streamLiveSessions(String radioId) {
    return _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('status', isEqualTo: 'live')
        .snapshots()
        .map((s) => s.docs.map((d) => Session.fromFirestore(d.data(), d.id)).toList());
  }

  Stream<List<Session>> streamPastSessionsForRediffusion(String radioId) {
    return _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('status', isEqualTo: 'ended')
        .where('isRediffusion', isEqualTo: false)
        .orderBy('scheduledStart', descending: true)
        .limit(50)
        .snapshots()
        .map((s) => s.docs.map((d) => Session.fromFirestore(d.data(), d.id)).toList());
  }

  /// Create a scheduled session (no code yet).
  Future<String> createSession(Session session) async {
    final ref = _db.collection('sessions').doc();
    await ref.set(session.toFirestore());
    return ref.id;
  }

  Future<void> updateSession(String sessionId, Map<String, dynamic> updates) async {
    await _db.collection('sessions').doc(sessionId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Start a session — sets status=live, actualStart, generates host code.
  /// Does NOT touch audio (that's external).
  Future<String> startSession(String sessionId) async {
    final code = _generateCode();
    await _db.collection('sessions').doc(sessionId).update({
      'status': 'live',
      'actualStart': FieldValue.serverTimestamp(),
      'sessionCode': code,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return code;
  }

  Future<void> endSession(String sessionId) async {
    await _db.collection('sessions').doc(sessionId).update({
      'status': 'ended',
      'actualEnd': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> cancelSession(String sessionId, String reason) async {
    await _db.collection('sessions').doc(sessionId).update({
      'status': 'cancelled',
      'cancelReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Schedule a rediffusion — copies metadata, blocks calls, points at source.
  Future<String> scheduleRediffusion({
    required String radioId,
    required Session source,
    required DateTime scheduledStart,
    required DateTime scheduledEnd,
  }) async {
    final ref = _db.collection('sessions').doc();
    await ref.set({
      'radioId': radioId,
      'programId': source.programId,
      'programName': source.programName,
      'hostId': source.hostId,
      'hostName': source.hostName,
      'thematic': source.thematic,
      'description': source.description,
      'format': source.format,
      'scheduledStart': Timestamp.fromDate(scheduledStart),
      'scheduledEnd': Timestamp.fromDate(scheduledEnd),
      'status': 'scheduled',
      'isRediffusion': true,
      'sourceSessionId': source.id,
      'recordingUrl': source.recordingUrl,
      'allowCalls': false,
      'listenerCount': 0,
      'completionRate': 0,
      'engagementCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return ref.id;
  }

  /// Generates a 6-char code like "MDR-4K7P".
  String _generateCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
    final rnd = Random.secure();
    final prefix = List.generate(3, (_) => chars[rnd.nextInt(chars.length)]).join();
    final suffix = List.generate(4, (_) => chars[rnd.nextInt(chars.length)]).join();
    return '$prefix-$suffix';
  }

  // ============ TIMETABLE ============

  Stream<List<TimetableSlot>> streamTimetable(String radioId) {
    return _db
        .collection('timetable')
        .where('radioId', isEqualTo: radioId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => TimetableSlot.fromFirestore(d.data(), d.id))
              .toList();
          list.sort((a, b) {
            if (a.weekday != b.weekday) return a.weekday.compareTo(b.weekday);
            if (a.startHour != b.startHour) return a.startHour.compareTo(b.startHour);
            return a.startMinute.compareTo(b.startMinute);
          });
          return list;
        });
  }

  Future<String> createSlot(TimetableSlot slot) async {
    final ref = await _db.collection('timetable').add(slot.toFirestore());
    return ref.id;
  }

  Future<void> updateSlot(String slotId, Map<String, dynamic> updates) async {
    await _db.collection('timetable').doc(slotId).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> upsertSlot(TimetableSlot slot) async {
    if (slot.id.isEmpty) {
      await _db.collection('timetable').add(slot.toFirestore());
    } else {
      await _db.collection('timetable').doc(slot.id).update(slot.toFirestore());
    }
  }

  Future<void> deleteSlot(String slotId) async {
    await _db.collection('timetable').doc(slotId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ PROGRAMS ============

  Stream<List<Program>> streamPrograms(String radioId) {
    return _db
        .collection('programs')
        .where('radioId', isEqualTo: radioId)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Program.fromFirestore(d.data(), d.id)).toList();
          list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return list;
        });
  }

  Future<String> createProgram(Program p) async {
    final ref = await _db.collection('programs').add(p.toFirestore());
    return ref.id;
  }

  Future<void> updateProgram(String id, Map<String, dynamic> updates) async {
    await _db.collection('programs').doc(id).update({
      ...updates,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> archiveProgram(String id) async {
    await _db.collection('programs').doc(id).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ============ HOSTS (read-only) ============

  Stream<List<Host>> streamHosts(String radioId) {
    return _db
        .collection('users')
        .where('radioId', isEqualTo: radioId)
        .where('role', isEqualTo: 'host')
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Host.fromFirestore(d.data(), d.id)).toList();
          list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return list;
        });
  }

  // ============ MEDIA ============

  Stream<List<MediaItem>> streamMedia(String radioId) {
    return _db
        .collection('media')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .map((s) => s.docs.map((d) => MediaItem.fromFirestore(d.data(), d.id)).toList());
  }

  Future<String> createMediaItem(MediaItem item) async {
    final ref = await _db.collection('media').add(item.toFirestore());
    return ref.id;
  }

  Future<void> deleteMediaItem(String mediaId) async {
    await _db.collection('media').doc(mediaId).delete();
  }
}
