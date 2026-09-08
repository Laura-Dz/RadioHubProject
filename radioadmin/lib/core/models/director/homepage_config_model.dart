import 'package:cloud_firestore/cloud_firestore.dart';

class HomepageSection {
  final String id;
  final String type;
  final String title;
  final String? subtitle;
  final bool isVisible;
  final int displayOrder;
  final Map<String, dynamic> config;

  HomepageSection({
    required this.id,
    required this.type,
    required this.title,
    this.subtitle,
    this.isVisible = true,
    this.displayOrder = 0,
    this.config = const {},
  });

  factory HomepageSection.fromFirestore(Map<String, dynamic> data, String id) {
    return HomepageSection(
      id: id,
      type: data['type'] ?? 'featured',
      title: data['title'] ?? 'Untitled Section',
      subtitle: data['subtitle'],
      isVisible: data['isVisible'] ?? true,
      displayOrder: data['displayOrder'] ?? 0,
      config: data['config'] ?? {},
    );
  }

  Map<String, dynamic> toFirestore() => {
    'type': type,
    'title': title,
    'subtitle': subtitle,
    'isVisible': isVisible,
    'displayOrder': displayOrder,
    'config': config,
  };
}

class HomepageConfig {
  final String id;
  final String radioId;
  final List<HomepageSection> sections;
  final Map<String, dynamic> theme;
  final String? bannerImageUrl;
  final String? logoUrl;
  final bool isActive;
  final DateTime updatedAt;

  HomepageConfig({
    required this.id,
    required this.radioId,
    this.sections = const [],
    this.theme = const {},
    this.bannerImageUrl,
    this.logoUrl,
    this.isActive = true,
    required this.updatedAt,
  });

  factory HomepageConfig.fromFirestore(Map<String, dynamic> data, String id) {
    final sectionsData = data['sections'] as List? ?? [];
    return HomepageConfig(
      id: id,
      radioId: data['radioId'] ?? '',
      sections: sectionsData
          .map((s) => HomepageSection.fromFirestore(s, s['id'] ?? ''))
          .toList()
        ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder)),
      theme: data['theme'] ?? {},
      bannerImageUrl: data['bannerImageUrl'],
      logoUrl: data['logoUrl'],
      isActive: data['isActive'] ?? true,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'sections': sections.map((s) => s.toFirestore()).toList(),
    'theme': theme,
    'bannerImageUrl': bannerImageUrl,
    'logoUrl': logoUrl,
    'isActive': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
