import 'package:cloud_firestore/cloud_firestore.dart';

class Program {
  final String id;
  final String name;
  final String description;
  final String? imageUrl;
  final String category;
  final List<String> hosts;
  final List<String> coHosts;
  final Duration defaultDuration;
  final Map<String, dynamic> metadata;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Program({
    required this.id,
    required this.name,
    required this.description,
    this.imageUrl,
    required this.category,
    required this.hosts,
    this.coHosts = const [],
    required this.defaultDuration,
    this.metadata = const {},
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Program.fromFirestore(Map<String, dynamic> data, String id) {
    return Program(
      id: id,
      name: data['name'] ?? 'Untitled Program',
      description: data['description'] ?? '',
      imageUrl: data['imageUrl'],
      category: data['category'] ?? 'general',
      hosts: List<String>.from(data['hosts'] ?? []),
      coHosts: List<String>.from(data['coHosts'] ?? []),
      defaultDuration: Duration(seconds: data['defaultDurationSeconds'] ?? 7200),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'category': category,
        'hosts': hosts,
        'coHosts': coHosts,
        'defaultDurationSeconds': defaultDuration.inSeconds,
        'metadata': metadata,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
