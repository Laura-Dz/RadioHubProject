import 'package:flutter/foundation.dart';
import '../../core/models/channel_model.dart';
import '../../core/services/channel_service.dart';

class ChannelsViewModel extends ChangeNotifier {
  final ChannelService _channelService;

  List<ChannelModel> _channels = [];
  List<ChannelModel> _featuredChannels = [];
  List<ChannelModel> _trendingChannels = [];
  List<String> _categories = ['all'];

  bool _isLoading = false;
  bool _hasMore = true;
  String? _error;

  String? _selectedCategory;
  String? _searchQuery;

  ChannelsViewModel(this._channelService);

  List<ChannelModel> get channels => _channels;
  List<ChannelModel> get featuredChannels => _featuredChannels;
  List<ChannelModel> get trendingChannels => _trendingChannels;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get hasMore => _hasMore;
  String? get error => _error;
  String? get selectedCategory => _selectedCategory;
  String? get searchQuery => _searchQuery;

  Future<void> loadInitialData() async {
    _setLoading(true);
    _error = null;

    try {
      final categories = await _channelService.getCategories();
      final featuredChannels = await _channelService.getFeaturedChannels(limit: 5);
      final trendingChannels = await _channelService.getTrendingChannels(limit: 10);
      final channels = await _channelService.getChannels(limit: 20);

      _categories = ['all', ...categories];
      _featuredChannels = featuredChannels;
      _trendingChannels = trendingChannels;
      _channels = channels;
      _hasMore = channels.length >= 20;
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadChannels() async {
    if (_isLoading || !_hasMore) return;

    _setLoading(true);
    _error = null;

    try {
      final newChannels = await _channelService.getChannels(
        category: _selectedCategory,
        searchQuery: _searchQuery,
        limit: 20,
      );

      if (newChannels.isEmpty) {
        _hasMore = false;
      } else {
        _channels.addAll(newChannels);
        _hasMore = newChannels.length >= 20;
      }
    } catch (e) {
      _error = e.toString();
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refresh() async {
    _hasMore = true;
    _channels = [];
    await loadInitialData();
  }

  Future<void> setCategory(String? category) async {
    if (_selectedCategory == category) return;
    _selectedCategory = category;
    _channels = [];
    _hasMore = true;
    notifyListeners();
    await loadChannels();
  }

  Future<void> setSearchQuery(String query) async {
    _searchQuery = query.isEmpty ? null : query;
    _channels = [];
    _hasMore = true;
    notifyListeners();
    await loadChannels();
  }

  Future<void> toggleFollow(String channelId, bool follow) async {
    await _channelService.toggleFollowChannel(channelId, follow);

    _channels = _channels.map((c) {
      if (c.id == channelId) {
        return ChannelModel(
          id: c.id,
          name: c.name,
          description: c.description,
          imageUrl: c.imageUrl,
          logoUrl: c.logoUrl,
          category: c.category,
          host: c.host,
          followerCount: follow ? c.followerCount + 1 : c.followerCount - 1,
          isFollowed: follow,
          isLive: c.isLive,
          listenerCount: c.listenerCount,
          rating: c.rating,
          tags: c.tags,
          scheduleNote: c.scheduleNote,
          createdAt: c.createdAt,
          lastActive: c.lastActive,
        );
      }
      return c;
    }).toList();

    notifyListeners();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
