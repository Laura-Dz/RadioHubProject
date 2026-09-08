import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/technician/program_model.dart';
import '../core/models/technician/session_model.dart';
import '../core/models/technician/host_model.dart';
import '../core/models/technician/media_model.dart';
import '../core/models/technician/metrics_model.dart';
import '../core/services/technician_service.dart';

class TechnicianViewModel extends ChangeNotifier {
  final TechnicianService _service;

  TechnicianViewModel({required TechnicianService service}) : _service = service {
    _loadData();
  }

  List<Program> _programs = [];
  List<Session> _sessions = [];
  List<Session> _liveSessions = [];
  List<Host> _hosts = [];
  List<Session> _pastSessions = [];
  List<MediaItem> _media = [];

  Map<DateTime, List<Session>> _weeklySchedule = {};
  DateTime _selectedWeek = DateTime.now();
  bool _isLoading = true;
  String? _errorMessage;

  List<Program> get programs => _programs;
  List<Session> get sessions => _sessions;
  List<Session> get liveSessions => _liveSessions;
  List<Host> get hosts => _hosts;
  List<Session> get pastSessions => _pastSessions;
  List<MediaItem> get media => _media;
  Map<DateTime, List<Session>> get weeklySchedule => _weeklySchedule;
  DateTime get selectedWeek => _selectedWeek;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Session> get waitingCalls {
    if (_liveSessions.isEmpty) return const [];
    final live = _liveSessions.first;
    if (live.status != SessionStatus.live) return const [];
    return [live];
  }

  Future<void> routeCallToHost(String sessionId, String hostId) async {
    await FirebaseFirestore.instance
        .collection('sessions')
        .doc(sessionId)
        .collection('calls')
        .doc(hostId)
        .set({
      'status': 'routing',
      'hostId': hostId,
      'routedAt': FieldValue.serverTimestamp(),
    });
  }

  List<Session> get todaySchedule {
    final now = DateTime.now();
    return _sessions.where((s) {
      return s.date.year == now.year &&
          s.date.month == now.month &&
          s.date.day == now.day;
    }).toList();
  }

  Future<void> _loadData() async {
    _isLoading = true;
    notifyListeners();
    try {
      await Future.wait([
        _loadPrograms(),
        _loadHosts(),
        _loadSessions(),
        _loadLiveSessions(),
        _loadPastSessions(),
        _loadMedia(),
      ]);
      _buildWeeklySchedule();
      _isLoading = false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
    }
    notifyListeners();
  }

  Future<void> _loadPrograms() async {
    _programs = await _service.getPrograms();
  }

  Future<void> _loadHosts() async {
    _hosts = await _service.getHosts();
  }

  Future<void> _loadSessions() async {
    _sessions = await _service.getSessions();
  }

  Future<void> _loadLiveSessions() async {
    _liveSessions = await _service.getLiveSessions();
  }

  Future<void> _loadPastSessions() async {
    _pastSessions = await _service.getPastSessions();
  }

  Future<void> _loadMedia() async {
    _media = await _service.getMediaItems();
  }

  void _buildWeeklySchedule() {
    final startOfWeek = _selectedWeek.subtract(Duration(days: _selectedWeek.weekday - 1));
    _weeklySchedule = {};
    for (int i = 0; i < 7; i++) {
      final day = startOfWeek.add(Duration(days: i));
      _weeklySchedule[day] = _sessions.where((s) =>
          s.date.year == day.year &&
          s.date.month == day.month &&
          s.date.day == day.day).toList();
    }
    notifyListeners();
  }

  // ===== PROGRAMS =====
  Future<void> createProgram(Program program) async {
    await _service.createProgram(program);
    await _loadPrograms();
  }

  Future<void> updateProgram(Program program) async {
    await _service.updateProgram(program);
    await _loadPrograms();
  }

  Future<void> deleteProgram(String programId) async {
    await _service.deleteProgram(programId);
    await _loadPrograms();
  }

  // ===== HOSTS =====
  Future<void> createHost(Host host) async {
    await _service.createHost(host);
    await _loadHosts();
  }

  Future<void> updateHost(Host host) async {
    await _service.updateHost(host);
    await _loadHosts();
  }

  Future<void> deleteHost(String hostId) async {
    await _service.deleteHost(hostId);
    await _loadHosts();
  }

  List<Host> getHostsForProgram(String programId) {
    return _hosts.where((h) => h.programIds.contains(programId)).toList();
  }

  // ===== SESSIONS =====
  Future<void> createSession(Session session) async {
    await _service.createSession(session);
    await _loadSessions();
    _buildWeeklySchedule();
  }

  Future<void> updateSession(Session session) async {
    await _service.updateSession(session);
    await _loadSessions();
    _buildWeeklySchedule();
  }

  Future<void> startSession(String sessionId) async {
    await _service.startSession(sessionId);
    await _loadSessions();
    await _loadLiveSessions();
    _buildWeeklySchedule();
  }

  Future<void> endSession(String sessionId) async {
    await _service.endSession(sessionId);
    await _loadSessions();
    await _loadLiveSessions();
    await _loadPastSessions();
    _buildWeeklySchedule();
  }

  Future<void> scheduleRediffusion({
    required String sessionId,
    required DateTime date,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    await _service.scheduleRediffusion(
      sessionId: sessionId,
      date: date,
      startTime: startTime,
      endTime: endTime,
    );
    await _loadSessions();
    _buildWeeklySchedule();
  }

  // ===== MEDIA =====
  Future<void> createMedia(MediaItem item) async {
    await _service.createMediaItem(item);
    await _loadMedia();
  }

  Future<void> deleteMedia(String id) async {
    await _service.deleteMediaItem(id);
    await _loadMedia();
  }

  // ===== SCHEDULE =====
  void goToPreviousWeek() {
    _selectedWeek = _selectedWeek.subtract(const Duration(days: 7));
    _buildWeeklySchedule();
  }

  void goToNextWeek() {
    _selectedWeek = _selectedWeek.add(const Duration(days: 7));
    _buildWeeklySchedule();
  }

  void goToToday() {
    _selectedWeek = DateTime.now();
    _buildWeeklySchedule();
  }

  List<Session> getSessionsForSlot(DateTime date, int hour) {
    return _weeklySchedule[date]?.where((s) => s.startTime.hour == hour).toList() ?? [];
  }

  List<int> getAvailableSlots(DateTime date, {int startHour = 6, int endHour = 22}) {
    final occupied = _weeklySchedule[date]?.map((s) => s.startTime.hour).toSet() ?? {};
    return List.generate(endHour - startHour, (i) => startHour + i)
        .where((h) => !occupied.contains(h))
        .toList();
  }

  Future<LiveMetrics> getLiveMetrics(String sessionId) async {
    return await _service.getLiveMetrics(sessionId);
  }

  Stream<LiveMetrics> streamLiveMetrics(String sessionId) {
    return _service.streamLiveMetrics(sessionId);
  }

  Future<void> refreshData() async {
    await _loadData();
  }
}
