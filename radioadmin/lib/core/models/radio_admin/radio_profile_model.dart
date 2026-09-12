import 'package:cloud_firestore/cloud_firestore.dart';

class RadioProfile {
  final String id;
  final String name;
  final String description;
  final String? function;
  final String? vision;
  final String? mission;
  final String? logoUrl;
  final String? bannerUrl;
  final String? contactEmail;
  final String? contactPhone;
  final String? website;
  final String? location;
  final List<String> socialLinks;
  final List<String> tags;
  final String? language;
  final DateTime? updatedAt;

  RadioProfile({
    required this.id,
    required this.name,
    required this.description,
    this.function,
    this.vision,
    this.mission,
    this.logoUrl,
    this.bannerUrl,
    this.contactEmail,
    this.contactPhone,
    this.website,
    this.location,
    this.socialLinks = const [],
    this.tags = const [],
    this.language,
    this.updatedAt,
  });

  factory RadioProfile.fromFirestore(Map<String, dynamic> d, String id) => RadioProfile(
    id: id,
    name: d['name'] ?? '',
    description: d['description'] ?? '',
    function: d['function'],
    vision: d['vision'],
    mission: d['mission'],
    logoUrl: d['logoUrl'],
    bannerUrl: d['bannerUrl'],
    contactEmail: d['contactEmail'],
    contactPhone: d['contactPhone'],
    website: d['website'],
    location: d['location'],
    socialLinks: List<String>.from(d['socialLinks'] ?? []),
    tags: List<String>.from(d['tags'] ?? []),
    language: d['language'],
    updatedAt: d['updatedAt'] is Timestamp ? (d['updatedAt'] as Timestamp).toDate() : null,
  );

  /// NOTE: livestreamUrl / broadcastLink intentionally NOT included. SysAdmin owns those.
  Map<String, dynamic> toFirestore() => {
    'name': name,
    'description': description,
    'function': function,
    'vision': vision,
    'mission': mission,
    'logoUrl': logoUrl,
    'bannerUrl': bannerUrl,
    'contactEmail': contactEmail,
    'contactPhone': contactPhone,
    'website': website,
    'location': location,
    'socialLinks': socialLinks,
    'tags': tags,
    'language': language,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  RadioProfile copyWith({
    String? name,
    String? description,
    String? function,
    String? vision,
    String? mission,
    String? logoUrl,
    String? bannerUrl,
    String? contactEmail,
    String? contactPhone,
    String? website,
    String? location,
    List<String>? socialLinks,
    List<String>? tags,
    String? language,
  }) => RadioProfile(
    id: id,
    name: name ?? this.name,
    description: description ?? this.description,
    function: function ?? this.function,
    vision: vision ?? this.vision,
    mission: mission ?? this.mission,
    logoUrl: logoUrl ?? this.logoUrl,
    bannerUrl: bannerUrl ?? this.bannerUrl,
    contactEmail: contactEmail ?? this.contactEmail,
    contactPhone: contactPhone ?? this.contactPhone,
    website: website ?? this.website,
    location: location ?? this.location,
    socialLinks: socialLinks ?? this.socialLinks,
    tags: tags ?? this.tags,
    language: language ?? this.language,
  );
}
