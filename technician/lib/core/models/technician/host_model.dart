import 'package:cloud_firestore/cloud_firestore.dart';

class Host {
  final String id;
  final String name;
  final String email;
  final String? phone;
  final String? bio;
  final String? photoUrl;
  final List<String> programIds;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Host({
    required this.id,
    required this.name,
    required this.email,
    this.phone,
    this.bio,
    this.photoUrl,
    this.programIds = const [],
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Host.fromFirestore(Map<String, dynamic> data, String id) {
    return Host(
      id: id,
      name: data['name'] ?? 'Unknown Host',
      email: data['email'] ?? '',
      phone: data['phone'],
      bio: data['bio'],
      photoUrl: data['photoUrl'],
      programIds: List<String>.from(data['programIds'] ?? []),
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
        'email': email,
        'phone': phone,
        'bio': bio,
        'photoUrl': photoUrl,
        'programIds': programIds,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };
}
