import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/host_session.dart';
import '../core/models/comment.dart';
import '../core/models/call.dart';
import '../core/services/comment_service.dart';
import '../core/services/call_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class HostViewModel extends ChangeNotifier {
  final CommentService _comments = CommentService();
  final CallService _calls = CallService();
  final _db = FirebaseFirestore.instance;

  String? _sessionId;
  HostSession? _session;
  List<Comment> _commentList = [];
  List<Call> _callList = [];
  String? _replyingToId;
  String? _error;

  StreamSubscription? _sessionSub;
  StreamSubscription? _commentsSub;
  StreamSubscription? _callsSub;

  // Getters
  HostSession? get session => _session;
  List<Comment> get comments => _commentList;
  List<Call> get calls => _callList;
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
      _session = HostSession.fromFirestore(doc.data()!, doc.id);
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
  }

  void disposeStreams() {
    _sessionSub?.cancel();
    _commentsSub?.cancel();
    _callsSub?.cancel();
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
