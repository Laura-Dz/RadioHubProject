import 'package:flutter/foundation.dart';
import '../core/models/show_model.dart';
import '../core/models/user_model.dart';
import '../core/services/firestore_service.dart';
import 'base_view_model.dart';

class HomeViewModel extends BaseViewModel {
  final FirestoreService _firestoreService;

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
    await Future.delayed(const Duration(milliseconds: 300));
    _liveShows = [
      ShowModel(
        id: 'live_1',
        title: 'Morning Drive Radio',
        host: 'Sarah Johnson',
        imageUrl: 'https://picsum.photos/seed/morning/400/300',
        category: ShowCategory.talk,
        status: ShowStatus.live,
        startTime: DateTime.now().subtract(const Duration(hours: 1)),
        endTime: DateTime.now().add(const Duration(hours: 1)),
        listenerCount: 1234,
        rating: 4.8,
        isFollowed: true,
        tags: ['morning', 'talk', 'news'],
        description: 'Start your day with Sarah!',
      ),
      ShowModel(
        id: 'live_2',
        title: 'Tech Talk Live',
        host: 'Mike Chen',
        imageUrl: 'https://picsum.photos/seed/tech/400/300',
        category: ShowCategory.education,
        status: ShowStatus.live,
        startTime: DateTime.now().subtract(const Duration(minutes: 30)),
        endTime: DateTime.now().add(const Duration(hours: 2)),
        listenerCount: 845,
        rating: 4.9,
        isFollowed: false,
        tags: ['tech', 'education', 'live'],
        description: 'Latest tech discussions',
      ),
      ShowModel(
        id: 'live_3',
        title: 'Music Mix Live',
        host: 'DJ Flow',
        imageUrl: 'https://picsum.photos/seed/music/400/300',
        category: ShowCategory.music,
        status: ShowStatus.live,
        startTime: DateTime.now().subtract(const Duration(minutes: 15)),
        endTime: DateTime.now().add(const Duration(hours: 3)),
        listenerCount: 2100,
        rating: 4.7,
        isFollowed: true,
        tags: ['music', 'dj', 'live'],
        description: 'Best music mix',
      ),
    ];
  }

  Future<void> _loadFollowedShows() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _followedShows = [
      ShowModel(
        id: 'followed_1',
        title: 'Weekend Special',
        host: 'Emma Wilson',
        imageUrl: 'https://picsum.photos/seed/weekend/400/300',
        category: ShowCategory.entertainment,
        status: ShowStatus.upcoming,
        startTime: DateTime.now().add(const Duration(hours: 2)),
        listenerCount: 567,
        rating: 4.6,
        isFollowed: true,
        tags: ['weekend', 'special'],
        description: 'Fun weekend show',
      ),
      ShowModel(
        id: 'followed_2',
        title: 'News Hour',
        host: 'James Brown',
        imageUrl: 'https://picsum.photos/seed/news/400/300',
        category: ShowCategory.news,
        status: ShowStatus.upcoming,
        startTime: DateTime.now().add(const Duration(hours: 5)),
        listenerCount: 234,
        rating: 4.4,
        isFollowed: true,
        tags: ['news', 'hour'],
        description: 'Evening news',
      ),
    ];
  }

  Future<void> _loadChannels() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _channels = [
      ShowModel(
        id: 'channel_1',
        title: 'Radio One',
        host: 'Various',
        imageUrl: 'https://picsum.photos/seed/radio1/400/300',
        category: ShowCategory.music,
        status: ShowStatus.live,
        listenerCount: 4500,
        rating: 4.7,
        isFollowed: true,
        tags: ['pop', 'hits'],
        description: 'Top 40 hits',
      ),
      ShowModel(
        id: 'channel_2',
        title: 'Classical FM',
        host: 'Various',
        imageUrl: 'https://picsum.photos/seed/classical/400/300',
        category: ShowCategory.music,
        status: ShowStatus.recorded,
        listenerCount: 1200,
        rating: 4.9,
        isFollowed: false,
        tags: ['classical', 'orchestra'],
        description: 'Classical music',
      ),
      ShowModel(
        id: 'channel_3',
        title: 'Sports Talk',
        host: 'Various',
        imageUrl: 'https://picsum.photos/seed/sports/400/300',
        category: ShowCategory.sports,
        status: ShowStatus.live,
        listenerCount: 3200,
        rating: 4.5,
        isFollowed: false,
        tags: ['sports', 'live'],
        description: 'Sports news',
      ),
    ];
  }

  Future<void> _loadRecommendedShows() async {
    await Future.delayed(const Duration(milliseconds: 300));
    _recommendedShows = [
      ShowModel(
        id: 'rec_1',
        title: 'Late Night Vibes',
        host: 'Alex Rivera',
        imageUrl: 'https://picsum.photos/seed/late/400/300',
        category: ShowCategory.music,
        status: ShowStatus.recorded,
        listenerCount: 890,
        rating: 4.8,
        isFollowed: false,
        tags: ['night', 'relax'],
        description: 'Chill vibes',
      ),
      ShowModel(
        id: 'rec_2',
        title: 'Comedy Hour',
        host: 'Lisa Chen',
        imageUrl: 'https://picsum.photos/seed/comedy/400/300',
        category: ShowCategory.comedy,
        status: ShowStatus.recorded,
        listenerCount: 670,
        rating: 4.6,
        isFollowed: false,
        tags: ['comedy', 'humor'],
        description: 'Laugh out loud',
      ),
      ShowModel(
        id: 'rec_3',
        title: 'Mindful Morning',
        host: 'Dr. Smith',
        imageUrl: 'https://picsum.photos/seed/mindful/400/300',
        category: ShowCategory.education,
        status: ShowStatus.upcoming,
        startTime: DateTime.now().add(const Duration(hours: 10)),
        listenerCount: 340,
        rating: 4.9,
        isFollowed: false,
        tags: ['mindful', 'morning'],
        description: 'Start your day right',
      ),
    ];
  }

  Future<void> _loadTrendingShows() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _trendingShows = [
      ShowModel(
        id: 'trend_1',
        title: 'Global Top 40',
        host: 'DJ Max',
        imageUrl: 'https://picsum.photos/seed/global/400/300',
        category: ShowCategory.music,
        status: ShowStatus.live,
        listenerCount: 5600,
        rating: 4.7,
        isFollowed: false,
        tags: ['top40', 'global'],
        description: 'Worldwide hits',
      ),
      ShowModel(
        id: 'trend_2',
        title: 'Tech Trends',
        host: 'Sarah Kim',
        imageUrl: 'https://picsum.photos/seed/trends/400/300',
        category: ShowCategory.education,
        status: ShowStatus.recorded,
        listenerCount: 2100,
        rating: 4.8,
        isFollowed: false,
        tags: ['tech', 'trends'],
        description: 'Latest tech news',
      ),
      ShowModel(
        id: 'trend_3',
        title: 'Political Debate',
        host: 'David Miller',
        imageUrl: 'https://picsum.photos/seed/debate/400/300',
        category: ShowCategory.news,
        status: ShowStatus.recorded,
        listenerCount: 3400,
        rating: 4.3,
        isFollowed: false,
        tags: ['politics', 'debate'],
        description: 'Current affairs',
      ),
      ShowModel(
        id: 'trend_4',
        title: 'Health & Wellness',
        host: 'Dr. Thompson',
        imageUrl: 'https://picsum.photos/seed/health/400/300',
        category: ShowCategory.education,
        status: ShowStatus.upcoming,
        startTime: DateTime.now().add(const Duration(hours: 8)),
        listenerCount: 1500,
        rating: 4.9,
        isFollowed: false,
        tags: ['health', 'wellness'],
        description: 'Healthy living tips',
      ),
    ];
  }

  Future<void> _loadNewEpisodes() async {
    await Future.delayed(const Duration(milliseconds: 200));
    _newEpisodes = [
      ShowModel(
        id: 'new_1',
        title: 'Mindful Meditation - S3',
        host: 'Dr. Smith',
        imageUrl: 'https://picsum.photos/seed/meditation/400/300',
        category: ShowCategory.education,
        status: ShowStatus.recorded,
        listenerCount: 450,
        rating: 4.9,
        isFollowed: true,
        tags: ['meditation', 'mindful'],
        description: 'Season 3 Episode 1',
      ),
      ShowModel(
        id: 'new_2',
        title: 'Tech Insights - E12',
        host: 'Mike Chen',
        imageUrl: 'https://picsum.photos/seed/insights/400/300',
        category: ShowCategory.education,
        status: ShowStatus.recorded,
        listenerCount: 320,
        rating: 4.7,
        isFollowed: true,
        tags: ['tech', 'insights'],
        description: 'New episode available',
      ),
      ShowModel(
        id: 'new_3',
        title: 'True Crime - S2',
        host: 'Lisa Thompson',
        imageUrl: 'https://picsum.photos/seed/crime/400/300',
        category: ShowCategory.entertainment,
        status: ShowStatus.recorded,
        listenerCount: 780,
        rating: 4.6,
        isFollowed: false,
        tags: ['crime', 'true'],
        description: 'Season 2 Premiere',
      ),
    ];
  }

  void refreshData() => loadHomeData();

  @override
  void dispose() {
    super.dispose();
  }
}
