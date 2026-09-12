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
  final Duration duration;
  final bool isActive;
  final List<String> hostIds;
  final List<String> coHostIds;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Program({
    required this.id,
    required this.radioId,
    required this.name,
    required this.description,
    required this.category,
    required this.duration,
    this.isActive = true,
    this.hostIds = const [],
    this.coHostIds = const [],
    this.metadata = const {},
    required this.createdAt,
    this.updatedAt,
  });

  factory Program.fromFirestore(Map<String, dynamic> data, String id) {
    return Program(
      id: id,
      radioId: data['radioId'] ?? '',
      name: data['name'] ?? 'Untitled Program',
      description: data['description'] ?? '',
      category: ProgramCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => ProgramCategory.music,
      ),
      duration: Duration(seconds: data['durationSeconds'] ?? 7200),
      isActive: data['isActive'] ?? true,
      hostIds: List<String>.from(data['hostIds'] ?? []),
      coHostIds: List<String>.from(data['coHostIds'] ?? []),
      metadata: data['metadata'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'name': name,
    'description': description,
    'category': category.toString().split('.').last,
    'durationSeconds': duration.inSeconds,
    'isActive': isActive,
    'hostIds': hostIds,
    'coHostIds': coHostIds,
    'metadata': metadata,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}