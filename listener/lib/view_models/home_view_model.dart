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
      final snapshot = await _firestore
          .collection('shows')
          .where('status', isEqualTo: 'live')
          .orderBy('listenerCount', descending: true)
          .limit(10)
          .get();
      _liveShows = snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading live shows: $e');
      _liveShows = [];
    }
  }

  Future<void> _loadFollowedShows() async {
    try {
      final userId = _firestoreService.getCurrentUserId();
      if (userId == null) {
        _followedShows = [];
        return;
      }
      final snapshot = await _firestore
          .collection('shows')
          .where('followers', arrayContains: userId)
          .where('isActive', isEqualTo: true)
          .orderBy('startTime')
          .limit(10)
          .get();
      _followedShows = snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading followed shows: $e');
      _followedShows = [];
    }
  }

  Future<void> _loadChannels() async {
    try {
      final snapshot = await _firestore
          .collection('channels')
          .where('isActive', isEqualTo: true)
          .orderBy('followerCount', descending: true)
          .limit(10)
          .get();
      _channels = snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading channels: $e');
      _channels = [];
    }
  }

  Future<void> _loadRecommendedShows() async {
    try {
      final snapshot = await _firestore
          .collection('shows')
          .where('isActive', isEqualTo: true)
          .orderBy('rating', descending: true)
          .limit(10)
          .get();
      _recommendedShows = snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading recommended shows: $e');
      _recommendedShows = [];
    }
  }

  Future<void> _loadTrendingShows() async {
    try {
      final snapshot = await _firestore
          .collection('shows')
          .where('isActive', isEqualTo: true)
          .orderBy('listenerCount', descending: true)
          .limit(10)
          .get();
      _trendingShows = snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e) {
      debugPrint('Error loading trending shows: $e');
      _trendingShows = [];
    }
  }

  Future<void> _loadNewEpisodes() async {
    try {
      final snapshot = await _firestore
          .collection('shows')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(10)
          .get();
      _newEpisodes = snapshot.docs
          .map((doc) => ShowModel.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
          .toList();
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
