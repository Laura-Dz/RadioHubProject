import 'dart:async';
import 'package:flutter/material.dart';
import '../core/models/technician/session_model.dart';
import '../core/models/technician/timetable_slot_model.dart';
import '../core/models/technician/program_model.dart';
import '../core/models/technician/program_category_model.dart';
import '../core/models/technician/host_model.dart';
import '../core/models/technician/media_item_model.dart';
import '../core/services/technician_service.dart';

class TechnicianViewModel extends ChangeNotifier {
  final TechnicianService _service;

  String _radioId = '';
  String _radioName = '';
  String _technicianName = '';
  bool _isInitialized = false;

  List<ProgramCategory> _categories = [];
  List<Session> _sessions = [];
  List<Session> _liveSessions = [];
  List<Session> _rediffusionCandidates = [];
  List<TimetableSlot> _timetable = [];
  List<Program> _programs = [];
  List<Host> _hosts = [];
  List<MediaItem> _mediaItems = [];

  StreamSubscription? _categoriesSub;
  StreamSubscription? _sessionsSub;
  StreamSubscription? _liveSub;
  StreamSubscription? _rediffSub;
  StreamSubscription? _timetableSub;
  StreamSubscription? _programsSub;
  StreamSubscription? _hostsSub;
  StreamSubscription? _mediaSub;

  TechnicianViewModel({required TechnicianService service}) : _service = service;

  // Getters
  String get radioId => _radioId;
  String get radioName => _radioName;
  String get technicianName => _technicianName;
  bool get isInitialized => _isInitialized;
  List<ProgramCategory> get categories => _categories;
  List<Session> get sessions => _sessions;
  List<Session> get liveSessions => _liveSessions;
  List<Session> get rediffusionCandidates => _rediffusionCandidates;
  List<TimetableSlot> get timetable => _timetable;
  List<Program> get programs => _programs;
  List<Host> get hosts => _hosts;
  List<MediaItem> get mediaItems => _mediaItems;

  void initialize({
    required String radioId,
    required String radioName,
    required String technicianName,
  }) {
    if (_isInitialized && _radioId == radioId) return;
    _radioId = radioId;
    _radioName = radioName;
    _technicianName = technicianName;
    _isInitialized = true;
    _attachStreams();
    _service.ensureDefaultCategories(_radioId);
  }

  void _attachStreams() {
    _detachStreams();

    _categoriesSub = _service.streamCategories(_radioId).listen((list) {
      _categories = list;
      notifyListeners();
    });
    _sessionsSub = _service.streamSessions(_radioId).listen((list) {
      _sessions = list;
      notifyListeners();
    });
    _liveSub = _service.streamLiveSessions(_radioId).listen((list) {
      _liveSessions = list;
      notifyListeners();
    });
    _rediffSub = _service.streamPastSessionsForRediffusion(_radioId).listen((list) {
      _rediffusionCandidates = list;
      notifyListeners();
    });
    _timetableSub = _service.streamTimetable(_radioId).listen((list) {
      _timetable = list;
      notifyListeners();
    });
    _programsSub = _service.streamPrograms(_radioId).listen((list) {
      _programs = list;
      notifyListeners();
    });
    _hostsSub = _service.streamHosts(_radioId).listen((list) {
      _hosts = list;
      notifyListeners();
    });
    _mediaSub = _service.streamMedia(_radioId).listen((list) {
      _mediaItems = list;
      notifyListeners();
    });
  }

  void _detachStreams() {
    _categoriesSub?.cancel();
    _sessionsSub?.cancel();
    _liveSub?.cancel();
    _rediffSub?.cancel();
    _timetableSub?.cancel();
    _programsSub?.cancel();
    _hostsSub?.cancel();
    _mediaSub?.cancel();
  }

  // ============ CATEGORIES ============

  Future<String> createCategory(String name) =>
      _service.createCategory(_radioId, name);

  // ============ SESSIONS ============

  Future<String> createSession(Session session) async {
    final id = await _service.createSession(session);
    return id;
  }

  Future<String> startSession(String sessionId) async {
    return await _service.startSession(sessionId);
  }

  Future<void> endSession(String sessionId) async {
    await _service.endSession(sessionId);
  }

  Future<void> cancelSession(String sessionId, String reason) async {
    await _service.cancelSession(sessionId, reason);
  }

  Future<String> scheduleRediffusion({
    required Session source,
    required DateTime start,
    required DateTime end,
  }) async {
    return await _service.scheduleRediffusion(
      radioId: _radioId,
      source: source,
      scheduledStart: start,
      scheduledEnd: end,
    );
  }

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
  }) =>
      _service.initializeSessionForSlot(
        slot: slot,
        date: date,
        hostId: hostId,
        hostName: hostName,
        coHostIds: coHostIds,
        coHostNames: coHostNames,
        guestName: guestName,
        guestRole: guestRole,
        thematic: thematic,
      );

  Future<String> rediffuseSlot({
    required TimetableSlot slot,
    required DateTime date,
    required Session source,
  }) =>
      _service.rediffuseSlot(slot: slot, date: date, source: source);

  Future<List<Session>> pastSessionsForProgram(String programId) =>
      _service.getPastSessionsForProgram(_radioId, programId);

  // ============ TIMETABLE ============

  Future<void> upsertSlot(TimetableSlot slot) async {
    await _service.upsertSlot(slot);
  }

  Future<String> createSlot(TimetableSlot slot) => _service.createSlot(slot);

  Future<void> updateSlot(String slotId, Map<String, dynamic> updates) =>
      _service.updateSlot(slotId, updates);

  Future<void> deleteSlot(String slotId) async {
    await _service.deleteSlot(slotId);
  }

  List<TimetableSlot> slotsForDay(int weekday) =>
      _timetable.where((s) => s.weekday == weekday).toList();

  /// Generate sessions for the next `days` days from the timetable.
  /// Skips any date/slot where a session already exists.
  Future<int> generateFromTimetable({int days = 14}) async {
    final now = DateTime.now();
    final cutoff = now.add(Duration(days: days));
    int created = 0;

    for (final slot in _timetable) {
      DateTime cursor = now;
      while (cursor.weekday != slot.weekday) {
        cursor = cursor.add(const Duration(days: 1));
      }
      while (cursor.isBefore(cutoff)) {
        final start = DateTime(
            cursor.year, cursor.month, cursor.day, slot.startHour, slot.startMinute);
        final end = DateTime(
            cursor.year, cursor.month, cursor.day, slot.endHour, slot.endMinute);

        if (start.isBefore(now)) {
          cursor = cursor.add(const Duration(days: 7));
          continue;
        }

        final exists = _sessions.any((s) =>
            s.programId == slot.programId &&
            s.scheduledStart.isAtSameMomentAs(start));

        if (!exists) {
          await _service.createSession(Session(
            id: '',
            radioId: _radioId,
            timetableSlotId: slot.id,
            programId: slot.programId,
            programName: slot.programName,
            hostId: slot.defaultHostId ?? '',
            hostName: slot.defaultHostName ?? '',
            scheduledStart: start,
            scheduledEnd: end,
            createdAt: DateTime.now(),
          ));
          created++;
        }
        cursor = cursor.add(const Duration(days: 7));
      }
    }
    return created;
  }

  // ============ PROGRAMS ============

  Future<String> createProgram(Program p) => _service.createProgram(p);

  Future<void> updateProgram(String id, Map<String, dynamic> updates) =>
      _service.updateProgram(id, updates);

  Future<void> archiveProgram(String id) => _service.archiveProgram(id);

  // ============ MEDIA ============

  Future<String> createMediaItem(MediaItem item) => _service.createMediaItem(item);

  Future<void> deleteMediaItem(String id) => _service.deleteMediaItem(id);

  @override
  void dispose() {
    _detachStreams();
    super.dispose();
  }
}
