import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

enum StaffRole { host, technician }
enum StaffStatus { active, suspended, inactive }

class StaffMember {
  final String id;              // users/{uid} doc id
  final String? authUid;        // Firebase Auth uid (technicians only)
  final String name;
  final String email;
  final String phone;
  final String? bio;
  final String radioId;
  final String radioName;
  final StaffRole role;
  final StaffStatus status;
  final String? photoUrl;
  final DateTime? createdAt;
  final DateTime? suspendedAt;
  final String? suspendReason;
  final DateTime? lastActive;

  StaffMember({
    required this.id,
    this.authUid,
    required this.name,
    required this.email,
    required this.phone,
    this.bio,
    required this.radioId,
    required this.radioName,
    required this.role,
    this.status = StaffStatus.active,
    this.photoUrl,
    this.createdAt,
    this.suspendedAt,
    this.suspendReason,
    this.lastActive,
  });

  bool get isActive => status == StaffStatus.active;
  bool get isSuspended => status == StaffStatus.suspended;
  bool get hasAuthAccount => role == StaffRole.technician;

  factory StaffMember.fromFirestore(Map<String, dynamic> d, String id) {
    final roleStr = (d['role'] ?? 'host').toString().toLowerCase();
    final statusStr = (d['status'] ?? 'active').toString().toLowerCase();

    return StaffMember(
      id: id,
      authUid: d['authUid'] as String?,
      name: (d['displayName'] ?? d['name'] ?? '').toString(),
      email: (d['email'] ?? '').toString(),
      phone: (d['phone'] ?? '').toString(),
      bio: d['bio'] as String?,
      radioId: (d['radioId'] ?? '').toString(),
      radioName: (d['radioName'] ?? '').toString(),
      role: StaffRole.values.firstWhere(
        (e) => e.toString() == 'StaffRole.${d['role']}' || e.name.toLowerCase() == roleStr,
        orElse: () => StaffRole.host,
      ),
      status: StaffStatus.values.firstWhere(
        (e) => e.toString() == 'StaffStatus.${d['status']}' || e.name.toLowerCase() == statusStr,
        orElse: () => StaffStatus.active,
      ),
      photoUrl: d['photoUrl'] as String?,
      createdAt: FSParsers.toDate(d['createdAt']),
      suspendedAt: FSParsers.toDate(d['suspendedAt']),
      suspendReason: d['suspendReason'] as String?,
      lastActive: FSParsers.toDate(d['lastActive']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'authUid': authUid,
    'name': name,
    'displayName': name,
    'email': email,
    'phone': phone,
    'bio': bio,
    'radioId': radioId,
    'radioName': radioName,
    'role': role.name,
    'status': status.name,
    'photoUrl': photoUrl,
    'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
    'suspendedAt': suspendedAt != null ? Timestamp.fromDate(suspendedAt!) : null,
    'suspendReason': suspendReason,
    'lastActive': lastActive != null ? Timestamp.fromDate(lastActive!) : null,
  };
}
