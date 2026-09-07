import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ChannelModel {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String? logoUrl;
  final String category;
  final String host;
  final int followerCount;
  final bool isFollowed;
  final bool isLive;
  final int listenerCount;
  final double rating;
  final List<String> tags;
  final String? scheduleNote;
  final DateTime? createdAt;
  final DateTime? lastActive;

  ChannelModel({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    this.logoUrl,
    required this.category,
    required this.host,
    this.followerCount = 0,
    this.isFollowed = false,
    this.isLive = false,
    this.listenerCount = 0,
    this.rating = 0.0,
    this.tags = const [],
    this.scheduleNote,
    this.createdAt,
    this.lastActive,
  });

  factory ChannelModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ChannelModel(
      id: id,
      name: data['name'] ?? 'Unnamed Channel',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      logoUrl: data['logoUrl'],
      category: data['category'] ?? 'general',
      host: data['host'] ?? 'Unknown',
      followerCount: data['followerCount'] ?? 0,
      isFollowed: data['isFollowed'] ?? false,
      isLive: data['isLive'] ?? false,
      listenerCount: data['listenerCount'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      tags: List<String>.from(data['tags'] ?? []),
      scheduleNote: data['scheduleNote'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate(),
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
    );
  }

  ChannelModel copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? logoUrl,
    String? category,
    String? host,
    int? followerCount,
    bool? isFollowed,
    bool? isLive,
    int? listenerCount,
    double? rating,
    List<String>? tags,
    String? scheduleNote,
    DateTime? createdAt,
    DateTime? lastActive,
  }) {
    return ChannelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      logoUrl: logoUrl ?? this.logoUrl,
      category: category ?? this.category,
      host: host ?? this.host,
      followerCount: followerCount ?? this.followerCount,
      isFollowed: isFollowed ?? this.isFollowed,
      isLive: isLive ?? this.isLive,
      listenerCount: listenerCount ?? this.listenerCount,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      scheduleNote: scheduleNote ?? this.scheduleNote,
      createdAt: createdAt ?? this.createdAt,
      lastActive: lastActive ?? this.lastActive,
    );
  }

  String get categoryLabel {
    final map = {
      'music': 'Music',
      'talk': 'Talk',
      'news': 'News',
      'sports': 'Sports',
      'comedy': 'Comedy',
      'education': 'Education',
      'entertainment': 'Entertainment',
      'religious': 'Religious',
      'general': 'General',
    };
    return map[category] ?? category;
  }

  IconData get categoryIcon {
    final map = {
      'music': Icons.music_note,
      'talk': Icons.mic,
      'news': Icons.newspaper,
      'sports': Icons.sports,
      'comedy': Icons.emoji_emotions,
      'education': Icons.school,
      'entertainment': Icons.movie,
      'religious': Icons.church,
      'general': Icons.radio,
    };
    return map[category] ?? Icons.radio;
  }

  Color get categoryColor {
    final map = {
      'music': Colors.blue,
      'talk': Colors.purple,
      'news': Colors.red,
      'sports': Colors.orange,
      'comedy': Colors.green,
      'education': Colors.teal,
      'entertainment': Colors.pink,
      'religious': Colors.indigo,
      'general': Colors.grey,
    };
    return map[category] ?? Colors.grey;
  }
}
