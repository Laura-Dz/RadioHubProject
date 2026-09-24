import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum ProgramCategory {
  music,
  talk,
  news,
  sports,
  comedy,
  education,
  entertainment,
  religious,
}

extension ProgramCategoryExtension on ProgramCategory {
  String get label {
    switch (this) {
      case ProgramCategory.music:
        return 'Music';
      case ProgramCategory.talk:
        return 'Talk';
      case ProgramCategory.news:
        return 'News';
      case ProgramCategory.sports:
        return 'Sports';
      case ProgramCategory.comedy:
        return 'Comedy';
      case ProgramCategory.education:
        return 'Education';
      case ProgramCategory.entertainment:
        return 'Entertainment';
      case ProgramCategory.religious:
        return 'Religious';
    }
  }

  String get icon {
    switch (this) {
      case ProgramCategory.music:
        return '🎵';
      case ProgramCategory.talk:
        return '💬';
      case ProgramCategory.news:
        return '📰';
      case ProgramCategory.sports:
        return '⚽';
      case ProgramCategory.comedy:
        return '😂';
      case ProgramCategory.education:
        return '🎓';
      case ProgramCategory.entertainment:
        return '🎭';
      case ProgramCategory.religious:
        return '⛪';
    }
  }

  IconData get iconData {
    switch (this) {
      case ProgramCategory.music:
        return Icons.music_note;
      case ProgramCategory.talk:
        return Icons.mic;
      case ProgramCategory.news:
        return Icons.newspaper;
      case ProgramCategory.sports:
        return Icons.sports;
      case ProgramCategory.comedy:
        return Icons.emoji_emotions;
      case ProgramCategory.education:
        return Icons.school;
      case ProgramCategory.entertainment:
        return Icons.movie;
      case ProgramCategory.religious:
        return Icons.church;
    }
  }

  Color get iconColor {
    switch (this) {
      case ProgramCategory.music:
        return Colors.purple;
      case ProgramCategory.talk:
        return Colors.blue;
      case ProgramCategory.news:
        return Colors.red;
      case ProgramCategory.sports:
        return Colors.orange;
      case ProgramCategory.comedy:
        return Colors.green;
      case ProgramCategory.education:
        return Colors.teal;
      case ProgramCategory.entertainment:
        return Colors.pink;
      case ProgramCategory.religious:
        return Colors.indigo;
    }
  }
}

class Program {
  final String id;
  final String radioId;
  final String name;
  final String description;
  final ProgramCategory category;
  final List<String> categories;
  final Duration duration;
  final int defaultDurationMinutes;
  final bool isActive;
  final String? imageUrl;
  final List<String> hostIds;
  final List<String> hostNames;
  final List<String> coHostIds;
  final bool allowsCalls;
  final bool allowsComments;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Program({
    required this.id,
    required this.radioId,
    required this.name,
    required this.description,
    ProgramCategory? category,
    List<String>? categories,
    Duration? duration,
    int? defaultDurationMinutes,
    this.isActive = true,
    this.imageUrl,
    this.hostIds = const [],
    this.hostNames = const [],
    this.coHostIds = const [],
    this.allowsCalls = true,
    this.allowsComments = true,
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  })  : defaultDurationMinutes = defaultDurationMinutes ?? (duration != null ? duration.inMinutes : 60),
        duration = duration ?? Duration(minutes: defaultDurationMinutes ?? 60),
        categories = categories ?? (category != null ? [category.name] : const ['general']),
        category = category ??
            (categories != null && categories.isNotEmpty
                ? ProgramCategory.values.firstWhere(
                    (e) => e.name.toLowerCase() == categories.first.toLowerCase(),
                    orElse: () => ProgramCategory.music,
                  )
                : ProgramCategory.music);

  factory Program.fromFirestore(Map<String, dynamic> data, String id) {
    List<String> parsedCategories = [];
    if (data['categories'] is List) {
      parsedCategories = List<String>.from(data['categories']);
    } else if (data['category'] != null && data['category'].toString().isNotEmpty) {
      parsedCategories = [data['category'].toString()];
    }

    final durationMins = data['defaultDurationMinutes'] ??
        (data['durationSeconds'] != null ? (data['durationSeconds'] as int) ~/ 60 : 60);

    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return Program(
      id: id,
      radioId: (data['radioId'] ?? '').toString(),
      name: (data['name'] ?? 'Untitled Program').toString(),
      description: (data['description'] ?? '').toString(),
      categories: parsedCategories.isNotEmpty ? parsedCategories : ['general'],
      category: ProgramCategory.values.firstWhere(
        (e) =>
            e.name.toLowerCase() ==
            (parsedCategories.isNotEmpty ? parsedCategories.first.toLowerCase() : (data['category'] ?? '').toString().toLowerCase()),
        orElse: () => ProgramCategory.music,
      ),
      defaultDurationMinutes: durationMins,
      duration: Duration(minutes: durationMins),
      isActive: data['isActive'] ?? true,
      imageUrl: data['imageUrl']?.toString(),
      hostIds: List<String>.from(data['hostIds'] ?? []),
      hostNames: List<String>.from(data['hostNames'] ?? []),
      coHostIds: List<String>.from(data['coHostIds'] ?? []),
      allowsCalls: data['allowsCalls'] ?? true,
      allowsComments: data['allowsComments'] ?? true,
      metadata: data['metadata'] is Map ? Map<String, dynamic>.from(data['metadata']) : {},
      createdAt: parseDate(data['createdAt']),
      updatedAt: data['updatedAt'] != null ? parseDate(data['updatedAt']) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'name': name,
    'description': description,
    'category': category.name,
    'categories': categories,
    'defaultDurationMinutes': defaultDurationMinutes,
    'durationSeconds': duration.inSeconds,
    'isActive': isActive,
    'imageUrl': imageUrl,
    'hostIds': hostIds,
    'hostNames': hostNames,
    'coHostIds': coHostIds,
    'allowsCalls': allowsCalls,
    'allowsComments': allowsComments,
    'metadata': metadata,
    'createdAt': Timestamp.fromDate(createdAt),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}