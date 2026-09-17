import 'dart:async';
import 'package:flutter/foundation.dart';
import '../core/models/radio_model.dart';
import '../core/models/user_profile.dart';
import '../core/services/channels_service.dart';
import '../core/services/user_service.dart';

enum ChannelFilter { all, trending, forYou, following }

class ChannelsViewModel extends ChangeNotifier {
  final ChannelsService _service = ChannelsService();
  final UserService _userService = UserService();

  // Data
  List<RadioModel> _allRadios = [];
  List<RadioModel> _followedRadios = [];
  List<SearchEntry> _searchHistory = [];
  UserProfile? _user;

  // State
  bool _loading = true;
  ChannelFilter _filter = ChannelFilter.all;
  String _query = '';
  String? _category; // null = all categories
  final List<String> _recentQueries = [];

  StreamSubscription? _radiosSub;
  StreamSubscription? _followedSub;
  StreamSubscription? _historySub;
  StreamSubscription? _userSub;

  // Getters
  List<RadioModel> get allRadios => _allRadios;
  List<RadioModel> get followedRadios => _followedRadios;
  List<SearchEntry> get searchHistory => _searchHistory;
  List<String> get recentQueries => _recentQueries;
  UserProfile? get user => _user;
  bool get loading => _loading;
  ChannelFilter get filter => _filter;
  String get query => _query;
  String? get category => _category;

  bool get isSearching => _query.trim().isNotEmpty;

  /// All categories available across radios.
  List<String> get availableCategories {
    final set = <String>{};
    for (final r in _allRadios) {
      set.addAll(r.categories);
    }
    final list = set.toList()..sort();
    return list;
  }

  void attach(String uid) {
    detach();

    final cleanUid = uid.trim();
    _loading = true;
    notifyListeners();

    _radiosSub = _service.streamAllRadios(currentUserId: cleanUid).listen(
      (list) {
        _allRadios = list;
        _loading = false;
        notifyListeners();
      },
      onError: (e) {
        debugPrint('ChannelsViewModel streamAllRadios error: $e');
        _loading = false;
        notifyListeners();
      },
    );

    if (cleanUid.isNotEmpty) {
      _followedSub = _service.streamFollowed(cleanUid).listen(
        (list) {
          _followedRadios = list;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('ChannelsViewModel streamFollowed error: $e');
        },
      );

      _historySub = _service.streamSearchHistory(cleanUid).listen(
        (list) {
          _searchHistory = list;
          _recentQueries
            ..clear()
            ..addAll(list.map((e) => e.query));
          notifyListeners();
        },
        onError: (e) {
          debugPrint('ChannelsViewModel streamSearchHistory error: $e');
        },
      );

      _userSub = _userService.streamProfile(cleanUid).listen(
        (p) {
          _user = p;
          notifyListeners();
        },
        onError: (e) {
          debugPrint('ChannelsViewModel streamProfile error: $e');
        },
      );
    } else {
      _followedRadios = [];
      _searchHistory = [];
      _recentQueries.clear();
      _user = null;
    }
  }

  // ---------- ACTIONS ----------

  void setFilter(ChannelFilter f) {
    _filter = f;
    notifyListeners();
  }

  void setQuery(String q) {
    _query = q;
    notifyListeners();
  }

  void setCategory(String? c) {
    _category = c;
    notifyListeners();
  }

  Future<void> submitSearch(String uid, String q) async {
    final clean = q.trim();
    if (clean.isEmpty) return;
    await _service.addSearchQuery(uid, clean);
  }

  Future<void> removeHistoryEntry(String uid, String entryId) async {
    await _service.removeSearchEntry(uid, entryId);
  }

  Future<void> clearHistory(String uid) async {
    await _service.clearSearchHistory(uid);
  }

  Future<void> toggleFollow(String radioId, String uid, bool follow) async {
    final idx = _allRadios.indexWhere((r) => r.id == radioId);
    if (idx != -1) {
      final updated = _allRadios[idx].copyWith(
        isFollowed: follow,
        followerCount: (_allRadios[idx].followerCount + (follow ? 1 : -1)).clamp(0, 999999),
      );
      _allRadios[idx] = updated;
      if (follow) {
        if (!_followedRadios.any((r) => r.id == radioId)) {
          _followedRadios.add(updated);
        }
      } else {
        _followedRadios.removeWhere((r) => r.id == radioId);
      }
      notifyListeners();
    }

    await _service.toggleFollow(radioId, uid, follow);
  }

  // ---------- FILTERED RESULTS ----------

  /// Radios matching search + category filter, ignoring the tab filter.
  List<RadioModel> get _searchable {
    var list = _allRadios;

    if (_category != null) {
      list = list.where((r) => r.categories.contains(_category)).toList();
    }

    final q = _query.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((r) {
        return r.name.toLowerCase().contains(q) ||
            r.description.toLowerCase().contains(q) ||
            r.categories.any((c) => c.toLowerCase().contains(q)) ||
            r.tags.any((t) => t.toLowerCase().contains(q)) ||
            (r.city?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return list;
  }

  /// Radios for the current filter, sorted appropriately.
  List<RadioModel> get visibleRadios {
    final base = _searchable;

    switch (_filter) {
      case ChannelFilter.trending:
        return [...base]..sort((a, b) => b.listenerCount.compareTo(a.listenerCount));

      case ChannelFilter.following:
        return [...base]..sort((a, b) => b.listenerCount.compareTo(a.listenerCount))
          ..retainWhere((r) =>
              r.isFollowed || _followedRadios.any((f) => f.id == r.id));

      case ChannelFilter.forYou:
        final scored = base.map((r) => MapEntry(r, _personalScore(r))).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
        return scored.map((e) => e.key).toList();

      case ChannelFilter.all:
        // Trending-first, then alphabetical
        return [...base]..sort((a, b) {
          if (a.isLive != b.isLive) return a.isLive ? -1 : 1;
          return b.listenerCount.compareTo(a.listenerCount);
        });
    }
  }

  /// Top radios for the "Trending" carousel on the All view.
  List<RadioModel> get trendingRadios {
    final list = [..._searchable]
      ..sort((a, b) => b.listenerCount.compareTo(a.listenerCount));
    return list.take(6).toList();
  }

  /// Personalized radios for the "For You" carousel.
  List<RadioModel> get forYouRadios {
    final scored = _searchable.map((r) => MapEntry(r, _personalScore(r))).toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return scored
        .where((e) => e.value > 0)
        .map((e) => e.key)
        .take(6)
        .toList();
  }

  /// Radios the user follows, for the "Following" carousel.
  List<RadioModel> get followingRadios {
    if (_followedRadios.isNotEmpty) return _followedRadios;
    return _allRadios.where((r) => r.isFollowed).toList();
  }

  // ---------- PERSONALIZATION ----------

  /// Higher = more relevant to this user.
  double _personalScore(RadioModel r) {
    double score = 0;

    // Language match
    if (_user?.language == r.language) score += 4;

    // City / location match
    if (_user?.city != null &&
        _user!.city.isNotEmpty &&
        r.city != null &&
        r.city!.toLowerCase() == _user!.city.toLowerCase()) {
      score += 3;
    }

    // Age group match
    if (_user?.ageGroup != null && r.targetAgeGroups.contains(_user!.ageGroup)) {
      score += 2;
    }

    // Already followed — keep it near the top
    if (_followedRadios.any((f) => f.id == r.id)) score += 6;

    // Popularity nudge
    score += (r.listenerCount / 500).clamp(0, 5).toDouble();

    // Live bonus
    if (r.isLive) score += 1;

    return score;
  }

  /// Returns a short human-readable reason for why this radio is being shown,
  /// or null if there's nothing meaningful to say.
  String? reasonFor(RadioModel r, {required ChannelFilter context}) {
    // Following is explicit — no reason needed
    if (context == ChannelFilter.following) return null;

    final signals = <String>[];

    // Trending context: show listener activity
    if (context == ChannelFilter.trending) {
      if (r.listenerCount >= 1000) {
        signals.add('${_fmt(r.listenerCount)} listening');
      } else {
        signals.add('Trending today');
      }
    }

    // City match (Priority 1 for personalized contexts)
    if (_user?.city != null &&
        _user!.city.isNotEmpty &&
        r.city != null &&
        r.city!.toLowerCase() == _user!.city.toLowerCase()) {
      signals.add('In ${r.city}');
    }

    // Language match (Priority 2)
    if (_user?.language != null && _user!.language == r.language) {
      final langLabel = _user!.language == 'fr' ? 'French' : 'English';
      signals.add('In $langLabel');
    }

    // Age group match (Priority 3)
    if (_user?.ageGroup != null && r.targetAgeGroups.contains(_user!.ageGroup)) {
      signals.add('Popular in your age group');
    }

    // For You context fallback (Priority 5)
    if (context == ChannelFilter.forYou && signals.isEmpty) {
      if (r.followerCount >= 100) {
        signals.add('${_fmt(r.followerCount)} followers');
      } else {
        signals.add('Recommended for you');
      }
    }

    if (signals.isEmpty) return null;

    // Return the strongest one, not a wall of text
    return signals.first;
  }

  String _fmt(int n) {
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  // ---------- LIFECYCLE ----------

  void detach() {
    _radiosSub?.cancel();
    _followedSub?.cancel();
    _historySub?.cancel();
    _userSub?.cancel();
  }

  @override
  void dispose() {
    detach();
    super.dispose();
  }
}
