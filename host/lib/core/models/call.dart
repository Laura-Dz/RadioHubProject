import 'package:cloud_firestore/cloud_firestore.dart';

class Call {
  final String id;
  final String sessionId;
  final String userId;
  final String userName;
  final String userPhone;
  final String status; // pending | accepted | held | declined | ended | dropped
  final DateTime requestedAt;
  final DateTime? acceptedAt;
  final DateTime? heldAt;
  final int holdCount;

  Call({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.userName,
    required this.userPhone,
    required this.status,
    required this.requestedAt,
    this.acceptedAt,
    this.heldAt,
    this.holdCount = 0,
  });

  factory Call.fromFirestore(Map<String, dynamic> d, String id) {
    return Call(
      id: id,
      sessionId: (d['sessionId'] ?? '').toString(),
      userId: (d['userId'] ?? '').toString(),
      userName: (d['userName'] ?? 'Listener').toString(),
      userPhone: (d['userPhone'] ?? '').toString(),
      status: (d['status'] ?? 'pending').toString(),
      requestedAt: (d['requestedAt'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
      acceptedAt: (d['acceptedAt'] as Timestamp?)?.toDate().toLocal(),
      heldAt: (d['heldAt'] as Timestamp?)?.toDate().toLocal(),
      holdCount: (d['holdCount'] ?? 0) as int,
    );
  }

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isHeld => status == 'held';
}
