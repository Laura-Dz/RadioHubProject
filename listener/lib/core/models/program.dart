import 'package:cloud_firestore/cloud_firestore.dart';

class Program {
  final String id;
  final String radioId;
  final String name;
  final String description;
  final List<String> categories;
  final List<String> hostIds;
  final List<String> hostNames;
  final String? imageUrl;
  final int defaultDurationMinutes;
  final bool allowsCalls;
  final bool allowsComments;
  final bool isActive;
  final DateTime createdAt;

  Program({
    required this.id,
    required this.radioId,
    required this.name,
    required this.description,
    this.categories = const [],
    this.hostIds = const [],
    this.hostNames = const [],
    this.imageUrl,
    this.defaultDurationMinutes = 60,
    this.allowsCalls = true,
    this.allowsComments = true,
    this.isActive = true,
    required this.createdAt,
  });

  factory Program.fromFirestore(Map<String, dynamic> d, String id) {
    List<String> parsedCategories = [];
    if (d['categories'] is List) {
      parsedCategories = List<String>.from(d['categories']);
    } else if (d['category'] != null && d['category'].toString().isNotEmpty) {
      parsedCategories = [d['category'].toString()];
    }

    DateTime created = DateTime.now();
    if (d['createdAt'] is Timestamp) {
      created = (d['createdAt'] as Timestamp).toDate();
    }

    return Program(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      name: (d['name'] ?? d['title'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      categories: parsedCategories,
      hostIds: List<String>.from(d['hostIds'] ?? []),
      hostNames: List<String>.from(d['hostNames'] ?? []),
      imageUrl: d['imageUrl']?.toString(),
      defaultDurationMinutes: (d['defaultDurationMinutes'] ?? 60) as int,
      allowsCalls: d['allowsCalls'] != false,
      allowsComments: d['allowsComments'] != false,
      isActive: d['isActive'] != false,
      createdAt: created,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'name': name,
    'description': description,
    'categories': categories,
    'hostIds': hostIds,
    'hostNames': hostNames,
    'imageUrl': imageUrl,
    'defaultDurationMinutes': defaultDurationMinutes,
    'allowsCalls': allowsCalls,
    'allowsComments': allowsComments,
    'isActive': isActive,
    'createdAt': Timestamp.fromDate(createdAt),
  };
}
