import 'package:cloud_firestore/cloud_firestore.dart';

class RadioModel {
  final String id;
  final String name;
  final String description;
  final String? logoUrl;
  final String? bannerUrl;
  final List<String> categories;
  final String language;
  final List<String> targetAgeGroups;
  final List<String> hosts;
  final int followerCount;
  final bool isFollowed;
  final bool isLive;
  final int listenerCount;
  final double rating;
  final List<String> tags;
  final String? city;
  final bool isVerified;
  final DateTime? lastActive;
  final String? currentLiveSessionId;

  // Backward compatibility fields
  final DateTime? foundedDate;
  final String? website;
  final String? contactEmail;
  final String? phoneNumber;
  final Map<String, dynamic> settings;
  final List<String> socialLinks;
  final String legalStatus; // 'profit', 'nonProfit', 'stateOwned'

  RadioModel({
    required this.id,
    required this.name,
    required this.description,
    this.logoUrl,
    this.bannerUrl,
    this.categories = const [],
    this.language = 'en',
    this.targetAgeGroups = const [],
    this.hosts = const [],
    this.followerCount = 0,
    this.isFollowed = false,
    this.isLive = false,
    this.listenerCount = 0,
    this.rating = 0.0,
    this.tags = const [],
    this.city,
    this.isVerified = false,
    this.lastActive,
    this.currentLiveSessionId,
    this.foundedDate,
    this.website,
    this.contactEmail,
    this.phoneNumber,
    this.settings = const {},
    this.socialLinks = const [],
    this.legalStatus = 'profit',
  });

  bool get isNonProfit => legalStatus == 'nonProfit';

  // Backward compatibility getters
  String? get bannerImageUrl => bannerUrl;
  String? get coverImageUrl => (bannerUrl != null && bannerUrl!.trim().isNotEmpty) ? bannerUrl : logoUrl;
  String get location => city ?? '';
  String get category => primaryCategory;
  String get primaryCategory =>
      categories.isEmpty ? 'General' : categories.first;

  factory RadioModel.fromFirestore(Map<String, dynamic> d, String id) {
    return RadioModel(
      id: id,
      name: (d['name'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      logoUrl: d['logoUrl']?.toString() ?? d['logo']?.toString() ?? d['imageUrl']?.toString() ?? d['avatarUrl']?.toString(),
      bannerUrl: d['bannerUrl']?.toString() ?? d['bannerImageUrl']?.toString() ?? d['coverImageUrl']?.toString() ?? d['banner']?.toString(),
      categories: List<String>.from(d['categories'] ?? (d['category'] != null ? [d['category'].toString()] : [])),
      language: (d['language'] ?? 'en').toString(),
      targetAgeGroups: List<String>.from(d['targetAgeGroups'] ?? []),
      hosts: List<String>.from(d['hosts'] ?? []),
      followerCount: (d['followerCount'] ?? 0) as int,
      isFollowed: d['isFollowed'] == true,
      isLive: d['isLive'] == true,
      listenerCount: (d['listenerCount'] ?? 0) as int,
      rating: (d['rating'] ?? 0.0).toDouble(),
      tags: List<String>.from(d['tags'] ?? []),
      city: d['city']?.toString() ?? d['location']?.toString(),
      isVerified: d['isVerified'] == true,
      lastActive: (d['lastActive'] as Timestamp?)?.toDate().toLocal(),
      currentLiveSessionId: d['currentLiveSessionId']?.toString(),
      foundedDate: (d['foundedDate'] as Timestamp?)?.toDate(),
      website: d['website']?.toString(),
      contactEmail: d['contactEmail']?.toString(),
      phoneNumber: d['phoneNumber']?.toString(),
      settings: d['settings'] is Map<String, dynamic> ? d['settings'] : const {},
      socialLinks: List<String>.from(d['socialLinks'] ?? []),
      legalStatus: (d['legalStatus'] ?? 'profit').toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'description': description,
      'logoUrl': logoUrl,
      'bannerUrl': bannerUrl,
      'categories': categories,
      'language': language,
      'targetAgeGroups': targetAgeGroups,
      'hosts': hosts,
      'followerCount': followerCount,
      'isFollowed': isFollowed,
      'isLive': isLive,
      'listenerCount': listenerCount,
      'rating': rating,
      'tags': tags,
      'city': city,
      'isVerified': isVerified,
      'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : FieldValue.serverTimestamp(),
      'foundedDate': foundedDate != null ? Timestamp.fromDate(foundedDate!) : null,
      'website': website,
      'contactEmail': contactEmail,
      'phoneNumber': phoneNumber,
      'settings': settings,
      'socialLinks': socialLinks,
      'legalStatus': legalStatus,
    };
  }

  RadioModel copyWith({
    String? id,
    String? name,
    String? description,
    String? logoUrl,
    String? bannerUrl,
    List<String>? categories,
    String? language,
    List<String>? targetAgeGroups,
    List<String>? hosts,
    int? followerCount,
    bool? isFollowed,
    bool? isLive,
    int? listenerCount,
    double? rating,
    List<String>? tags,
    String? city,
    bool? isVerified,
    DateTime? lastActive,
    DateTime? foundedDate,
    String? website,
    String? contactEmail,
    String? phoneNumber,
    Map<String, dynamic>? settings,
    List<String>? socialLinks,
    String? legalStatus,
  }) {
    return RadioModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      categories: categories ?? this.categories,
      language: language ?? this.language,
      targetAgeGroups: targetAgeGroups ?? this.targetAgeGroups,
      hosts: hosts ?? this.hosts,
      followerCount: followerCount ?? this.followerCount,
      isFollowed: isFollowed ?? this.isFollowed,
      isLive: isLive ?? this.isLive,
      listenerCount: listenerCount ?? this.listenerCount,
      rating: rating ?? this.rating,
      tags: tags ?? this.tags,
      city: city ?? this.city,
      isVerified: isVerified ?? this.isVerified,
      lastActive: lastActive ?? this.lastActive,
      foundedDate: foundedDate ?? this.foundedDate,
      website: website ?? this.website,
      contactEmail: contactEmail ?? this.contactEmail,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      settings: settings ?? this.settings,
      socialLinks: socialLinks ?? this.socialLinks,
      legalStatus: legalStatus ?? this.legalStatus,
    );
  }
}
