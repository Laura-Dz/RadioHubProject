import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? phoneNumber;
  final String role;
  final String? subscription;
  final Map<String, dynamic> preferences;
  final DateTime createdAt;
  final DateTime? lastLogin;
  final bool isGuest;
  final bool isVerified;

  UserModel({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.phoneNumber,
    this.role = 'listener',
    this.subscription,
    this.preferences = const {},
    required this.createdAt,
    this.lastLogin,
    this.isGuest = false,
    this.isVerified = false,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String id) {
    final rawName = data['displayName'] ?? data['name'] ?? data['fullName'] ?? data['username'];
    return UserModel(
      id: id,
      email: data['email'] ?? '',
      displayName: rawName?.toString().trim(),
      photoUrl: data['photoUrl'] ?? data['photoURL'] ?? data['avatarUrl'],
      phoneNumber: data['phoneNumber'],
      role: data['role'] ?? 'listener',
      subscription: data['subscription'],
      preferences: data['preferences'] ?? {},
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (data['lastLogin'] as Timestamp?)?.toDate(),
      isGuest: data['isGuest'] ?? false,
      isVerified: data['isVerified'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'displayName': displayName,
    'phoneNumber': phoneNumber,
    'role': role,
    'subscription': subscription,
    'preferences': preferences,
    'lastLogin': FieldValue.serverTimestamp(),
    'isVerified': isVerified,
  };
}
