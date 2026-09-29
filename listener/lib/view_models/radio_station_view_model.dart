import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_database/firebase_database.dart';
import '../core/models/radio_model.dart';
import '../core/models/session_model.dart';
import '../core/models/user_mark.dart';
import '../core/models/poll.dart';
import '../core/services/user_marks_service.dart';
import '../core/services/realtime_database_service.dart';
import '../core/services/cloud_function_caller.dart';
import '../core/services/voip_audio_service.dart';
import 'package:just_audio/just_audio.dart';
import '../core/config/app_config.dart';
import '../core/services/listener_activity_service.dart';

class RadioStationViewModel extends ChangeNotifier {
  final _db = FirebaseFirestore.instance;
  final _marks = UserMarksService();
  final _auth = FirebaseAuth.instance;
  final _activityService = ListenerActivityService();
  DateTime? _playStartedAt;

  String _radioId = '';
  RadioModel? _radio;
  SessionModel? _liveSession;
  SessionModel? _nextSession;
  List<SessionModel> _upcomingSessions = [];
  Set<String> _favouritePrograms = {};
  Set<String> _reminders = {};
  Set<String> _listenLater = {};

  bool _loading = true;
  bool _isPlaying = false;
  bool _isPlayerDismissed = false;
  bool get isPlayerDismissed => _isPlayerDismissed;
  bool _hasRegisteredPresence = false;
  DatabaseReference? _myPresenceRef;
  String? _error;

  Poll? _activePoll;
  bool _hasVoted = false;
  int? _myVoteIndex;
  bool _showPollModal = false;

  StreamSubscription? _radioSub;
  StreamSubscription? _directLiveSub;
  StreamSubscription? _sessionsSub;
  StreamSubscription? _programsSub;
  StreamSubscription? _favSub;
  StreamSubscription? _remSub;
  StreamSubscription? _listSub;
  StreamSubscription? _pollSub;
  StreamSubscription? _rtdbPollSub;
  StreamSubscription? _myVoteSub;
  StreamSubscription? _rtdbVoteSub;
  StreamSubscription? _callSub;
  StreamSubscription? _rtdbCallSub;
  Timer? _timeTicker;
  final Map<String, String> _programImages = {};
  List<SessionModel> _allRawSessions = [];
  String? _myCallStatus;
  bool _isVoipMuted = false;

  String? get uid => _auth.currentUser?.uid;
  RadioModel? get radio => _radio;
  SessionModel? get liveSession => _liveSession;
  SessionModel? get nextSession => _nextSession;
  List<SessionModel> get upcomingSessions => _upcomingSessions;
  bool get loading => _loading;
  bool get isPlaying => _isPlaying;
  String? get error => _error;

  Poll? get activePoll => _activePoll;
  bool get hasVoted => _hasVoted;
  int? get myVoteIndex => _myVoteIndex;
  bool get showPollModal => _showPollModal;
  bool get hasActivePoll => _activePoll != null && _activePoll!.isActive && !_activePoll!.isExpired;

  String? get myCallStatus => _myCallStatus;
  bool get hasActiveCall => _myCallStatus == 'pending' || _myCallStatus == 'accepted' || _myCallStatus == 'held';
  bool get isCallAccepted => _myCallStatus == 'accepted';
  bool get isCallHeld => _myCallStatus == 'held';
  bool get isVoipMuted => _isVoipMuted;
  void toggleVoipMute() {
    _isVoipMuted = !_isVoipMuted;
    notifyListeners();
  }

  bool get isOnAir => _liveSession != null;
  bool get canComment =>
      isOnAir && (_liveSession!.allowComments) && !_liveSession!.isRediffusion;
  bool get canCall =>
      isOnAir && _liveSession!.allowCalls && !_liveSession!.isRediffusion;
  bool get isFavouriteOnAir =>
      _liveSession != null && _favouritePrograms.contains(_liveSession!.programId);

  void _setLiveSession(SessionModel? live) {
    final previousLiveId = _liveSession?.id;
    _liveSession = live;

    if (_liveSession != null) {
      if (previousLiveId != _liveSession!.id) {
        _watchPoll(_liveSession!.id);
        _watchMyCall(_liveSession!.id);
      }
    } else {
      _pollSub?.cancel();
      _rtdbPollSub?.cancel();
      _myVoteSub?.cancel();
      _rtdbVoteSub?.cancel();
      _callSub?.cancel();
      _activePoll = null;
      _hasVoted = false;
      _myVoteIndex = null;
      _myCallStatus = null;
    }
    notifyListeners();
  }

  void attach(String radioId) {
    if (_radioId != radioId) {
      _isPlayerDismissed = false;
    }
    _radioId = radioId;
    _detach();
    _loading = true;

    _radioSub = _db.collection('radios').doc(radioId).snapshots().listen((d) {
      if (d.exists) {
        _radio = RadioModel.fromFirestore(d.data()!, d.id);
        final liveId = _radio?.currentLiveSessionId;
        if (liveId != null && liveId.isNotEmpty && (_liveSession == null || _liveSession!.id != liveId)) {
          _directLiveSub?.cancel();
          _directLiveSub = _db.collection('sessions').doc(liveId).snapshots().listen((sDoc) {
            if (sDoc.exists && sDoc.data() != null) {
              final directLive = SessionModel.fromFirestore(sDoc.data()!, sDoc.id);
              if (directLive.status != SessionStatus.ended && directLive.status != SessionStatus.cancelled) {
                _setLiveSession(directLive);
              }
            }
          }, onError: (e) => debugPrint('Error watching direct live session: $e'));
        }
      }
      _loading = false;
      notifyListeners();
    }, onError: (err) {
      debugPrint('Error streaming radio doc: $err');
      _loading = false;
      notifyListeners();
    });

    // Stream programs for this radio so we always have the program poster images
    _programsSub = _db
        .collection('programs')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .listen((snap) {
      _programImages.clear();
      for (final doc in snap.docs) {
        final d = doc.data();
        final img = (d['imageUrl'] ?? d['posterUrl'] ?? d['coverUrl'] ?? d['bannerUrl'] ?? d['image'])?.toString();
        if (img != null && img.isNotEmpty) {
          _programImages[doc.id] = img;
        }
      }
      _recomputeLiveAndNext();
    }, onError: (e) => debugPrint('Error streaming programs: $e'));

    // All sessions for this radio (no composite index needed: sorting in memory)
    _sessionsSub = _db
        .collection('sessions')
        .where('radioId', isEqualTo: radioId)
        .snapshots()
        .listen((snap) {
      _allRawSessions = snap.docs
          .map((d) => SessionModel.fromFirestore(d.data(), d.id))
          .toList();
      _recomputeLiveAndNext();
    }, onError: (err) {
      debugPrint('Error streaming sessions: $err');
    });

    // Recompute live and next session every 15 seconds to ensure hero image and show automatically transition
    _timeTicker?.cancel();
    _timeTicker = Timer.periodic(const Duration(seconds: 15), (_) {
      _recomputeLiveAndNext();
    });

    final userId = uid;
    if (userId != null) {
      _favSub = _marks.streamMarksOfType(userId, MarkType.favouriteProgram)
          .listen((s) { _favouritePrograms = s; notifyListeners(); }, onError: (e) => debugPrint('favSub error: $e'));
      _remSub = _marks.streamMarksOfType(userId, MarkType.reminder)
          .listen((s) { _reminders = s; notifyListeners(); }, onError: (e) => debugPrint('remSub error: $e'));
      _listSub = _marks.streamMarksOfType(userId, MarkType.listenLater)
          .listen((s) { _listenLater = s; notifyListeners(); }, onError: (e) => debugPrint('listSub error: $e'));
    }
  }

  // ---------- Follow radio ----------

  Future<void> toggleStarRadio() async {
    final userId = uid;
    if (userId == null || _radio == null) return;
    final isFollowing = _radio!.isFollowed;
    await _db.collection('radios').doc(_radioId).update({
      'followers': isFollowing
          ? FieldValue.arrayRemove([userId])
          : FieldValue.arrayUnion([userId]),
      'followerCount': FieldValue.increment(isFollowing ? -1 : 1),
    });
  }

  // ---------- Program marks ----------

  bool isProgramFavourite(String programId) =>
      _favouritePrograms.contains(programId);

  bool isSessionReminder(String sessionId) => _reminders.contains(sessionId);

  bool isProgramListenLater(String programId) =>
      _listenLater.contains(programId);

  Future<void> toggleFavouriteProgram(String programId, String programName) async {
    final userId = uid;
    if (userId == null) return;
    await _marks.toggle(
      uid: userId,
      type: MarkType.favouriteProgram,
      targetId: programId,
      radioId: _radioId,
      radioName: _radio?.name,
      targetName: programName,
    );
  }

  Future<void> toggleListenLater(String programId, String programName) async {
    final userId = uid;
    if (userId == null) return;
    await _marks.toggle(
      uid: userId,
      type: MarkType.listenLater,
      targetId: programId,
      radioId: _radioId,
      radioName: _radio?.name,
      targetName: programName,
    );
  }

  Future<void> toggleReminder(SessionModel session) async {
    final userId = uid;
    if (userId == null) return;
    await _marks.toggle(
      uid: userId,
      type: MarkType.reminder,
      targetId: session.id,
      radioId: _radioId,
      radioName: _radio?.name,
      targetName: session.programName,
      reminderAt: session.scheduledStart,
    );
  }

  // ---------- Player & Real-Time Listener Stats ----------

  AudioPlayer? _audioPlayer;
  bool _audioPlayerInitialized = false;

  Future<void> _initAudioPlayer() async {
    if (_audioPlayer != null) return;
    try {
      _audioPlayer = AudioPlayer();
      _audioPlayerInitialized = true;

      _audioPlayer!.playerStateStream.listen((state) {
        final isActuallyPlaying = state.playing && state.processingState != ProcessingState.completed;
        if (_isPlaying != isActuallyPlaying) {
          _isPlaying = isActuallyPlaying;
          notifyListeners();
        }
      });

      _audioPlayer!.playbackEventStream.listen(
        (event) {},
        onError: (Object e, StackTrace st) {
          debugPrint('Audio playback error: $e');
          _error = 'Audio stream error: $e';
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint('Error initializing AudioPlayer: $e');
    }
  }

  void togglePlay() {
    if (_isPlaying) {
      pausePlayback();
    } else {
      startPlayback();
    }
  }

  Future<void> startPlayback() async {
    try {
      await _initAudioPlayer();
      if (_audioPlayer == null) {
        throw Exception('AudioPlayer failed to initialize');
      }
      _isPlaying = true;
      _isPlayerDismissed = false;
      _playStartedAt = DateTime.now();
      _incrementListenerCount();

      // Log PLAY activity for Audimat determination
      final curUid = uid ?? 'listener_${DateTime.now().millisecondsSinceEpoch}';
      _activityService.logPlay(
        radioId: _radioId,
        radioName: _radio?.name ?? 'Radio Station',
        userId: curUid,
        sessionId: _liveSession?.id,
        sessionTitle: _liveSession?.programName,
        programId: _liveSession?.programId,
        programCategory: _liveSession?.thematic,
      );

      notifyListeners();

      final primaryUrl = AppConfig.getStreamUrl(_radioId);
      debugPrint('Connecting to live mixer stream: $primaryUrl');

      await _audioPlayer!.stop();
      await _audioPlayer!.setUrl(primaryUrl);
      await _audioPlayer!.play();
    } catch (e) {
      debugPrint('Failed to start mixer playback: $e');
      _isPlaying = false;
      _playStartedAt = null;
      _error = 'Unable to play stream: $e';
      notifyListeners();
    }
  }

  void pausePlayback() {
    if (_isPlaying) {
      _isPlaying = false;
      final curUid = uid ?? 'listener_${DateTime.now().millisecondsSinceEpoch}';
      if (_playStartedAt != null) {
        final duration = DateTime.now().difference(_playStartedAt!).inSeconds;
        _activityService.logPause(
          radioId: _radioId,
          radioName: _radio?.name ?? 'Radio Station',
          userId: curUid,
          durationSeconds: duration,
          sessionId: _liveSession?.id,
          sessionTitle: _liveSession?.programName,
          programId: _liveSession?.programId,
          programCategory: _liveSession?.thematic,
        );
        _playStartedAt = null;
      }
      _decrementListenerCount();
      notifyListeners();
      try {
        _audioPlayer?.pause();
      } catch (e) {
        debugPrint('Error pausing audio player: $e');
      }
    }
  }

  void stopAndDismiss() {
    final curUid = uid ?? 'listener_${DateTime.now().millisecondsSinceEpoch}';
    if (_playStartedAt != null) {
      final duration = DateTime.now().difference(_playStartedAt!).inSeconds;
      _activityService.logStop(
        radioId: _radioId,
        radioName: _radio?.name ?? 'Radio Station',
        userId: curUid,
        durationSeconds: duration,
        sessionId: _liveSession?.id,
        sessionTitle: _liveSession?.programName,
        programId: _liveSession?.programId,
        programCategory: _liveSession?.thematic,
      );
      _playStartedAt = null;
    }
    _isPlaying = false;
    try {
      _audioPlayer?.stop();
    } catch (e) {
      debugPrint('Error stopping audio player: $e');
    }
    _decrementListenerCount();
    _isPlayerDismissed = true;
    notifyListeners();
  }

  Future<void> _incrementListenerCount() async {
    if (_radioId.isEmpty) return;
    try {
      final curUid = uid ?? 'listener_${DateTime.now().millisecondsSinceEpoch}';
      final liveId = _liveSession?.id;

      // 1. RTDB presence with onDisconnect hook
      try {
        if (liveId != null && liveId.isNotEmpty) {
          _myPresenceRef = RealtimeDatabaseService.database.ref('sessions/$liveId/listeners/$curUid');
          await _myPresenceRef!.set({'connectedAt': ServerValue.timestamp});
          await _myPresenceRef!.onDisconnect().remove();
          await RealtimeDatabaseService.database.ref('sessions/$liveId/listenerCount').set(ServerValue.increment(1));
        }
        await RealtimeDatabaseService.database.ref('radios/$_radioId/listenerCount').set(ServerValue.increment(1));
      } catch (e) {
        debugPrint('RTDB presence increment error: $e');
      }

      // 2. Firestore increment
      if (liveId != null && liveId.isNotEmpty) {
        await _db.collection('sessions').doc(liveId).update({
          'listenerCount': FieldValue.increment(1),
          'peakListeners': FieldValue.increment(1),
        }).catchError((_) {});

        // Post timeseries point for technician metrics
        final currentCount = (_liveSession?.listenerCount ?? 0) + 1;
        await _db.collection('listener_analytics').add({
          'sessionId': liveId,
          'radioId': _radioId,
          'count': currentCount,
          'date': FieldValue.serverTimestamp(),
        }).catchError((_) {});
      }

      await _db.collection('radios').doc(_radioId).update({
        'listenerCount': FieldValue.increment(1),
      }).catchError((_) {});

      _hasRegisteredPresence = true;
    } catch (e) {
      debugPrint('Error incrementing listener count: $e');
    }
  }

  Future<void> _decrementListenerCount() async {
    if (!_hasRegisteredPresence) return;
    _hasRegisteredPresence = false;
    try {
      final liveId = _liveSession?.id;
      // 1. RTDB removal
      try {
        await _myPresenceRef?.remove();
        _myPresenceRef = null;
        if (liveId != null && liveId.isNotEmpty) {
          await RealtimeDatabaseService.database.ref('sessions/$liveId/listenerCount').set(ServerValue.increment(-1));
        }
        await RealtimeDatabaseService.database.ref('radios/$_radioId/listenerCount').set(ServerValue.increment(-1));
      } catch (e) {
        debugPrint('RTDB presence decrement error: $e');
      }

      // 2. Firestore decrement
      if (liveId != null && liveId.isNotEmpty) {
        await _db.collection('sessions').doc(liveId).update({
          'listenerCount': FieldValue.increment(-1),
        }).catchError((_) {});
      }

      await _db.collection('radios').doc(_radioId).update({
        'listenerCount': FieldValue.increment(-1),
      }).catchError((_) {});
    } catch (e) {
      debugPrint('Error decrementing listener count: $e');
    }
  }

  // ---------- Poll ----------

  void _watchPoll(String sessionId) {
    _pollSub?.cancel();
    _rtdbPollSub?.cancel();
    _myVoteSub?.cancel();
    _rtdbVoteSub?.cancel();

    // 1. WebSocket / Firebase Realtime Database poll listener
    try {
      final rtdbRef = RealtimeDatabaseService.database.ref('polls/$sessionId');
      _rtdbPollSub = rtdbRef.onValue.listen((event) {
        final val = event.snapshot.value;
        if (val != null && val is Map) {
          final map = <String, dynamic>{};
          val.forEach((k, v) => map[k.toString()] = v);
          final st = map['status']?.toString();
          if (st == 'active' || st == null) {
            final poll = Poll.fromMap(map, map['id']?.toString() ?? sessionId);
            _activePoll = poll;
            _watchMyVote(poll.id, sessionId: sessionId);
            notifyListeners();
          } else if (st == 'closed') {
            if (_activePoll?.sessionId == sessionId) {
              _activePoll = null;
              _hasVoted = false;
              _myVoteIndex = null;
              notifyListeners();
            }
          }
        }
      }, onError: (e) {
        debugPrint('RTDB poll stream error: $e');
      });
    } catch (e) {
      debugPrint('RTDB poll init error: $e');
    }

    // 2. Firestore polls stream fallback
    _pollSub = _db
        .collection('polls')
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .listen((snap) {
      final activeDocs = snap.docs
          .where((d) => (d.data()['status'] ?? 'active') == 'active')
          .toList();
      if (activeDocs.isEmpty) {
        if (_activePoll?.sessionId == sessionId && _rtdbPollSub == null) {
          _activePoll = null;
          _hasVoted = false;
          _myVoteIndex = null;
          notifyListeners();
        }
      } else {
        // Only set from Firestore if RTDB hasn't provided the poll yet
        if (_activePoll == null || _activePoll?.sessionId != sessionId) {
          final doc = activeDocs.first;
          final poll = Poll.fromFirestore(doc.data(), doc.id);
          _activePoll = poll;
          _watchMyVote(poll.id, sessionId: sessionId);
          notifyListeners();
        }
      }
    }, onError: (err) {
      debugPrint('Firestore poll stream error: $err');
    });
  }

  void _watchMyVote(String pollId, {String? sessionId}) {
    final curUid = uid;
    if (curUid == null) return;
    _myVoteSub?.cancel();
    _rtdbVoteSub?.cancel();

    // 1. Realtime Database vote listener (WebSocket)
    if (sessionId != null) {
      _rtdbVoteSub = RealtimeDatabaseService.database
          .ref('polls/$sessionId/votes/$curUid')
          .onValue
          .listen((event) {
        final val = event.snapshot.value;
        if (val != null && val is Map) {
          final m = Map<String, dynamic>.from(val);
          _hasVoted = true;
          _myVoteIndex = (m['optionIndex'] as num?)?.toInt() ?? 0;
          notifyListeners();
        }
      }, onError: (_) {});
    }

    // 2. Firestore vote fallback
    _myVoteSub = _db
        .collection('polls')
        .doc(pollId)
        .collection('votes')
        .doc(curUid)
        .snapshots()
        .listen((doc) {
      if (doc.exists) {
        _hasVoted = true;
        _myVoteIndex = (doc.data()?['optionIndex'] ?? 0) as int;
        notifyListeners();
      }
    }, onError: (e) => debugPrint('Error watching my vote: $e'));
  }

  void setShowPollModal(bool v) {
    _showPollModal = v;
    notifyListeners();
  }

  Future<void> voteOnPoll(int optionIndex) async {
    if (_activePoll == null) return;
    final poll = _activePoll!;
    final pollId = poll.id;
    final sessionId = poll.sessionId;
    final curUid = uid;

    // Optimistic update so UI immediately shows the answered state and updated count
    _hasVoted = true;
    _myVoteIndex = optionIndex;
    final newCounts = Map<String, int>.from(poll.voteCounts);
    newCounts['$optionIndex'] = (newCounts['$optionIndex'] ?? 0) + 1;
    _activePoll = poll.copyWith(
      totalVotes: poll.totalVotes + 1,
      voteCounts: newCounts,
    );
    notifyListeners();

    // 1. WebSocket / Realtime Database vote
    try {
      final rtdb = RealtimeDatabaseService.database.ref('polls/$sessionId');
      await rtdb.child('totalVotes').set(ServerValue.increment(1));
      await rtdb.child('voteCounts/$optionIndex').set(ServerValue.increment(1));
      if (curUid != null) {
        await rtdb.child('votes/$curUid').set({
          'optionIndex': optionIndex,
          'votedAt': ServerValue.timestamp,
        });
      }
    } catch (e) {
      debugPrint('RTDB voteOnPoll note: $e');
    }

    // 2. Cloud Function & Firestore fallback
    try {
      await CloudFunctionCaller.call('votePoll', {
        'pollId': pollId,
        'optionIndex': optionIndex,
      });
    } catch (e) {
      debugPrint('votePoll callable note: $e');
      if (curUid != null) {
        try {
          final pollRef = _db.collection('polls').doc(pollId);
          final voteRef = pollRef.collection('votes').doc(curUid);

          await _db.runTransaction((tx) async {
            final existing = await tx.get(voteRef);
            if (!existing.exists) {
              tx.set(voteRef, {
                'optionIndex': optionIndex,
                'votedAt': FieldValue.serverTimestamp(),
              });
              tx.update(pollRef, {
                'voteCounts.$optionIndex': FieldValue.increment(1),
                'totalVotes': FieldValue.increment(1),
              });
            }
          });
        } catch (dbErr) {
          debugPrint('Firestore vote fallback error: $dbErr');
        }
      }
    }
  }

  // ---------- Calls (VOIP Studio Connection) ----------

  void _recomputeLiveAndNext() {
    if (_allRawSessions.isEmpty) return;
    final now = DateTime.now();

    // Enrich sessions with program imageUrl if session has none
    final all = _allRawSessions.map((s) {
      if ((s.imageUrl == null || s.imageUrl!.isEmpty) && _programImages.containsKey(s.programId)) {
        return s.copyWith(imageUrl: _programImages[s.programId]);
      }
      return s;
    }).toList()
      ..sort((a, b) => a.scheduledStart.compareTo(b.scheduledStart));

    // Multi-layer live session detection:
    // 1. Explicit onAir status
    // 2. Or matches radio.currentLiveSessionId
    // 3. Or active scheduled time slot (started <= now <= ended and not ended/cancelled)
    SessionModel? live = _firstOrNull(
        all.where((s) => s.status == SessionStatus.onAir));

    if (live == null && _radio?.currentLiveSessionId != null && _radio!.currentLiveSessionId!.isNotEmpty) {
      live = _firstOrNull(
          all.where((s) => s.id == _radio!.currentLiveSessionId));
    }

    if (live == null) {
      live = _firstOrNull(all.where((s) =>
          s.scheduledStart.isBefore(now) &&
          s.scheduledEnd.isAfter(now) &&
          s.status != SessionStatus.ended &&
          s.status != SessionStatus.cancelled));
    }

    _setLiveSession(live);

    final upcoming = all
        .where((s) =>
            s.status == SessionStatus.scheduled &&
            s.scheduledEnd.isAfter(now) &&
            s.id != _liveSession?.id)
        .toList();

    _nextSession = upcoming.isNotEmpty ? upcoming.first : null;

    final cutoff = now.add(const Duration(hours: 24));
    _upcomingSessions = upcoming
        .where((s) => s.scheduledStart.isBefore(cutoff))
        .toList();

    notifyListeners();
  }

  // ---------- Calls (VOIP Studio Connection) ----------

  void _watchMyCall(String sessionId) {
    var curUid = uid;
    if (curUid == null) return;
    _callSub?.cancel();
    _rtdbCallSub?.cancel();

    // 1. Listen to Firestore calls for this user (single-field equality, no composite index needed)
    _callSub = _db
        .collection('calls')
        .where('userId', isEqualTo: curUid)
        .snapshots()
        .listen((snap) {
      final active = snap.docs.where((d) {
        final data = d.data();
        if (data['sessionId'] != sessionId) return false;
        final st = data['status']?.toString();
        return st == 'pending' || st == 'accepted' || st == 'held';
      }).toList();

      if (active.isNotEmpty) {
        _myCallStatus = active.first.data()['status'] as String?;
      } else {
        if (_myCallStatus != 'accepted' && _myCallStatus != 'held' && _myCallStatus != 'pending') {
          _myCallStatus = null;
        }
      }
      notifyListeners();
    }, onError: (e) {
      debugPrint('Error in _watchMyCall firestore: $e');
    });

    // 2. Listen to Realtime Database calls for instant WebSocket updates
    try {
      final ref = RealtimeDatabaseService.database.ref('calls/$sessionId');
      _rtdbCallSub = ref.onValue.listen((event) {
        final val = event.snapshot.value;
        if (val is Map) {
          String? foundStatus;
          val.forEach((k, v) {
            if (v is Map && v['userId'] == curUid) {
              final st = v['status']?.toString();
              if (st == 'pending' || st == 'accepted' || st == 'held') {
                foundStatus = st;
              } else if (st == 'dropped' || st == 'ended' || st == 'declined') {
                foundStatus = 'none';
              }
            }
          });
          if (foundStatus != null) {
            _myCallStatus = foundStatus == 'none' ? null : foundStatus;
            notifyListeners();
          }
        }
      }, onError: (e) {
        debugPrint('RTDB _watchMyCall error: $e');
      });
    } catch (e) {
      debugPrint('RTDB call watch error: $e');
    }
  }

  Future<void> requestCall(String callerTopicOrName) async {
    if (_liveSession == null) throw Exception('No live session currently on air');
    final sessionId = _liveSession!.id;
    var curUid = uid;
    if (curUid == null) {
      try {
        final cred = await _auth.signInAnonymously();
        curUid = cred.user?.uid;
      } catch (e) {
        debugPrint('Anonymous auth error in requestCall: $e');
      }
    }
    if (curUid == null) throw Exception('Please log in to request a VOIP call');

    final user = _auth.currentUser;
    // Resolve user's actual display name
    String resolvedName = '';
    if (user != null && user.displayName != null && user.displayName!.trim().isNotEmpty) {
      resolvedName = user.displayName!.trim();
    }
    if (resolvedName.isEmpty && curUid.isNotEmpty) {
      try {
        final uDoc = await _db.collection('users').doc(curUid).get();
        if (uDoc.exists) {
          final ud = uDoc.data() ?? {};
          final raw = ud['displayName'] ?? ud['name'] ?? ud['fullName'] ?? ud['username'];
          if (raw != null && raw.toString().trim().isNotEmpty) {
            resolvedName = raw.toString().trim();
            try {
              await user?.updateDisplayName(resolvedName);
            } catch (_) {}
          }
        }
      } catch (_) {}
    }
    if (resolvedName.isEmpty && user?.email != null && user!.email!.isNotEmpty) {
      resolvedName = user.email!.split('@').first;
    }
    if (resolvedName.isEmpty) {
      resolvedName = 'Listener';
    }

    final topic = callerTopicOrName.trim();

    try {
      // 1. Stop radio audio playback so background station audio does not feed into caller's mic
      if (_isPlaying) {
        pausePlayback();
      }

      // 2. Request device microphone & speaker permissions via browser/WebRTC
      try {
        await VoipAudioService.requestMicAndSpeaker();
      } catch (micErr) {
        debugPrint('Voip mic access notice: $micErr');
      }

      final sessionRef = _db.collection('sessions').doc(sessionId);

      // Clean up any stale active calls for this user (avoids false-positive queue locks)
      final existing = await _db
          .collection('calls')
          .where('userId', isEqualTo: curUid)
          .limit(10)
          .get();

      for (final doc in existing.docs) {
        final data = doc.data();
        if (data['sessionId'] != sessionId) continue;
        final st = data['status'];
        if (st == 'pending' || st == 'accepted' || st == 'held') {
          await doc.reference.update({
            'status': 'dropped',
            'endedAt': FieldValue.serverTimestamp(),
          }).catchError((_) {});
          try {
            await RealtimeDatabaseService.database
                .ref('calls/$sessionId/${doc.id}')
                .update({'status': 'dropped'});
          } catch (_) {}
        }
      }

      // Generate a common ID for both Firestore and Realtime Database
      final callDocRef = _db.collection('calls').doc();
      final callId = callDocRef.id;

      // 1. Write to Firestore
      await callDocRef.set({
        'sessionId': sessionId,
        'radioId': _radioId,
        'userId': curUid,
        'userName': resolvedName,
        'userPhone': user?.phoneNumber ?? 'VOIP',
        'topic': topic,
        'callType': 'voip',
        'isVoip': true,
        'status': 'pending',
        'requestedAt': FieldValue.serverTimestamp(),
        'acceptedAt': null,
        'heldAt': null,
        'holdCount': 0,
        'lastActionBy': 'listener',
      });

      // 2. Write to Realtime Database (instant WebSocket)
      try {
        await RealtimeDatabaseService.database.ref('calls/$sessionId/$callId').set({
          'id': callId,
          'sessionId': sessionId,
          'radioId': _radioId,
          'userId': curUid,
          'userName': resolvedName,
          'userPhone': user?.phoneNumber ?? 'VOIP',
          'topic': topic,
          'callType': 'voip',
          'isVoip': true,
          'status': 'pending',
          'requestedAt': ServerValue.timestamp,
        });
      } catch (rtdbErr) {
        debugPrint('RTDB call write error: $rtdbErr');
      }

      await sessionRef.update({
        'callsCount': FieldValue.increment(1),
        'engagementCount': FieldValue.increment(1),
      }).catchError((_) {});

      _myCallStatus = 'pending';
      notifyListeners();
    } catch (e) {
      debugPrint('requestCall error: $e');
      rethrow;
    }
  }

  Future<void> cancelCallRequest() async {
    if (_liveSession == null) return;
    final curUid = uid;
    if (curUid == null) return;
    final sessionId = _liveSession!.id;

    final snap = await _db
        .collection('calls')
        .where('userId', isEqualTo: curUid)
        .limit(10)
        .get();

    for (final doc in snap.docs) {
      final data = doc.data();
      if (data['sessionId'] != sessionId) continue;
      final st = data['status'];
      if (st == 'pending' || st == 'held' || st == 'accepted') {
        await doc.reference.update({
          'status': 'dropped',
          'endedAt': FieldValue.serverTimestamp(),
        });
        try {
          await RealtimeDatabaseService.database
              .ref('calls/$sessionId/${doc.id}')
              .update({'status': 'dropped'});
        } catch (_) {}
      }
    }
    _myCallStatus = null;
    VoipAudioService.stopAudio();
    notifyListeners();
  }

  // ---------- Helpers ----------

  SessionModel? _firstOrNull(Iterable<SessionModel> it) {
    for (final s in it) return s;
    return null;
  }

  void _detach() {
    if (_isPlaying) {
      if (_playStartedAt != null) {
        final duration = DateTime.now().difference(_playStartedAt!).inSeconds;
        final curUid = uid ?? 'listener_${DateTime.now().millisecondsSinceEpoch}';
        _activityService.logStop(
          radioId: _radioId,
          radioName: _radio?.name ?? 'Radio Station',
          userId: curUid,
          durationSeconds: duration,
          sessionId: _liveSession?.id,
          sessionTitle: _liveSession?.programName,
          programId: _liveSession?.programId,
          programCategory: _liveSession?.thematic,
        );
        _playStartedAt = null;
      }
      _decrementListenerCount();
      _isPlaying = false;
    }
    VoipAudioService.stopAudio();
    _timeTicker?.cancel();
    _radioSub?.cancel();
    _directLiveSub?.cancel();
    _sessionsSub?.cancel();
    _programsSub?.cancel();
    _favSub?.cancel();
    _remSub?.cancel();
    _listSub?.cancel();
    _pollSub?.cancel();
    _rtdbPollSub?.cancel();
    _myVoteSub?.cancel();
    _rtdbVoteSub?.cancel();
    _callSub?.cancel();
    _rtdbCallSub?.cancel();
  }

  @override
  void dispose() {
    _detach();
    try {
      _audioPlayer?.dispose();
    } catch (_) {}
    _audioPlayer = null;
    _audioPlayerInitialized = false;
    super.dispose();
  }

  // Mini-player & station info helpers
  String? get currentProgramImage => (_liveSession?.imageUrl != null && _liveSession!.imageUrl!.isNotEmpty)
      ? _liveSession!.imageUrl
      : (_radio?.bannerUrl != null && _radio!.bannerUrl!.isNotEmpty
          ? _radio!.bannerUrl
          : (_radio?.logoUrl != null && _radio!.logoUrl!.isNotEmpty ? _radio!.logoUrl : null));
  String get currentTitle => _liveSession?.programName ?? _radio?.name ?? 'Radio Station';
  String get currentSubtitle => _liveSession?.hostName != null && _liveSession!.hostName!.isNotEmpty
      ? 'Host: ${_liveSession!.hostName}'
      : (_radio?.city != null && _radio!.city!.isNotEmpty ? '${_radio!.city} · Live' : 'Live On Air');
  bool get hasActiveSession => _liveSession != null || _radio != null;

  // Backward-compatibility aliases
  void loadRadioData(String radioId) => attach(radioId);
  bool get isLoading => _loading;
}
