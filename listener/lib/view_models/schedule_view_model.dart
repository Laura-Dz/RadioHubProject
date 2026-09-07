import 'package:flutter/foundation.dart';
import '../../core/models/schedule_model.dart';
import '../../core/models/flash_model.dart';
import '../../core/services/schedule_service.dart';

class ScheduleViewModel extends ChangeNotifier {
  final ScheduleService _scheduleService;

  List<ScheduleItem> _todaySchedule = [];
  List<ScheduleItem> _upcomingShows = [];
  List<FlashProgram> _activeFlashes = [];
  ScheduleItem? _nowPlaying;

  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();

  ScheduleViewModel(this._scheduleService);

  List<ScheduleItem> get todaySchedule => _todaySchedule;
  List<ScheduleItem> get upcomingShows => _upcomingShows;
  List<FlashProgram> get activeFlashes => _activeFlashes;
  ScheduleItem? get nowPlaying => _nowPlaying;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;

  Future<void> loadSchedule() async {
    _setLoading(true);
    _error = null;

    try {
      final nowPlaying = await _scheduleService.getNowPlaying();
      final todaySchedule = await _scheduleService.getScheduleForDate(_selectedDate);
      final upcomingShows = await _scheduleService.getUpcomingShows(limit: 10);
      final activeFlashes = await _scheduleService.getActiveFlashes();

      _nowPlaying = nowPlaying;
      _todaySchedule = todaySchedule;
      _upcomingShows = upcomingShows;
      _activeFlashes = activeFlashes;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> setSelectedDate(DateTime date) async {
    if (DateTime(date.year, date.month, date.day) ==
        DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day)) {
      return;
    }

    _selectedDate = date;
    notifyListeners();
    await loadSchedule();
  }

  Future<void> refresh() async {
    await loadSchedule();
  }

  Stream<List<ScheduleItem>> getScheduleStream() {
    return _scheduleService.streamTodaySchedule();
  }

  Future<Map<DateTime, List<ScheduleItem>>> getScheduleForWeek(DateTime startDate) async {
    return await _scheduleService.getScheduleForWeek(startDate);
  }

  Future<List<ScheduleItem>> getSpecialEvents() async {
    return await _scheduleService.getSpecialEvents(limit: 20);
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
