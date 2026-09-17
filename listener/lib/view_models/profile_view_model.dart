import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../core/models/user_profile.dart';
import '../core/models/user_preferences.dart';
import '../core/services/user_service.dart';

class ProfileViewModel extends ChangeNotifier {
  final UserService _service = UserService();

  UserProfile? _profile;
  UserPreferences _preferences = UserPreferences();
  bool _loading = true;
  String? _error;

  StreamSubscription? _profileSub;
  StreamSubscription? _prefsSub;

  UserProfile? get profile => _profile;
  UserPreferences get preferences => _preferences;
  bool get loading => _loading;
  String? get error => _error;

  void attach() {
    final uid = _service.uid;
    if (uid == null) return;

    _profileSub = _service.streamProfile(uid).listen((p) {
      _profile = p;
      _loading = false;
      notifyListeners();
    }, onError: (e) {
      _error = e.toString();
      _loading = false;
      notifyListeners();
    });

    _prefsSub = _service.streamPreferences(uid).listen((prefs) {
      _preferences = prefs;
      notifyListeners();
    }, onError: (e) {
      debugPrint('streamPreferences error: $e');
    });
  }

  // ---------- PROFILE ----------

  Future<void> updateProfile({
    String? displayName,
    String? phone,
    String? bio,
    String? city,
    String? ageGroup,
    String? gender,
    String? language,
  }) async {
    final uid = _service.uid;
    if (uid == null) return;

    final updates = <String, dynamic>{};
    if (displayName != null) updates['displayName'] = displayName.trim();
    if (phone != null) updates['phone'] = phone.trim();
    if (bio != null) updates['bio'] = bio.trim();
    if (city != null) updates['city'] = city.trim();
    if (ageGroup != null) updates['ageGroup'] = ageGroup;
    if (gender != null) updates['gender'] = gender;
    if (language != null) updates['language'] = language;

    if (updates.isEmpty) return;

    try {
      await _service.updateProfile(uid, updates);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> uploadAvatar({
    required Uint8List bytes,
    required String extension,
    void Function(double)? onProgress,
  }) async {
    final uid = _service.uid;
    if (uid == null) return;
    try {
      final url = await _service.uploadAvatar(
        uid: uid,
        bytes: bytes,
        extension: extension,
        onProgress: onProgress,
      );
      await _service.updateProfile(uid, {'photoUrl': url});
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ---------- PREFERENCES ----------

  Future<void> updatePreferences(UserPreferences next) async {
    final uid = _service.uid;
    if (uid == null) return;
    _preferences = next;
    notifyListeners();
    try {
      await _service.updatePreferences(uid, next);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> toggle(String key) async {
    switch (key) {
      case 'pushNotifications':
        await updatePreferences(
            _preferences.copyWith(pushNotifications: !_preferences.pushNotifications));
        break;
      case 'followedShowAlerts':
        await updatePreferences(
            _preferences.copyWith(followedShowAlerts: !_preferences.followedShowAlerts));
        break;
      case 'hostReplyAlerts':
        await updatePreferences(
            _preferences.copyWith(hostReplyAlerts: !_preferences.hostReplyAlerts));
        break;
      case 'callStatusAlerts':
        await updatePreferences(
            _preferences.copyWith(callStatusAlerts: !_preferences.callStatusAlerts));
        break;
      case 'announcementUpdates':
        await updatePreferences(
            _preferences.copyWith(announcementUpdates: !_preferences.announcementUpdates));
        break;
      case 'dataSaver':
        await updatePreferences(
            _preferences.copyWith(dataSaver: !_preferences.dataSaver));
        break;
      case 'autoplayOnOpen':
        await updatePreferences(
            _preferences.copyWith(autoplayOnOpen: !_preferences.autoplayOnOpen));
        break;
      case 'reduceMotion':
        await updatePreferences(
            _preferences.copyWith(reduceMotion: !_preferences.reduceMotion));
        break;
    }
  }

  Future<void> setAudioQuality(String q) =>
      updatePreferences(_preferences.copyWith(audioQuality: q));

  Future<void> setTheme(String t) =>
      updatePreferences(_preferences.copyWith(theme: t));

  // ---------- ACCOUNT ----------

  Future<void> changePassword(String current, String next) async {
    try {
      await _service.changePassword(current, next);
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      notifyListeners();
      rethrow;
    }
  }

  Future<void> deleteAccount() async {
    await _service.deleteAccount();
  }

  Future<void> signOut() async {
    _profileSub?.cancel();
    _prefsSub?.cancel();
    await _service.signOut();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _profileSub?.cancel();
    _prefsSub?.cancel();
    super.dispose();
  }
}
