import 'package:flutter/material.dart';
import '../core/enums/navigation_tabs.dart';
import '../core/constants/app_constants.dart';
import '../core/services/shared_preferences_service.dart';
import '../core/services/firestore_service.dart';
import 'base_view_model.dart';

class MainLayoutViewModel extends BaseViewModel {
  final SharedPreferencesService _prefsService;
  final FirestoreService _firestoreService;

  NavigationTabs _currentTab = NavigationTabs.home;
  String _currentTitle = 'Home';
  String? _currentStationName;
  bool _isDarkMode = false;

  MainLayoutViewModel({
    required SharedPreferencesService prefsService,
    required FirestoreService firestoreService,
  })  : _prefsService = prefsService,
        _firestoreService = firestoreService {
    _loadPreferences();
  }

  NavigationTabs get currentTab => _currentTab;
  String get currentTitle => _currentTitle;
  String? get currentStationName => _currentStationName;
  bool get isDarkMode => _isDarkMode;

  void setTab(NavigationTabs tab) {
    _currentTab = tab;
    _updateTitle(tab);
    _saveSelectedTab(tab);
    notifyListeners();
  }

  void setStationName(String? name) {
    _currentStationName = name;
    _updateTitle(_currentTab);
    notifyListeners();
  }

  void toggleTheme() {
    _isDarkMode = !_isDarkMode;
    _prefsService.setDarkMode(_isDarkMode);
    notifyListeners();
  }

  void _updateTitle(NavigationTabs tab) {
    switch (tab) {
      case NavigationTabs.home:
        _currentTitle = _currentStationName ?? 'Radio Stream';
        break;
      case NavigationTabs.channels:
        _currentTitle = 'Channels';
        break;
      case NavigationTabs.announcements:
        _currentTitle = 'Announcements';
        break;
      case NavigationTabs.profile:
        _currentTitle = 'Profile';
        break;
      case NavigationTabs.settings:
        _currentTitle = 'Settings';
        break;
    }
  }

  void navigateToAnnouncements() => setTab(NavigationTabs.announcements);


  Future<void> _loadPreferences() async {
    final savedTab = _prefsService.getSelectedTab();
    if (savedTab != null) {
      _currentTab = savedTab;
      _updateTitle(savedTab);
    }
    _isDarkMode = _prefsService.getDarkMode();
    _currentStationName = _prefsService.getCurrentStation();
    notifyListeners();
  }

  Future<void> _saveSelectedTab(NavigationTabs tab) async {
    await _prefsService.setSelectedTab(tab);
  }

  void navigateToHome() => setTab(NavigationTabs.home);
  void navigateToChannels() => setTab(NavigationTabs.channels);
  void navigateToProfile() => setTab(NavigationTabs.profile);
  void navigateToSettings() => setTab(NavigationTabs.settings);

  Future<void> loadUserData() async {
    await execute(() async {
      final user = await _firestoreService.getCurrentUser();
      if (user != null) {
        _currentStationName = user.displayName ?? 'Radio Stream';
        _updateTitle(_currentTab);
        notifyListeners();
      }
    });
  }
}
