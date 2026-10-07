import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/technician/session_model.dart';
import '../models/technician/timetable_slot_model.dart';
import '../models/technician/program_model.dart';
import '../models/technician/program_category_model.dart';
import '../models/technician/host_model.dart';
import '../models/technician/media_item_model.dart';
import '../models/technician/notification_model.dart';
import '../models/technician/metrics_model.dart';
import 'network_time_service.dart';

class TechnicianService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ============ PROGRAM CATEGORIES ============

  Stream<List<ProgramCategory>> streamCategories(String radioId) {
    return _db
        .collection('program_categories')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => ProgramCategory.fromFirestore(d.data(), d.id))
              .toList();
          list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
          return list;
        });
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
    try {
      final snap = await _db
          .collection('sessions')
          .where('programId', isEqualTo: programId)
          .get();

      final now = DateTime.now();
      final list = snap.docs
          .map((d) => Session.fromFirestore(d.data(), d.id))
          .where((s) {
            if (radioId.isNotEmpty && s.radioId.isNotEmpty && s.radioId != radioId) {
              return false;
            }
            if (s.isRediffusion) return false;
            if (s.status == SessionStatus.onAir) return false;
            return s.status == SessionStatus.ended ||
                s.actualEnd != null ||
                s.scheduledEnd.isBefore(now) ||
                s.scheduledStart.isBefore(now);
          })
          .toList();

      list.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
      return list.take(50).toList();
    } catch (e) {
      debugPrint('getPastSessionsForProgram error: $e');
      return [];
    }
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
  /// Creates a scheduled session bound to a timetable slot.
  /// Does NOT start it — the technician starts it later via startSession().
  Future<String> initializeSessionForSlot({
    required TimetableSlot slot,
    required DateTime date,
    required String hostId,
    required String hostName,
    List<String> coHostIds = const [],
    List<String> coHostNames = const [],
    List<Map<String, String>> guests = const [],
    String? guestName,
    String? guestRole,
    String? thematic,
  }) async {
    final start = slot.dateFor(date);
    final end = slot.endDateFor(date);

    try {
      final ref = _db.collection('sessions').doc();
      final effectiveGuests = guests.isNotEmpty
          ? guests
          : (guestName != null && guestName.isNotEmpty
              ? [{'name': guestName, 'role': guestRole ?? ''}]
              : <Map<String, String>>[]);
      final effectiveGuestName = guestName ?? (effectiveGuests.isNotEmpty ? effectiveGuests.first['name'] : null);
      final effectiveGuestRole = guestRole ?? (effectiveGuests.isNotEmpty ? effectiveGuests.first['role'] : null);

      await ref.set({
        'radioId': slot.radioId,
        'timetableSlotId': slot.id,
        'programId': slot.programId,
        'programName': slot.programName,
        'hostId': hostId,
        'hostName': hostName,
        'coHostIds': coHostIds,
        'coHostNames': coHostNames,
        'guests': effectiveGuests,
        'guestName': effectiveGuestName,
        'guestRole': effectiveGuestRole,
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
    } on FirebaseException catch (e, st) {
      debugPrint('=== INITIALIZE SESSION FOR SLOT FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  /// Schedule a rediffusion bound to a slot.
  Future<String> rediffuseSlot({
    required TimetableSlot slot,
    required DateTime date,
    required Session source,
  }) async {
    final start = slot.dateFor(date);
    final end = slot.endDateFor(date);
    try {
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
    } on FirebaseException catch (e, st) {
      debugPrint('=== REDIFFUSE SLOT FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  // ============ SESSIONS ============

  Stream<List<Session>> streamSessions(String radioId) {
    return _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .limit(200)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Session.fromFirestore(d.data(), d.id)).toList();
          list.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
          return list;
        });
  }

  Stream<List<Session>> streamLiveSessions(String radioId) {
    return _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('status', isEqualTo: 'on_air')
        .snapshots()
        .map((s) => s.docs.map((d) => Session.fromFirestore(d.data(), d.id)).toList());
  }

  /// Real-time stream of upcoming scheduled sessions for this radio (next 24h rolling look-ahead).
  Stream<List<Session>> streamUpcomingSessions(String radioId) {
    return _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('status', isEqualTo: 'scheduled')
        .limit(100)
        .snapshots()
        .map((snap) {
          final now = NetworkTimeService().now();
          final tomorrow = now.add(const Duration(hours: 24));
          final list = snap.docs
              .map((d) => Session.fromFirestore(d.data(), d.id))
              .where((s) =>
                  s.scheduledEnd.isAfter(now) &&
                  s.scheduledStart.isBefore(tomorrow))
              .toList();
          list.sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));
          return list;
        });
  }

  /// Real-time stream of the currently live session, if any.
  Stream<Session?> streamCurrentLiveSession(String radioId) {
    return _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('status', isEqualTo: 'on_air')
        .limit(1)
        .snapshots()
        .map((snap) => snap.docs.isEmpty
            ? null
            : Session.fromFirestore(snap.docs.first.data(), snap.docs.first.id));
  }

  /// Real-time stream of the last 20 ended sessions.
  Stream<List<Session>> streamRecentEndedSessions(String radioId) {
    return _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('status', isEqualTo: 'ended')
        .limit(50)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((d) => Session.fromFirestore(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
          return list.take(20).toList();
        });
  }

  Stream<List<Session>> streamPastSessionsForRediffusion(String radioId) {
    return _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('status', isEqualTo: 'ended')
        .where('isRediffusion', isEqualTo: false)
        .limit(100)
        .snapshots()
        .map((s) {
          final list = s.docs.map((d) => Session.fromFirestore(d.data(), d.id)).toList();
          list.sort((a, b) => b.scheduledStart.compareTo(a.scheduledStart));
          return list.take(50).toList();
        });
  }

  /// Create a scheduled session (no code yet).
  Future<String> createSession(Session session) async {
    try {
      final ref = _db.collection('sessions').doc();
      await ref.set(session.toFirestore());
      return ref.id;
    } on FirebaseException catch (e, st) {
      debugPrint('=== CREATE SESSION FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  Future<void> updateSession(String sessionId, Map<String, dynamic> updates) async {
    try {
      await _db.collection('sessions').doc(sessionId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, st) {
      debugPrint('=== UPDATE SESSION FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  /// Returns the id of the currently live session for this radio, if any.
  Future<String?> getLiveSessionId(String radioId) async {
    final snap = await _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('status', isEqualTo: 'on_air')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  /// Start a session. Fails if another session is already live for this radio,
  /// or if the session is outside the 5-minute start window.
  Future<String> startSession(String sessionId) async {
    // 1. Load the session
    final doc = await _db.collection('sessions').doc(sessionId).get();
    if (!doc.exists) throw Exception('Session not found');
    final session = Session.fromFirestore(doc.data()!, sessionId);
    final radioId = session.radioId;

    // 2. Time-window guard
    if (!session.isWithinStartWindow) {
      final diff = session.minutesUntilStart;
      if (diff > 0) {
        throw Exception('You can start this session in $diff minute(s).');
      }
      throw Exception('The start window for this session has closed.');
    }

    // 3. Live-collision guard
    final liveId = await getLiveSessionId(radioId);
    if (liveId != null && liveId != sessionId) {
      final liveDoc = await _db.collection('sessions').doc(liveId).get();
      final liveName = liveDoc.data()?['programName'] ?? 'another session';
      throw Exception(
        'A session is already live ($liveName). End it before starting another.',
      );
    }

    // 4. Start
    try {
      final code = _generateCode();
      await _db.collection('sessions').doc(sessionId).update({
        'status': 'on_air',
        'actualStart': FieldValue.serverTimestamp(),
        'sessionCode': code,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // 5. Mark the radio's currently-live pointer (single source of truth)
      await _db.collection('radios').doc(radioId).update({
        'currentLiveSessionId': sessionId,
        'currentLiveSince': FieldValue.serverTimestamp(),
      });

      return code;
    } on FirebaseException catch (e, st) {
      debugPrint('=== START SESSION FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  /// Creates an intermediary block for a slot. No host. No code.
  /// Used for spots, jingles, and low-priority announcements.
  Future<String> createIntermediary({
    required TimetableSlot slot,
    required DateTime date,
  }) async {
    final start = slot.dateFor(date);
    final end = slot.endDateFor(date);
    final ref = _db.collection('sessions').doc();

    final data = {
      'radioId': slot.radioId,
      'timetableSlotId': slot.id,
      'programId': slot.programId,
      'programName': slot.programName,
      'sessionType': 'intermediary',
      'hostId': null,
      'hostName': null,
      'scheduledStart': Timestamp.fromDate(start),
      'scheduledEnd': Timestamp.fromDate(end),
      'status': 'scheduled',
      'isRediffusion': false,
      'allowCalls': false,
      'allowComments': true,
      'listenerCount': 0,
      'completionRate': 0,
      'engagementCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await ref.set(data);
      debugPrint('INTERMEDIARY CREATED: ${ref.id}');
      return ref.id;
    } on FirebaseException catch (e, st) {
      debugPrint('=== INTERMEDIARY WRITE FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  /// End the currently live session. Also clears the radio's live pointer.
  Future<void> endSession(String sessionId) async {
    final doc = await _db.collection('sessions').doc(sessionId).get();
    if (!doc.exists) throw Exception('Session not found');
    final radioId = (doc.data()?['radioId'] ?? '').toString();

    try {
      await _db.collection('sessions').doc(sessionId).update({
        'status': 'ended',
        'actualEnd': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (radioId.isNotEmpty) {
        await _db.collection('radios').doc(radioId).update({
          'currentLiveSessionId': FieldValue.delete(),
          'currentLiveSince': FieldValue.delete(),
        });
      }
    } on FirebaseException catch (e, st) {
      debugPrint('=== END SESSION FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  /// Convenience — start a session and immediately generate the code.
  /// Same as startSession but returns both.
  Future<Map<String, String>> startSessionWithCode(String sessionId) async {
    final code = await startSession(sessionId);
    return {'sessionId': sessionId, 'sessionCode': code};
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
    final rnd = math.Random.secure();
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
    try {
      final ref = await _db.collection('timetable').add(slot.toFirestore());
      return ref.id;
    } on FirebaseException catch (e, st) {
      debugPrint('=== CREATE SLOT FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  Future<void> updateSlot(String slotId, Map<String, dynamic> updates) async {
    try {
      await _db.collection('timetable').doc(slotId).update({
        ...updates,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, st) {
      debugPrint('=== UPDATE SLOT FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  Future<void> upsertSlot(TimetableSlot slot) async {
    try {
      if (slot.id.isEmpty) {
        await _db.collection('timetable').add(slot.toFirestore());
      } else {
        await _db.collection('timetable').doc(slot.id).update(slot.toFirestore());
      }
    } on FirebaseException catch (e, st) {
      debugPrint('=== UPSERT SLOT FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  Future<void> deleteSlot(String slotId) async {
    try {
      await _db.collection('timetable').doc(slotId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e, st) {
      debugPrint('=== DELETE SLOT FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
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
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => Host.fromFirestore(d.data(), d.id))
              .where((h) =>
                  h.status.toLowerCase() != 'inactive' &&
                  h.status.toLowerCase() != 'suspended')
              .toList();
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
        .map((s) {
          final list = s.docs
              .map((d) => MediaItem.fromFirestore(d.data(), d.id))
              .toList();
          list.sort((a, b) => b.uploadedAt.compareTo(a.uploadedAt));
          return list;
        });
  }

  Future<String> createMedia(MediaItem item) async {
    final ref = await _db.collection('media').add({
      ...item.toFirestore(),
      'uploadedBy': _auth.currentUser?.uid ?? '',
    });
    return ref.id;
  }

  Future<String> createMediaItem(MediaItem item) => createMedia(item);

  Future<void> deleteMedia(String id) async {
    await _db.collection('media').doc(id).delete();
  }

  Future<void> deleteMediaItem(String id) => deleteMedia(id);

  Future<void> updateMedia(String id, Map<String, dynamic> updates) async {
    await _db.collection('media').doc(id).update(updates);
  }

  // ============ OVERLAP CHECK ============

  /// Returns true if [candidate] overlaps any existing slot on the same weekday.
  /// Pass [excludeSlotId] when editing to skip the slot being edited.
  bool timetableOverlaps(
    List<TimetableSlot> existing,
    TimetableSlot candidate, {
    String? excludeSlotId,
  }) {
    final aStart = candidate.startHour * 60 + candidate.startMinute;
    final aEnd = candidate.endHour * 60 + candidate.endMinute;
    for (final s in existing) {
      if (s.id == excludeSlotId) continue;
      if (s.weekday != candidate.weekday) continue;
      final bStart = s.startHour * 60 + s.startMinute;
      final bEnd = s.endHour * 60 + s.endMinute;
      if (aStart < bEnd && bStart < aEnd) return true;
    }
    return false;
  }

  // ============ AUTO-GENERATE TIMETABLE SLOTS ============

  /// Generates timetable slots for a program based on its recurrence pattern.
  /// Skips any day/time that would overlap with an existing slot.
  Future<int> generateTimetableFromProgram({
    required Program program,
    required List<TimetableSlot> existing,
  }) async {
    if (program.recurrenceType == RecurrenceType.none) return 0;
    if (program.defaultStartHour == null) return 0;

    final startH = program.defaultStartHour!;
    final startM = program.defaultStartMinute ?? 0;
    final endMinutes = startH * 60 + startM + program.defaultDurationMinutes;
    final endH = (endMinutes ~/ 60) % 24;
    final endM = endMinutes % 60;

    final days = program.recurrenceType.resolveDays(program.recurrenceDays);
    int created = 0;

    for (final wd in days) {
      final candidate = TimetableSlot(
        id: '',
        radioId: program.radioId,
        programId: program.id,
        programName: program.name,
        weekday: wd,
        startHour: startH,
        startMinute: startM,
        endHour: endH,
        endMinute: endM,
        hostIds: program.hostIds,
        hostNames: program.hostNames,
        createdAt: DateTime.now(),
      );
      if (timetableOverlaps(existing, candidate)) continue;
      await createSlot(candidate);
      created++;
    }
    return created;
  }

  // ============ SPECIAL EVENTS ============

  /// Creates a special event or flash. Always tied to a live broadcast.
  Future<String> createSpecialEvent({
    required String radioId,
    required String title,
    required SessionType type,
    required DateTime start,
    required DateTime end,
    String? description,
    String? hostId,
    String? hostName,
  }) async {
    final ref = _db.collection('sessions').doc();

    final data = {
      'radioId': radioId,
      'timetableSlotId': null,
      'programId': null,
      'programName': title,
      'sessionType': type == SessionType.flash ? 'flash' : 'special',
      'hostId': hostId,
      'hostName': hostName,
      'description': description,
      'scheduledStart': Timestamp.fromDate(start),
      'scheduledEnd': Timestamp.fromDate(end),
      'status': 'scheduled',
      'isRediffusion': false,
      'allowCalls': true,
      'allowComments': true,
      'listenerCount': 0,
      'completionRate': 0,
      'engagementCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    try {
      await ref.set(data);
      debugPrint('SPECIAL EVENT CREATED: ${ref.id}');
      return ref.id;
    } on FirebaseException catch (e, st) {
      debugPrint('=== SPECIAL EVENT WRITE FAILED ===');
      debugPrint('code: ${e.code}');
      debugPrint('message: ${e.message}');
      debugPrint('stack: $st');
      rethrow;
    }
  }

  // ============ NOTIFICATIONS ============

  Stream<List<NotificationItem>> streamNotifications(String radioId) {
    return _db
        .collection('notifications')
        .where('radioId', isEqualTo: radioId)
        .limit(100)
        .snapshots()
        .map((s) {
          final list = s.docs
              .map((d) => NotificationItem.fromFirestore(d.data(), d.id))
              .where((n) => n.recipientRole == 'technician' || n.recipientRole == 'all')
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Future<void> markNotificationRead(String id) async {
    await _db.collection('notifications').doc(id).update({'isRead': true});
  }

  Future<void> markAllNotificationsRead(String radioId) async {
    final snap = await _db
        .collection('notifications')
        .where('radioId', isEqualTo: radioId)
        .where('recipientRole', whereIn: ['technician', 'all'])
        .where('isRead', isEqualTo: false)
        .get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      batch.update(doc.reference, {'isRead': true});
    }
    await batch.commit();
  }

  // ==================== AGGREGATE METRICS ====================

  Future<RadioMetrics> computeMetrics(String radioId, String period) async {
    final now = DateTime.now();
    final days = switch (period) {
      '24h' => 1,
      '7d' => 7,
      '30d' => 30,
      '90d' => 90,
      _ => 7,
    };
    final cutoff = now.subtract(Duration(days: days));

    // 1. Fetch sessions in the period
    final sessionsSnap = await _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .where('scheduledStart', isGreaterThanOrEqualTo: cutoff)
        .where('status', isEqualTo: 'ended')
        .limit(500)
        .get();

    final sessions = sessionsSnap.docs.map((d) {
      final data = d.data();
      return SessionPerformance(
        id: d.id,
        programName: (data['programName'] ?? 'Unknown').toString(),
        start: (data['scheduledStart'] as Timestamp?)?.toDate() ?? now,
        peakListeners: (data['peakListeners'] ?? data['listenerCount'] ?? 0) as int,
        avgListeners: (data['listenerCount'] ?? 0) as int,
        comments: (data['commentsCount'] ?? 0) as int,
        calls: (data['callsCount'] ?? 0) as int,
        likes: (data['likesCount'] ?? 0) as int,
        shares: (data['sharesCount'] ?? 0) as int,
        retention: (data['completionRate'] ?? 0).toDouble(),
      );
    }).toList();

    // 2. Audimat totals
    int totalListeners = 0;
    int peakListeners = 0;
    int totalComments = 0;
    int totalCalls = 0;
    int totalLikes = 0;
    int totalShares = 0;

    for (final s in sessions) {
      totalListeners += s.avgListeners;
      peakListeners = math.max(peakListeners, s.peakListeners);
      totalComments += s.comments;
      totalCalls += s.calls;
      totalLikes += s.likes;
      totalShares += s.shares;
    }

    final totalInteractions =
        totalComments + totalCalls + totalLikes + totalShares;
    final avgListeners = sessions.isEmpty ? 0 : totalListeners ~/ sessions.length;
    final interactionsPerListener =
        totalListeners == 0 ? 0.0 : totalInteractions / totalListeners;

    // 3. Growth: second half vs first half by date
    sessions.sort((a, b) => a.start.compareTo(b.start));
    final half = sessions.length ~/ 2;
    final first = sessions.take(half).fold<int>(0, (s, x) => s + x.avgListeners);
    final second =
        sessions.skip(half).fold<int>(0, (s, x) => s + x.avgListeners);
    final growth =
        first == 0 ? 0.0 : ((second - first) / first) * 100;

    // 4. Time series from listener_analytics
    final analyticsSnap = await _db
        .collection('listener_analytics')
        .where('radioId', isEqualTo: radioId)
        .where('date', isGreaterThanOrEqualTo: cutoff)
        .orderBy('date')
        .limit(5000)
        .get();

    final trend = <ListenerPoint>[];
    for (final doc in analyticsSnap.docs) {
      final d = doc.data();
      final date = (d['date'] as Timestamp?)?.toDate();
      if (date == null) continue;
      trend.add(ListenerPoint(
        date,
        (d['count'] ?? 0) as int,
        comments: (d['comments'] ?? 0) as int,
        calls: (d['calls'] ?? 0) as int,
      ));
    }
    trend.sort((a, b) => a.time.compareTo(b.time));

    // 5. Hourly buckets
    final hourSums = List<int>.filled(24, 0);
    final hourCounts = List<int>.filled(24, 0);
    for (final p in trend) {
      hourSums[p.time.hour] += p.count;
      hourCounts[p.time.hour]++;
    }
    final byHour = List.generate(24, (h) => HourPoint(
          '${h.toString().padLeft(2, '0')}h',
          hourCounts[h] == 0 ? 0 : hourSums[h] ~/ hourCounts[h],
        ));

    // 6. Daily buckets
    final dayMap = <String, int>{};
    for (final p in trend) {
      final key =
          '${p.time.year}-${p.time.month.toString().padLeft(2, '0')}-${p.time.day.toString().padLeft(2, '0')}';
      dayMap[key] = (dayMap[key] ?? 0) + p.count;
    }
    final byDay = dayMap.entries
        .map((e) => DayPoint(e.key.substring(5), e.value))
        .toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    // 7. Per-program aggregates
    final progAccum = <String, List<SessionPerformance>>{};
    for (final s in sessions) {
      progAccum.putIfAbsent(s.programName, () => []).add(s);
    }
    final byProgram = progAccum.entries.map((e) {
      final list = e.value;
      final avgL =
          list.fold<int>(0, (s, x) => s + x.avgListeners) ~/ list.length;
      final peakL =
          list.map((x) => x.peakListeners).reduce((a, b) => math.max(a, b));
      final inter =
          list.fold<int>(0, (s, x) => s + x.totalInteractions);
      final ret = list.fold<double>(0, (s, x) => s + x.retention) /
          list.length;
      return ProgramPerformance(
        programName: e.key,
        avgListeners: avgL,
        peakListeners: peakL,
        totalSessions: list.length,
        totalInteractions: inter,
        avgRetention: ret,
      );
    }).toList()
      ..sort((a, b) => b.avgListeners.compareTo(a.avgListeners));

    // 8. Top sessions
    final topAudience = [...sessions]
      ..sort((a, b) => b.avgListeners.compareTo(a.avgListeners));
    final topInteraction = [...sessions]
      ..sort((a, b) => b.totalInteractions.compareTo(a.totalInteractions));

    return RadioMetrics(
      totalListeners: totalListeners,
      peakListeners: peakListeners,
      avgListeners: avgListeners,
      growthPercent: growth,
      totalComments: totalComments,
      totalCalls: totalCalls,
      totalLikes: totalLikes,
      totalShares: totalShares,
      totalInteractions: totalInteractions,
      interactionsPerListener: interactionsPerListener,
      trend: trend,
      byHour: byHour,
      byDay: byDay,
      byProgram: byProgram.take(8).toList(),
      topByAudience: topAudience.take(5).toList(),
      topByInteraction: topInteraction.take(5).toList(),
    );
  }

  // ==================== LIVE METRICS ====================

  /// Streams real-time metrics for a live session.
  /// Reads the session doc (updated by the listener app on every interaction)
  /// and the session's own listener_analytics subcollection for the trend.
  Stream<LiveMetrics> streamLiveMetrics(String sessionId) {
    return _db
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .asyncMap((doc) async {
      if (!doc.exists) {
        return LiveMetrics(since: DateTime.now());
      }
      final d = doc.data()!;
      final since =
          (d['actualStart'] as Timestamp?)?.toDate() ?? DateTime.now();

      // Fetch recent listener samples for this session
      List<ListenerPoint> recent = [];
      try {
        final samples = await _db
            .collection('listener_analytics')
            .where('sessionId', isEqualTo: sessionId)
            .orderBy('date', descending: true)
            .limit(30)
            .get();
        recent = samples.docs.map((s) {
          final sd = s.data();
          return ListenerPoint(
            (sd['date'] as Timestamp).toDate(),
            (sd['count'] ?? 0) as int,
          );
        }).toList()
          ..sort((a, b) => a.time.compareTo(b.time));
      } catch (_) {
        // Index may be missing — proceed without the trend
      }

      return LiveMetrics(
        sessionId: sessionId,
        currentListeners: (d['listenerCount'] ?? 0) as int,
        peakListeners: (d['peakListeners'] ?? d['listenerCount'] ?? 0) as int,
        comments: (d['commentsCount'] ?? 0) as int,
        calls: (d['callsCount'] ?? 0) as int,
        likes: (d['likesCount'] ?? 0) as int,
        shares: (d['sharesCount'] ?? 0) as int,
        since: since,
        recentTrend: recent,
      );
    });
  }
}
