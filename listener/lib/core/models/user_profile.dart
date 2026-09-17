import 'package:cloud_firestore/cloud_firestore.dart';

class UserProfile {
  final String id;
  final String email;
  final String displayName;
  final String? phone;
  final String? photoUrl;
  final String? bio;
  final String language;
  final String city;
  final String? ageGroup;   // 18_24 | 25_34 | 35_44 | 45_54 | 55_plus
  final String? gender;
  final DateTime createdAt;
  final DateTime? lastActive;

  UserProfile({
    required this.id,
    required this.email,
    required this.displayName,
    this.phone,
    this.photoUrl,
    this.bio,
    this.language = 'en',
    this.city = '',
    this.ageGroup,
    this.gender,
    required this.createdAt,
    this.lastActive,
  });

  factory UserProfile.fromFirestore(Map<String, dynamic> d, String id) {
    final rawName = d['displayName'] ?? d['name'] ?? d['fullName'] ?? d['username'];
    final nameStr = (rawName != null && rawName.toString().trim().isNotEmpty)
        ? rawName.toString().trim()
        : 'Listener';
    return UserProfile(
      id: id,
      email: (d['email'] ?? '').toString(),
      displayName: nameStr,
      phone: (d['phone'] ?? d['phoneNumber'])?.toString(),
      photoUrl: (d['photoUrl'] ?? d['photoURL'] ?? d['avatarUrl'])?.toString(),
      bio: d['bio']?.toString(),
      language: (d['language'] ?? 'en').toString(),
      city: (d['city'] ?? '').toString(),
      ageGroup: d['ageGroup']?.toString(),
      gender: d['gender']?.toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
      lastActive: (d['lastActive'] as Timestamp?)?.toDate().toLocal(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'email': email,
        'displayName': displayName,
        'phone': phone,
        'photoUrl': photoUrl,
        'bio': bio,
        'language': language,
        'city': city,
        'ageGroup': ageGroup,
        'gender': gender,
        'lastActive': FieldValue.serverTimestamp(),
      };

  UserProfile copyWith({
    String? displayName,
    String? phone,
    String? photoUrl,
    String? bio,
    String? language,
    String? city,
    String? ageGroup,
    String? gender,
  }) =>
      UserProfile(
        id: id,
        email: email,
        displayName: displayName ?? this.displayName,
        phone: phone ?? this.phone,
        photoUrl: photoUrl ?? this.photoUrl,
        bio: bio ?? this.bio,
        language: language ?? this.language,
        city: city ?? this.city,
        ageGroup: ageGroup ?? this.ageGroup,
        gender: gender ?? this.gender,
        createdAt: createdAt,
        lastActive: lastActive,
      );
}
