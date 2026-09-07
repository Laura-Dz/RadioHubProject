import 'package:flutter/foundation.dart';
import '../../core/models/show_model.dart';
import '../../core/services/timetable_service.dart';

class TimetableViewModel extends ChangeNotifier {
  final TimetableService _timetableService;

  List<ShowModel> _weekdayShows = [];
  List<ShowModel> _weekendShows = [];
  List<ShowModel> _filteredShows = [];
  List<String> _hosts = [];
  List<String> _categories = ['all'];

  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  String? _selectedDayType;
  String? _selectedCategory;
  String? _selectedHost;

  TimetableViewModel(this._timetableService);

  List<ShowModel> get weekdayShows => _weekdayShows;
  List<ShowModel> get weekendShows => _weekendShows;
  List<ShowModel> get filteredShows => _filteredShows;
  List<String> get hosts => _hosts;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get selectedDayType => _selectedDayType;
  String? get selectedCategory => _selectedCategory;
  String? get selectedHost => _selectedHost;

  Future<void> loadInitialData() async {
    _setLoading(true);
    _error = null;

    try {
      final weekdayShows = await _timetableService.getWeekdayShows();
      final weekendShows = await _timetableService.getWeekendShows();
      final hosts = await _timetableService.getHosts();
      final musicShows = await _timetableService.getShowsByCategory('music');

      _weekdayShows = weekdayShows;
      _weekendShows = weekendShows;
      _hosts = hosts;
      _categories = ['all', ...musicShows.map((s) => s.category.label).toSet().toList()];
      _filteredShows = [..._weekdayShows, ..._weekendShows];
      _hasMore = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRecurringShows() async {
    if (_isLoading || !_hasMore) return;

    _setLoading(true);
    _error = null;

    try {
      final newShows = await _timetableService.getRecurringShows(
        dayType: _selectedDayType,
        category: _selectedCategory,
        host: _selectedHost,
      );

      _filteredShows = newShows;
      _hasMore = false;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    _hasMore = true;
    _filteredShows = [];
    await loadInitialData();
  }

  Future<void> setDayType(String? dayType) async {
    if (_selectedDayType == dayType) return;
    _selectedDayType = dayType;
    notifyListeners();
    await loadRecurringShows();
  }

  Future<void> setCategory(String? category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    notifyListeners();
    await loadRecurringShows();
  }

  Future<void> setHost(String? host) async {
    if (_selectedHost == host) return;
    _selectedHost = host;
    notifyListeners();
    await loadRecurringShows();
  }

  Future<void> clearFilters() async {
    _selectedDayType = null;
    _selectedCategory = null;
    _selectedHost = null;
    _filteredShows = [..._weekdayShows, ..._weekendShows];
    notifyListeners();
  }

  Future<void> toggleFollow(String showId, bool follow) async {
    await _timetableService.followRecurringShow(showId, follow);

    _filteredShows = _filteredShows.map((s) {
      if (s.id == showId) {
        return ShowModel(
          id: s.id,
          title: s.title,
          description: s.description,
          host: s.host,
          category: s.category,
          imageUrl: s.imageUrl,
          startTime: s.startTime,
          endTime: s.endTime,
          listenerCount: s.listenerCount,
          rating: s.rating,
          status: s.status,
          isFollowed: follow,
          tags: s.tags,
        );
      }
      return s;
    }).toList();

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
