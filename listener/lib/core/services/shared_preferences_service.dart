import 'package:shared_preferences/shared_preferences.dart';
import '../enums/navigation_tabs.dart';

class SharedPreferencesService {
  static const String KEY_APP_LANGUAGE = 'app_language';
  static const String KEY_APP_REGION = 'app_region';
  static const String KEY_IS_FIRST_LAUNCH = 'is_first_launch';
  static const String KEY_AUTH_TOKEN = 'auth_token';
  static const String KEY_USER_ID = 'user_id';
  static const String KEY_REFRESH_TOKEN = 'refresh_token';
  static const String KEY_SELECTED_TAB = 'selected_tab';
  static const String KEY_CURRENT_STATION = 'current_station';
  static const String KEY_DARK_MODE = 'dark_mode';

  final SharedPreferences _prefs;

  SharedPreferencesService(this._prefs);

  Future<void> setLanguage(String code) async =>
      await _prefs.setString(KEY_APP_LANGUAGE, code);

  String? getLanguage() => _prefs.getString(KEY_APP_LANGUAGE);

  Future<void> setRegion(String region) async =>
      await _prefs.setString(KEY_APP_REGION, region);

  String? getRegion() => _prefs.getString(KEY_APP_REGION);

  Future<void> setFirstLaunchComplete() async =>
      await _prefs.setBool(KEY_IS_FIRST_LAUNCH, false);

  bool isFirstLaunch() => _prefs.getBool(KEY_IS_FIRST_LAUNCH) ?? true;

  Future<void> setAuthToken(String token) async =>
      await _prefs.setString(KEY_AUTH_TOKEN, token);

  String? getAuthToken() => _prefs.getString(KEY_AUTH_TOKEN);

  Future<void> setUserId(String userId) async =>
      await _prefs.setString(KEY_USER_ID, userId);

  String? getUserId() => _prefs.getString(KEY_USER_ID);

  Future<void> setSelectedTab(NavigationTabs tab) async =>
      await _prefs.setString(KEY_SELECTED_TAB, tab.toString());

  NavigationTabs? getSelectedTab() {
    final tabString = _prefs.getString(KEY_SELECTED_TAB);
    if (tabString == null) return null;
    return NavigationTabs.values.firstWhere(
      (e) => e.toString() == tabString,
      orElse: () => NavigationTabs.home,
    );
  }

  Future<void> setCurrentStation(String? stationName) async {
    if (stationName != null) {
      await _prefs.setString(KEY_CURRENT_STATION, stationName);
    } else {
      await _prefs.remove(KEY_CURRENT_STATION);
    }
  }

  String? getCurrentStation() => _prefs.getString(KEY_CURRENT_STATION);

  Future<void> setDarkMode(bool isDark) async =>
      await _prefs.setBool(KEY_DARK_MODE, isDark);

  bool getDarkMode() => _prefs.getBool(KEY_DARK_MODE) ?? false;

  Future<void> clearAll() async => await _prefs.clear();
}
