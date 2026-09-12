import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ShowModel {
  final String id;
  final String title;
  final String host;
  final String? imageUrl;
  final ShowCategory category;
  final ShowStatus status;
  final DateTime? startTime;
  final DateTime? endTime;
  final int listenerCount;
  final int? episodeCount;
  final double rating;
  final bool isFollowed;
  final int? followerCount;
  final List<String> tags;
  final String? description;
  final bool isRediffusion;
  final bool allowCalls;

  ShowModel({
    required this.id,
    required this.title,
    required this.host,
    this.imageUrl,
    required this.category,
    required this.status,
    this.startTime,
    this.endTime,
    required this.listenerCount,
    this.episodeCount,
    required this.rating,
    required this.isFollowed,
    this.followerCount,
    this.tags = const [],
    this.description,
    this.isRediffusion = false,
    this.allowCalls = true,
  });

  String? get timeRemaining {
    if (startTime == null) return null;
    final now = DateTime.now();
    final difference = startTime!.difference(now);
    if (difference.isNegative) return null;

    final days = difference.inDays;
    final hours = difference.inHours.remainder(24);
    final minutes = difference.inMinutes.remainder(60);

    if (days > 0) return '$days d $hours h';
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  bool get isLive => status == ShowStatus.live;
  bool get isUpcoming => status == ShowStatus.upcoming;
  bool get isTrending => listenerCount > 1000;

  String get displayTag {
    if (isRediffusion) return 'REDIFFUSION';
    switch (status) {
      case ShowStatus.live:
        return 'LIVE';
      case ShowStatus.upcoming:
        return 'UPCOMING';
      case ShowStatus.ended:
        return 'ENDED';
      case ShowStatus.recorded:
        return 'ENDED';
    }
  }

  factory ShowModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ShowModel(
      id: id,
      title: data['title'] ?? 'Untitled Show',
      host: data['host'] ?? 'Unknown Host',
      imageUrl: data['imageUrl'],
      category: ShowCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => ShowCategory.music,
      ),
      status: ShowStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => ShowStatus.upcoming,
      ),
      startTime: (data['startTime'] as Timestamp?)?.toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      listenerCount: data['listenerCount'] ?? 0,
      episodeCount: data['episodeCount'],
      rating: (data['rating'] ?? 0.0).toDouble(),
      isFollowed: data['isFollowed'] ?? false,
      followerCount: data['followerCount'],
      tags: List<String>.from(data['tags'] ?? []),
      description: data['description'],
      isRediffusion: data['isRediffusion'] == true || data['status'] == 'rediffusion',
      allowCalls: data['allowCalls'] != false,
    );
  }
}

enum ShowCategory { music, talk, news, sports, comedy, education, entertainment, religious }

enum ShowStatus { live, upcoming, ended, recorded }

extension ShowCategoryExtension on ShowCategory {
  String get label {
    switch (this) {
      case ShowCategory.music:
        return 'Music';
      case ShowCategory.talk:
        return 'Talk';
      case ShowCategory.news:
        return 'News';
      case ShowCategory.sports:
        return 'Sports';
      case ShowCategory.comedy:
        return 'Comedy';
      case ShowCategory.education:
        return 'Education';
      case ShowCategory.entertainment:
        return 'Entertainment';
      case ShowCategory.religious:
        return 'Religious';
    }
  }

  IconData get icon {
    switch (this) {
      case ShowCategory.music:
        return Icons.music_note;
      case ShowCategory.talk:
        return Icons.mic;
      case ShowCategory.news:
        return Icons.newspaper;
      case ShowCategory.sports:
        return Icons.sports;
      case ShowCategory.comedy:
        return Icons.emoji_emotions;
      case ShowCategory.education:
        return Icons.school;
      case ShowCategory.entertainment:
        return Icons.movie;
      case ShowCategory.religious:
        return Icons.church;
    }
  }
}
