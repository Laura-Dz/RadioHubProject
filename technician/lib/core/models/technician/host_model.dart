import '../../utils/firestore_parsers.dart';

class Host {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? bio;
  final String? photoUrl;
  final String radioId;
  final String status;
  final List<String> programIds;
  final DateTime? createdAt;
  final DateTime? lastActive;

  Host({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.bio,
    this.photoUrl,
    required this.radioId,
    this.status = 'active',
    this.programIds = const [],
    this.createdAt,
    this.lastActive,
  });

  factory Host.fromFirestore(Map<String, dynamic> d, String id) => Host(
        id: id,
        name: (d['displayName'] ?? d['name'] ?? '').toString(),
        email: (d['email'] ?? '').toString(),
        phone: (d['phone'] ?? '').toString(),
        bio: d['bio']?.toString(),
        photoUrl: d['photoUrl']?.toString(),
        radioId: (d['radioId'] ?? '').toString(),
        status: (d['status'] ?? 'active').toString(),
        programIds: List<String>.from(d['programIds'] ?? []),
        createdAt: FSParsers.toDate(d['createdAt']),
        lastActive: FSParsers.toDate(d['lastActive']),
      );
}
