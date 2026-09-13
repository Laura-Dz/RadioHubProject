import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/models/technician/session_model.dart';
import '../core/models/technician/timetable_slot_model.dart';
import '../core/models/technician/program_model.dart';
import '../core/models/technician/program_category_model.dart';
import '../core/models/technician/host_model.dart';
import '../core/models/technician/media_item_model.dart';
import '../core/models/technician/notification_model.dart';
import '../core/models/technician/metrics_model.dart';
import '../core/services/technician_service.dart';
import '../core/services/storage_service.dart';
import '../core/services/media_upload_service.dart';

class TechnicianViewModel extends ChangeNotifier {
  final TechnicianService _service;
  final StorageService _storageService;
  final MediaUploadService _uploader = MediaUploadService();
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String _radioId = '';
  String _radioName = '';
  String _technicianName = '';
  bool _isInitialized = false;

  List<ProgramCategory> _categories = [];
  List<Session> _sessions = [];
  List<Session> _liveSessions = [];
  List<Session> _rediffusionCandidates = [];
  List<Session> _upcomingSessions = [];
  List<Session> _recentEnded = [];
  Session? _liveNow;
  bool _loadingUpcoming = true;
  List<TimetableSlot> _timetable = [];
  List<Program> _programs = [];
  List<Host> _hosts = [];
  List<MediaItem> _mediaItems = [];
  List<NotificationItem> _notifications = [];

  RadioMetrics _metrics = RadioMetrics();
  RadioMetrics get metrics => _metrics;

  bool _loadingMetrics = false;
  bool get loadingMetrics => _loadingMetrics;

  String _metricsPeriod = '7d';
  String get metricsPeriod => _metricsPeriod;

  StreamSubscription? _liveMetricsSub;
  LiveMetrics? _liveMetrics;
  LiveMetrics? get liveMetrics => _liveMetrics;

  StreamSubscription? _categoriesSub;
  StreamSubscription? _sessionsSub;
  StreamSubscription? _liveSub;
  StreamSubscription? _upcomingSub;
  StreamSubscription? _liveNowSub;
  StreamSubscription? _endedSub;
  StreamSubscription? _rediffSub;
  StreamSubscription? _timetableSub;
  StreamSubscription? _programsSub;
  StreamSubscription? _hostsSub;
  StreamSubscription? _mediaSub;
  StreamSubscription? _notifSub;

  TechnicianViewModel({
    required TechnicianService service,
    StorageService? storageService,
  })  : _service = service,
        _storageService = storageService ?? StorageService();

  // Getters
  String get radioId => _radioId;
  String get radioName => _radioName;
  String get technicianName => _technicianName;
  bool get isInitialized => _isInitialized;
  List<ProgramCategory> get categories => _categories;
  List<Session> get sessions => _sessions;
  List<Session> get liveSessions => _liveSessions;
  List<Session> get rediffusionCandidates => _rediffusionCandidates;

  List<Session> get upcomingSessions => _upcomingSessions;
  List<Session> get recentEndedSessions => _recentEnded;
  Session? get currentLiveSession => _liveNow;
  bool get loadingUpcoming => _loadingUpcoming;
  List<TimetableSlot> get timetable => _timetable;
  List<Program> get programs => _programs;
  List<Host> get hosts => _hosts;
  List<MediaItem> get mediaItems => _mediaItems;
  List<NotificationItem> get notifications => _notifications;
  int get unreadNotifications =>
      _notifications.where((n) => !n.isRead).length;

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
    _service.ensureDefaultCategories(_radioId).catchError((e) {
      debugPrint('Error in ensureDefaultCategories: $e');
    });
  }

  void _attachStreams() {
    _detachStreams();

    _categoriesSub = _service.streamCategories(_radioId).listen(
      (list) {
        _categories = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamCategories: $e'),
    );
    _sessionsSub = _service.streamSessions(_radioId).listen(
      (list) {
        _sessions = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamSessions: $e'),
    );
    _liveSub = _service.streamLiveSessions(_radioId).listen(
      (list) {
        _liveSessions = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamLiveSessions: $e'),
    );
    _upcomingSub = _service.streamUpcomingSessions(_radioId).listen(
      (list) {
        _upcomingSessions = list;
        _loadingUpcoming = false;
        notifyListeners();
      },
      onError: (e) {
        _loadingUpcoming = false;
        debugPrint('Error in streamUpcomingSessions: $e');
        notifyListeners();
      },
    );
    _liveNowSub = _service.streamCurrentLiveSession(_radioId).listen(
      (s) {
        _liveNow = s;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamCurrentLiveSession: $e'),
    );
    _endedSub = _service.streamRecentEndedSessions(_radioId).listen(
      (list) {
        _recentEnded = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamRecentEndedSessions: $e'),
    );
    _rediffSub = _service.streamPastSessionsForRediffusion(_radioId).listen(
      (list) {
        _rediffusionCandidates = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamPastSessionsForRediffusion: $e'),
    );
    _timetableSub = _service.streamTimetable(_radioId).listen(
      (list) {
        _timetable = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamTimetable: $e'),
    );
    _programsSub = _service.streamPrograms(_radioId).listen(
      (list) {
        _programs = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamPrograms: $e'),
    );
    _hostsSub = _service.streamHosts(_radioId).listen(
      (list) {
        _hosts = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamHosts: $e'),
    );
    _mediaSub = _service.streamMedia(_radioId).listen(
      (list) {
        _mediaItems = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('streamMedia error: $e'),
    );
    _notifSub = _service.streamNotifications(_radioId).listen(
      (list) {
        _notifications = list;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamNotifications: $e'),
    );
  }

  void _detachStreams() {
    _categoriesSub?.cancel();
    _sessionsSub?.cancel();
    _liveSub?.cancel();
    _upcomingSub?.cancel();
    _liveNowSub?.cancel();
    _endedSub?.cancel();
    _rediffSub?.cancel();
    _timetableSub?.cancel();
    _programsSub?.cancel();
    _hostsSub?.cancel();
    _mediaSub?.cancel();
    _notifSub?.cancel();
    _liveMetricsSub?.cancel();
    _liveMetrics = null;
  }

  Future<void> refreshData() async {
    _detachStreams();
    _attachStreams();
    notifyListeners();
  }

  // ============ METRICS ============

  Future<void> loadMetrics({String? period}) async {
    if (period != null) _metricsPeriod = period;
    _loadingMetrics = true;
    notifyListeners();
    try {
      _metrics = await _service.computeMetrics(_radioId, _metricsPeriod);
    } finally {
      _loadingMetrics = false;
      notifyListeners();
    }
  }

  void watchLiveMetrics(String sessionId) {
    _liveMetricsSub?.cancel();
    _liveMetrics = null;
    _liveMetricsSub = _service.streamLiveMetrics(sessionId).listen(
      (m) {
        _liveMetrics = m;
        notifyListeners();
      },
      onError: (e) => debugPrint('Error in streamLiveMetrics: $e'),
    );
  }

  void stopWatchingLiveMetrics() {
    _liveMetricsSub?.cancel();
    _liveMetricsSub = null;
    _liveMetrics = null;
    notifyListeners();
  }

  Stream<LiveMetrics> streamLiveMetrics(String sessionId) =>
      _service.streamLiveMetrics(sessionId);

  // ============ CATEGORIES ============

  Future<String> createCategory(String name) =>
      _service.createCategory(_radioId, name);

  // ============ SESSIONS ============

  Future<String> createSession(Session session) async {
    final id = await _service.createSession(session);
    return id;
  }

  Future<String?> getLiveSessionId() => _service.getLiveSessionId(_radioId);

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

  Future<void> uploadMedia({
    required Uint8List bytes,
    required String fileName,
    required String contentType,
    required String name,
    required MediaType type,
    required int durationSeconds,
    String? programId,
    List<String> tags = const [],
    String? description,
    void Function(double)? onProgress,
  }) async {
    final result = await _uploader.upload(
      radioId: _radioId,
      bytes: bytes,
      fileName: fileName,
      contentType: contentType,
      onProgress: onProgress,
    );

    final newItem = MediaItem(
      id: '',
      radioId: _radioId,
      name: name,
      url: result.downloadUrl,
      storagePath: result.storagePath,
      type: type,
      durationSeconds: durationSeconds,
      fileSizeKb: result.fileSizeKb,
      programId: programId,
      tags: tags,
      description: description,
      uploadedBy: _auth.currentUser?.uid ?? '',
      uploadedAt: DateTime.now(),
      moderationStatus: 'pending',
    );

    final id = await _service.createMedia(newItem);
    _mediaItems.removeWhere((m) => m.id == id);
    _mediaItems.insert(
      0,
      MediaItem(
        id: id,
        radioId: _radioId,
        name: name,
        url: result.downloadUrl,
        storagePath: result.storagePath,
        type: type,
        durationSeconds: durationSeconds,
        fileSizeKb: result.fileSizeKb,
        programId: programId,
        tags: tags,
        description: description,
        uploadedBy: _auth.currentUser?.uid ?? '',
        uploadedAt: DateTime.now(),
        moderationStatus: 'pending',
      ),
    );
    notifyListeners();
  }

  Future<void> deleteMedia(MediaItem item) async {
    _mediaItems.removeWhere((m) => m.id == item.id);
    notifyListeners();
    await _uploader.deleteByStoragePath(item.storagePath);
    await _service.deleteMedia(item.id);
  }

  // ============ STORAGE ============

  Future<String> uploadProgramImage({
    required String programId,
    required Uint8List bytes,
    required String extension,
    void Function(double)? onProgress,
  }) =>
      _storageService.uploadProgramImage(
        radioId: _radioId,
        programId: programId,
        bytes: bytes,
        extension: extension,
        onProgress: onProgress,
      );

  // ============ TIMETABLE HELPERS ============

  Future<int> generateTimetableFromProgram(Program p) =>
      _service.generateTimetableFromProgram(program: p, existing: _timetable);

  bool timetableOverlaps(TimetableSlot candidate, {String? excludeSlotId}) =>
      _service.timetableOverlaps(_timetable, candidate, excludeSlotId: excludeSlotId);

  Future<String> createIntermediary({
    required TimetableSlot slot,
    required DateTime date,
  }) =>
      _service.createIntermediary(slot: slot, date: date);

  // ============ SPECIAL EVENTS ============

  Future<String> createSpecialEvent({
    required String title,
    required SessionType type,
    required DateTime start,
    required DateTime end,
    String? description,
    String? hostId,
    String? hostName,
  }) =>
      _service.createSpecialEvent(
        radioId: _radioId,
        title: title,
        type: type,
        start: start,
        end: end,
        description: description,
        hostId: hostId,
        hostName: hostName,
      );

  // ============ NOTIFICATIONS ============

  Future<void> markNotificationRead(String id) => _service.markNotificationRead(id);
  Future<void> markAllNotificationsRead() => _service.markAllNotificationsRead(_radioId);

  @override
  void dispose() {
    _detachStreams();
    super.dispose();
  }
}
