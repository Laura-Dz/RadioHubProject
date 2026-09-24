import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/host_session.dart';
import '../core/models/comment.dart';
import '../core/models/call.dart';
import '../core/models/host_announcement.dart';
import '../core/services/comment_service.dart';
import '../core/services/call_service.dart';
import '../core/services/host_announcement_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostViewModel extends ChangeNotifier {
  final CommentService _comments = CommentService();
  final CallService _calls = CallService();
  final HostAnnouncementService _announcements = HostAnnouncementService();
  final _db = FirebaseFirestore.instance;

  String? _sessionId;
  HostSession? _session;
  List<Comment> _commentList = [];
  List<Call> _callList = [];
  List<HostAnnouncement> _announcementList = [];
  final Set<String> _dismissedNotificationIds = {};
  HostAnnouncement? _activeDueAnnouncement;
  String? _replyingToId;
  String? _error;

  StreamSubscription? _sessionSub;
  StreamSubscription? _commentsSub;
  StreamSubscription? _callsSub;
  StreamSubscription? _announcementsSub;
  Timer? _dueCheckTimer;

  // Getters
  HostSession? get session => _session;
  List<Comment> get comments => _commentList;
  List<Call> get calls => _callList;
  List<HostAnnouncement> get announcements => _announcementList;
  List<HostAnnouncement> get pendingAnnouncements =>
      _announcementList.where((a) => !a.isAired).toList();
  HostAnnouncement? get activeDueAnnouncement => _activeDueAnnouncement;
  int get unreadAnnouncementCount => pendingAnnouncements.length;
  String? get replyingToId => _replyingToId;
  String? get error => _error;

  List<Call> get pendingCalls =>
      _callList.where((c) => c.isPending).toList();
  List<Call> get heldCalls => _callList.where((c) => c.isHeld).toList();
  Call? get onCall {
    final l = _callList.where((c) => c.isAccepted).toList();
    return l.isEmpty ? null : l.first;
  }

  bool get sessionEnded => _session?.isEnded ?? false;

  void attach(String sessionId) {
    _sessionId = sessionId;

    _sessionSub = _db
        .collection('sessions')
        .doc(sessionId)
        .snapshots()
        .listen((doc) {
      if (!doc.exists) return;
      final prevSession = _session;
      _session = HostSession.fromFirestore(doc.data()!, doc.id);

      // Start streaming announcements once radioId & programName are known
      if (prevSession == null || prevSession.radioId != _session!.radioId) {
        _subscribeAnnouncements(_session!.radioId, _session!.programName);
      }
      notifyListeners();
    });

    _commentsSub = _comments.streamComments(sessionId).listen((list) {
      _commentList = list;
      notifyListeners();
    });

    _callsSub = _calls.streamCalls(sessionId).listen((list) {
      _callList = list;
      notifyListeners();
    });

    // Check for due announcements every 15 seconds
    _dueCheckTimer?.cancel();
    _dueCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkDueAnnouncements();
    });
  }

  void _subscribeAnnouncements(String radioId, String programName) {
    _announcementsSub?.cancel();
    _announcementsSub = _announcements
        .streamAnnouncementsForShow(radioId: radioId, programName: programName)
        .listen((list) {
      _announcementList = list;
      _checkDueAnnouncements();
      notifyListeners();
    });
  }

  void _checkDueAnnouncements() {
    final now = DateTime.now();
    final due = _announcementList.where((a) {
      return a.isDueNow(now) && !_dismissedNotificationIds.contains(a.id);
    }).toList();

    if (due.isNotEmpty) {
      if (_activeDueAnnouncement?.id != due.first.id) {
        _activeDueAnnouncement = due.first;
        notifyListeners();
      }
    } else if (_activeDueAnnouncement != null) {
      _activeDueAnnouncement = null;
      notifyListeners();
    }
  }

  void dismissDueAnnouncement(String announcementId) {
    _dismissedNotificationIds.add(announcementId);
    if (_activeDueAnnouncement?.id == announcementId) {
      _activeDueAnnouncement = null;
    }
    notifyListeners();
  }

  Future<void> markAnnouncementAired(HostAnnouncement a) async {
    try {
      await _announcements.markAsAired(
        announcementId: a.id,
        hostName: _session?.hostName ?? 'Host',
        programName: _session?.programName,
      );
      _dismissedNotificationIds.add(a.id);
      if (_activeDueAnnouncement?.id == a.id) {
        _activeDueAnnouncement = null;
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to mark announcement as aired: $e';
      notifyListeners();
    }
  }

  void disposeStreams() {
    _sessionSub?.cancel();
    _commentsSub?.cancel();
    _callsSub?.cancel();
    _announcementsSub?.cancel();
    _dueCheckTimer?.cancel();
  }

  // ---------- Comment reply ----------

  Future<void> startReplying(Comment c) async {
    // Cancel any previous replying state
    if (_replyingToId != null && _replyingToId != c.id) {
      try {
        await _comments.setReplying(_replyingToId!, false);
      } catch (_) {}
    }

    _replyingToId = c.id;
    notifyListeners();

    try {
      await _comments.setReplying(c.id, true);
    } catch (e) {
      _error = e.toString();
      _replyingToId = null;
      notifyListeners();
    }
  }

  Future<void> cancelReplying() async {
    final id = _replyingToId;
    _replyingToId = null;
    notifyListeners();
    if (id == null) return;
    try {
      await _comments.setReplying(id, false);
    } catch (_) {}
  }

  Future<void> markCommentReplied(Comment c) async {
    try {
      await _comments.markReplied(c.id);
      if (_replyingToId == c.id) {
        _replyingToId = null;
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> sendReply(String text) async {
    final id = _replyingToId;
    if (id == null || text.trim().isEmpty) return;

    try {
      await _comments.reply(id, text.trim());
      _replyingToId = null;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ---------- Call actions ----------

  Future<void> acceptCall(Call c) async {
    try {
      await _calls.accept(c.id, sessionId: _sessionId ?? c.sessionId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> holdCall(Call c) async {
    try {
      await _calls.hold(c.id, sessionId: _sessionId ?? c.sessionId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> declineCall(Call c) async {
    try {
      await _calls.decline(c.id, sessionId: _sessionId ?? c.sessionId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> endCall(Call c) async {
    try {
      await _calls.end(c.id, sessionId: _sessionId ?? c.sessionId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  @override
  void dispose() {
    disposeStreams();
    super.dispose();
  }
}
