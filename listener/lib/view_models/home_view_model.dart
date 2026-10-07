import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/models/show_model.dart';
import '../core/models/user_model.dart';
import '../core/services/firestore_service.dart';
import 'base_view_model.dart';

class HomeViewModel extends BaseViewModel {
  final FirestoreService _firestoreService;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  UserModel? _currentUser;
  List<ShowModel> _liveShows = [];
  List<ShowModel> _followedShows = [];
  List<ShowModel> _channels = [];
  List<ShowModel> _recommendedShows = [];
  List<ShowModel> _trendingShows = [];
  List<ShowModel> _newEpisodes = [];
  bool _isLoading = true;

  HomeViewModel({
    required FirestoreService firestoreService,
  }) : _firestoreService = firestoreService {
    loadHomeData();
  }

  UserModel? get currentUser => _currentUser;
  List<ShowModel> get liveShows => _liveShows;
  List<ShowModel> get followedShows => _followedShows;
  List<ShowModel> get channels => _channels;
  List<ShowModel> get recommendedShows => _recommendedShows;
  List<ShowModel> get trendingShows => _trendingShows;
  List<ShowModel> get newEpisodes => _newEpisodes;
  @override
  bool get isLoading => _isLoading;

  String get welcomeMessage {
    final name = _currentUser?.displayName ?? 'Listener';
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning, $name ☀️';
    if (hour < 17) return 'Good Afternoon, $name 🌤️';
    if (hour < 21) return 'Good Evening, $name 🌅';
    return 'Good Night, $name 🌙';
  }

  Future<void> loadHomeData() async {
    await execute(() async {
      _isLoading = true;
      notifyListeners();

      try {
        _currentUser = await _firestoreService.getCurrentUser();
        await Future.wait([
          _loadLiveShows(),
          _loadFollowedShows(),
          _loadChannels(),
          _loadRecommendedShows(),
          _loadTrendingShows(),
          _loadNewEpisodes(),
        ]);
      } catch (e) {
        setError('Failed to load home data');
      } finally {
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  Future<void> _loadLiveShows() async {
    try {
      final List<ShowModel> liveList = [];

      // 1. Fetch active ongoing sessions from 'sessions' collection
      try {
        final sessionsSnap = await _firestore
            .collection('sessions')
            .where('status', whereIn: ['on_air', 'live'])
            .limit(20)
            .get();

        for (final doc in sessionsSnap.docs) {
          final data = doc.data();
          liveList.add(ShowModel.fromSession(data, doc.id));
        }
      } catch (sessionErr) {
        debugPrint('Error loading live sessions: $sessionErr');
      }

      // 2. Also fetch from 'shows' collection where status is live
      try {
        final showsSnap = await _firestore
            .collection('shows')
            .where('status', isEqualTo: 'live')
            .limit(20)
            .get();

        for (final doc in showsSnap.docs) {
          // Avoid duplicate entry if same show or session
          if (!liveList.any((s) => s.id == doc.id || s.title == (doc.data()['title'] ?? doc.data()['name']))) {
            liveList.add(ShowModel.fromFirestore(doc.data(), doc.id));
          }
        }
      } catch (showsErr) {
        debugPrint('Error loading live shows collection: $showsErr');
      }

      liveList.sort((a, b) => b.listenerCount.compareTo(a.listenerCount));
      _liveShows = liveList.take(15).toList();
    } catch (e) {
      debugPrint('Error loading live shows: $e');
      _liveShows = [];
    }
  }

  Future<void> _loadFollowedShows() async {
    try {
      final userId = _firestoreService.getCurrentUserId();
      if (userId == null || userId.isEmpty) {
        _followedShows = [];
        return;
      }
      final snapshot = await _firestore
          .collection('shows')
          .where('followers', arrayContains: userId)
          .limit(20)
          .get();
      final list = snapshot.docs
          .where((doc) => (doc.data()['isActive'] ?? true) != false)
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        if (a.startTime == null) return 1;
        if (b.startTime == null) return -1;
        return a.startTime!.compareTo(b.startTime!);
      });
      _followedShows = list.take(10).toList();
    } catch (e) {
      debugPrint('Error loading followed shows: $e');
      _followedShows = [];
    }
  }

  Future<void> _loadChannels() async {
    try {
      var snapshot = await _firestore
          .collection('radios')
          .limit(20)
          .get();
      if (snapshot.docs.isEmpty) {
        snapshot = await _firestore
            .collection('channels')
            .limit(20)
            .get();
      }
      final list = snapshot.docs
          .where((doc) => (doc.data()['isActive'] ?? true) != false)
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => (b.followerCount ?? 0).compareTo(a.followerCount ?? 0));
      _channels = list.take(10).toList();
    } catch (e) {
      debugPrint('Error loading channels: $e');
      _channels = [];
    }
  }

  Future<void> _loadRecommendedShows() async {
    try {
      final snapshot = await _firestore
          .collection('shows')
          .limit(20)
          .get();
      final list = snapshot.docs
          .where((doc) => (doc.data()['isActive'] ?? true) != false)
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.rating.compareTo(a.rating));
      _recommendedShows = list.take(10).toList();
    } catch (e) {
      debugPrint('Error loading recommended shows: $e');
      _recommendedShows = [];
    }
  }

  Future<void> _loadTrendingShows() async {
    try {
      final snapshot = await _firestore
          .collection('shows')
          .limit(20)
          .get();
      final list = snapshot.docs
          .where((doc) => (doc.data()['isActive'] ?? true) != false)
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) => b.listenerCount.compareTo(a.listenerCount));
      _trendingShows = list.take(10).toList();
    } catch (e) {
      debugPrint('Error loading trending shows: $e');
      _trendingShows = [];
    }
  }

  Future<void> _loadNewEpisodes() async {
    try {
      final snapshot = await _firestore
          .collection('shows')
          .limit(20)
          .get();
      final list = snapshot.docs
          .where((doc) => (doc.data()['isActive'] ?? true) != false)
          .map((doc) => ShowModel.fromFirestore(doc.data(), doc.id))
          .toList();
      list.sort((a, b) {
        final aDate = a.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bDate = b.startTime ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bDate.compareTo(aDate);
      });
      _newEpisodes = list.take(10).toList();
    } catch (e) {
      debugPrint('Error loading new episodes: $e');
      _newEpisodes = [];
    }
  }

  Future<void> refreshData() => loadHomeData();

  @override
  void dispose() {
    super.dispose();
  }
}
