class Host {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String? bio;
  final String? photoUrl;
  final String radioId;
  final String status;
  final String? specialty;
  final int? experienceYears;
  final List<String> programIds;

  Host({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    this.bio,
    this.photoUrl,
    required this.radioId,
    this.status = 'active',
    this.specialty,
    this.experienceYears,
    this.programIds = const [],
  });

  factory Host.fromFirestore(Map<String, dynamic> d, String id) {
    return Host(
      id: id,
      name: (d['displayName'] ?? d['name'] ?? '').toString(),
      email: (d['email'] ?? '').toString(),
      phone: (d['phone'] ?? '').toString(),
      bio: d['bio']?.toString(),
      photoUrl: d['photoUrl']?.toString(),
      radioId: (d['radioId'] ?? '').toString(),
      status: (d['status'] ?? 'active').toString(),
      specialty: d['specialty']?.toString(),
      experienceYears: d['experienceYears'] as int?,
      programIds: List<String>.from(d['programIds'] ?? []),
    );
  }
}
