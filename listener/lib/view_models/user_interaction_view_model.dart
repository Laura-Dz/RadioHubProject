import 'dart:async';

import '../core/services/user_interaction_service.dart';
import '../core/models/user_interaction_model.dart';
import '../core/models/show_model.dart';
import 'base_view_model.dart';

class UserInteractionViewModel extends BaseViewModel {
  final UserInteractionService _interactionService;
  final String userId;

  List<String> _starredChannelIds = [];
  List<String> _followedShowIds = [];
  List<ShowReminder> _activeReminders = [];
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;

  bool _disposed = false;
  List<StreamSubscription> _subscriptions = [];

  UserInteractionViewModel({
    required UserInteractionService interactionService,
    required this.userId,
  })  : _interactionService = interactionService {
    _loadInitialData();
  }

  List<String> get starredChannelIds => _starredChannelIds;
  List<String> get followedShowIds => _followedShowIds;
  List<ShowReminder> get activeReminders => _activeReminders;
  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;

  void _loadInitialData() {
    _subscriptions.add(
      _interactionService.streamStarredChannels(userId).listen((stars) {
        _starredChannelIds = stars.map((s) => s.channelId).toList();
        if (!_disposed) notifyListeners();
      }),
    );
    _subscriptions.add(
      _interactionService.streamFollowedShows(userId).listen((follows) {
        _followedShowIds = follows.map((f) => f.showId).toList();
        if (!_disposed) notifyListeners();
      }),
    );
    _subscriptions.add(
      _interactionService.streamActiveReminders(userId).listen((reminders) {
        _activeReminders = reminders;
        if (!_disposed) notifyListeners();
      }),
    );
    _subscriptions.add(
      _interactionService.streamNotifications(userId).listen((notifications) {
        _notifications = notifications;
        _unreadCount = notifications.where((n) => !n.isRead).length;
        if (!_disposed) notifyListeners();
      }),
    );
  }

  Future<void> toggleStarChannel(String channelId) async {
    await execute(() async {
      await _interactionService.toggleStarChannel(userId, channelId);
    });
  }

  bool isChannelStarred(String channelId) {
    return _starredChannelIds.contains(channelId);
  }

  Future<void> toggleFollowShow(String showId) async {
    await execute(() async {
      await _interactionService.toggleFollowShow(userId, showId);
    });
  }

  bool isShowFollowed(String showId) {
    return _followedShowIds.contains(showId);
  }

  Future<void> setReminder({
    required String showId,
    required String programName,
    required DateTime showStartTime,
    int reminderMinutesBefore = 15,
  }) async {
    await execute(() async {
      await _interactionService.setShowReminder(
        userId: userId,
        showId: showId,
        programName: programName,
        showStartTime: showStartTime,
        reminderMinutesBefore: reminderMinutesBefore,
      );
    });
  }

  Future<void> removeReminder(String showId) async {
    await execute(() async {
      await _interactionService.removeShowReminder(userId, showId);
    });
  }

  bool hasReminder(String showId) {
    return _activeReminders.any((r) => r.showId == showId && r.isActive);
  }

  ShowReminder? getReminderForShow(String showId) {
    try {
      return _activeReminders.firstWhere((r) => r.showId == showId && r.isActive);
    } catch (_) {
      return null;
    }
  }

  List<ShowModel> filterFollowedShows(List<ShowModel> allShows) {
    return allShows.where((show) => _followedShowIds.contains(show.id)).toList();
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _interactionService.markNotificationAsRead(notificationId);
  }

  Future<void> markAllNotificationsAsRead() async {
    await _interactionService.markAllNotificationsAsRead(userId);
  }

  @override
  void dispose() {
    _disposed = true;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    super.dispose();
  }
}
