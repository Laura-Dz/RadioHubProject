import 'dart:async';
import '../core/enums/view_state.dart';
import '../core/models/radio_model.dart';
import '../core/models/schedule_model.dart';
import '../core/models/announcement_request_model.dart';
import '../core/services/radio_service.dart';
import '../core/services/schedule_service.dart';
import '../core/services/firestore_service.dart';
import 'base_view_model.dart';

class RadioStationViewModel extends BaseViewModel {
  final RadioService _radioService;
  final ScheduleService _scheduleService;
  final FirestoreService _firestoreService;

  RadioModel? _radio;
  ScheduleItem? _currentProgram;
  List<ScheduleItem> _upcomingPrograms = [];
  AnnouncementPricing? _pricing;
  bool _isFollowing = false;

  bool _isLoading = true;
  bool _isPlaying = false;
  bool _showComments = false;
  bool _showUpcomingModal = false;

  StreamSubscription<dynamic>? _radioStreamSubscription;
  StreamSubscription<dynamic>? _scheduleStreamSubscription;

  RadioStationViewModel({
    required RadioService radioService,
    required ScheduleService scheduleService,
    required FirestoreService firestoreService,
  })  : _radioService = radioService,
        _scheduleService = scheduleService,
        _firestoreService = firestoreService;

  RadioModel? get radio => _radio;
  ScheduleItem? get currentProgram => _currentProgram;
  List<ScheduleItem> get upcomingPrograms => _upcomingPrograms;
  AnnouncementPricing? get pricing => _pricing;
  bool get isFollowing => _isFollowing;
  bool get isLoading => _isLoading;
  bool get isPlaying => _isPlaying;
  bool get showComments => _showComments;
  bool get showUpcomingModal => _showUpcomingModal;

  Future<void> loadRadioData(String radioId) async {
    setState(ViewState.loading);
    _isLoading = true;
    notifyListeners();

    try {
      _radio = await _radioService.getRadioById(radioId);
      if (_radio == null) {
        setError('Radio not found');
        return;
      }
      _isFollowing = _radio!.isFollowed;

      _currentProgram = await _scheduleService.getCurrentProgram(radioId);
      _upcomingPrograms = await _scheduleService.getUpcomingPrograms(radioId);
      _pricing = await _radioService.getPricing(radioId);

      _listenToRealtimeUpdates(radioId);

      _isLoading = false;
      setState(ViewState.idle);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      setError('Failed to load radio data');
      notifyListeners();
    }
  }

  void _listenToRealtimeUpdates(String radioId) {
    _radioStreamSubscription?.cancel();
    _radioStreamSubscription = _radioService.streamRadio(radioId).listen((radio) {
      if (radio != null) {
        _radio = radio;
        _isFollowing = radio.isFollowed;
        notifyListeners();
      }
    });

    _scheduleStreamSubscription?.cancel();
    _scheduleStreamSubscription = _scheduleService.streamScheduleForRadio(radioId).listen((programs) {
      final now = DateTime.now();
      _currentProgram = null;
      for (final p in programs) {
        if (p.startTime.isBefore(now) && p.endTime.isAfter(now)) {
          _currentProgram = p;
          break;
        }
      }
      if (_currentProgram == null && programs.isNotEmpty) {
        _currentProgram = programs.firstWhere(
          (p) => p.startTime.isAfter(now),
          orElse: () => programs.last,
        );
      }
      _upcomingPrograms = programs.where((p) => p.startTime.isAfter(now)).toList();
      notifyListeners();
    });
  }

  void togglePlay() {
    _isPlaying = !_isPlaying;
    notifyListeners();
  }

  void toggleComments() {
    _showComments = !_showComments;
    notifyListeners();
  }

  void toggleUpcomingModal() {
    _showUpcomingModal = !_showUpcomingModal;
    notifyListeners();
  }

  Future<void> toggleFollow() async {
    if (_radio == null) return;
    final newFollow = !_isFollowing;
    await _radioService.toggleFollowRadio(_radio!.id, newFollow);
    _isFollowing = newFollow;
    _radio = _radio!.copyWith(
      isFollowed: newFollow,
      followerCount: _radio!.followerCount + (newFollow ? 1 : -1),
    );
    notifyListeners();
  }

  Future<void> requestAnnouncement({
    required String message,
    required AnnouncementCategory category,
    required int durationSeconds,
    required double price,
  }) async {
    if (_radio == null) return;
    try {
      final userId = _firestoreService.getCurrentUserId() ?? '';
      final userName = _firestoreService.getCurrentUserName() ?? 'Anonymous';
      final request = AnnouncementRequest(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        radioId: _radio!.id,
        userId: userId,
        userName: userName,
        message: message,
        category: category,
        durationSeconds: durationSeconds,
        price: price,
        status: AnnouncementStatus.pending,
        createdAt: DateTime.now(),
      );
      await _radioService.submitAnnouncementRequest(request);
      setState(ViewState.success);
      notifyListeners();
    } catch (e) {
      setError('Failed to submit announcement');
      notifyListeners();
    }
  }

  Future<void> refreshData() async {
    if (_radio != null) {
      await loadRadioData(_radio!.id);
    }
  }

  @override
  void dispose() {
    _radioStreamSubscription?.cancel();
    _scheduleStreamSubscription?.cancel();
    super.dispose();
  }
}
