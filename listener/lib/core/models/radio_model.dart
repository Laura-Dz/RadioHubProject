import 'package:cloud_firestore/cloud_firestore.dart';

class RadioModel {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String? coverImageUrl;
  final String? bannerImageUrl;
  final String category;
  final List<String> hosts;
  final int followerCount;
  bool isFollowed;
  bool isLive;
  final int listenerCount;
  final double rating;
  final List<String> tags;
  final String? location;
  final DateTime? foundedDate;
  final String? website;
  final String? contactEmail;
  final String? phoneNumber;
  final Map<String, dynamic> settings;
  final List<String> socialLinks;
  final bool isVerified;
  final DateTime? lastActive;

  RadioModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.coverImageUrl,
    this.bannerImageUrl,
    required this.category,
    required this.hosts,
    this.followerCount = 0,
    this.isFollowed = false,
    this.isLive = false,
    this.listenerCount = 0,
    this.rating = 0.0,
    this.tags = const [],
    this.location,
    this.foundedDate,
    this.website,
    this.contactEmail,
    this.phoneNumber,
    this.settings = const {},
    this.socialLinks = const [],
    this.isVerified = false,
    this.lastActive,
  });

  factory RadioModel.fromFirestore(Map<String, dynamic> data, String id) {
    return RadioModel(
      id: id,
      name: data['name'] ?? 'Unnamed Radio',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      coverImageUrl: data['coverImageUrl'],
      bannerImageUrl: data['bannerImageUrl'],
      category: data['category'] ?? 'general',
      hosts: List<String>.from(data['hosts'] ?? []),
      followerCount: data['followerCount'] ?? 0,
      isFollowed: data['isFollowed'] ?? false,
      isLive: data['isLive'] ?? false,
      listenerCount: data['listenerCount'] ?? 0,
      rating: (data['rating'] ?? 0.0).toDouble(),
      tags: List<String>.from(data['tags'] ?? []),
      location: data['location'],
      foundedDate: (data['foundedDate'] as Timestamp?)?.toDate(),
      website: data['website'],
      contactEmail: data['contactEmail'],
      phoneNumber: data['phoneNumber'],
      settings: data['settings'] ?? {},
      socialLinks: List<String>.from(data['socialLinks'] ?? []),
      isVerified: data['isVerified'] ?? false,
      lastActive: (data['lastActive'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'coverImageUrl': coverImageUrl,
      'bannerImageUrl': bannerImageUrl,
      'category': category,
      'hosts': hosts,
      'followerCount': followerCount,
      'isFollowed': isFollowed,
      'isLive': isLive,
      'listenerCount': listenerCount,
      'rating': rating,
      'tags': tags,
      'location': location,
      'foundedDate': foundedDate,
      'website': website,
      'contactEmail': contactEmail,
      'phoneNumber': phoneNumber,
      'settings': settings,
      'socialLinks': socialLinks,
      'isVerified': isVerified,
      'lastActive': FieldValue.serverTimestamp(),
    };
  }

  RadioModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? coverImageUrl,
    String? bannerImageUrl,
    String? category,
    List<String>? hosts,
    int? followerCount,
    bool? isFollowed,
    bool? isLive,
    int? listenerCount,
    double? rating,
    List<String>? tags,
    String? location,
    DateTime? foundedDate,
    String? website,
    String? contactEmail,
    String? phoneNumber,
    Map<String, dynamic>? settings,
    List<String>? socialLinks,
    bool? isVerified,
    DateTime? lastActive,
  }) {
    return RadioModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      coverImageUrl: coverImageUrl ?? this.coverImageUrl,
      bannerImageUrl: bannerImageUrl ?? this.bannerImageUrl,
      category: category ?? this.category,
      hosts: hosts ?? this.hosts,
      followerCount: followerCount ?? this.followerCount,
      isFollowed: isFollowed ?? this.isFollowed,
      isLive: isLive ?? this.isLive,
      listenerCount: listenerCount ?? this.listenerCount,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      location: location ?? this.location,
      foundedDate: foundedDate ?? this.foundedDate,
      website: website ?? this.website,
      contactEmail: contactEmail ?? this.contactEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      settings: settings ?? this.settings,
      socialLinks: socialLinks ?? this.socialLinks,
      isVerified: isVerified ?? this.isVerified,
      lastActive: lastActive ?? this.lastActive,
    );
  }
}
