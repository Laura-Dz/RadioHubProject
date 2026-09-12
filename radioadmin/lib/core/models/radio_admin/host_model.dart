import 'package:cloud_firestore/cloud_firestore.dart';

class Host {
  final String id;
  final String radioId;
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final String? photoUrl;
  final bool isActive;
  final List<String> programIds;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Host({
    required this.id,
    required this.radioId,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.photoUrl,
    this.isActive = true,
    this.programIds = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory Host.fromFirestore(Map<String, dynamic> data, String id) {
    return Host(
      id: id,
      radioId: data['radioId'] ?? '',
      name: data['name'] ?? 'Unknown Host',
      email: data['email'] ?? '',
      phone: data['phone'],
      bio: data['bio'],
      photoUrl: data['photoUrl'],
      isActive: data['isActive'] ?? true,
      programIds: List<String>.from(data['programIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'name': name,
    'email': email,
    'phone': phone,
    'bio': bio,
    'photoUrl': photoUrl,
    'isActive': isActive,
    'programIds': programIds,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };
}