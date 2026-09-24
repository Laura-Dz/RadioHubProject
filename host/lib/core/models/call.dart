import 'package:cloud_firestore/cloud_firestore.dart';

class Call {
  final String id;
  final String sessionId;
  final String userId;
  final String userName;
  final String userPhone;
  final String topic;
  final bool isVoip;
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
    this.topic = '',
    this.isVoip = true,
    required this.status,
    required this.requestedAt,
    this.acceptedAt,
    this.heldAt,
    this.holdCount = 0,
  });

  factory Call.fromFirestore(Map<String, dynamic> d, String id) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate().toLocal();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
      if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt()).toLocal();
      if (val is String) return DateTime.tryParse(val)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullable(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate().toLocal();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
      if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt()).toLocal();
      if (val is String) return DateTime.tryParse(val)?.toLocal();
      return null;
    }

    final rawName = d['userName'] ?? d['name'] ?? d['displayName'];
    final name = (rawName != null && rawName.toString().trim().isNotEmpty)
        ? rawName.toString().trim()
        : 'Listener';

    return Call(
      id: id,
      sessionId: (d['sessionId'] ?? '').toString(),
      userId: (d['userId'] ?? '').toString(),
      userName: name,
      userPhone: (d['userPhone'] ?? (d['isVoip'] == true ? 'VOIP' : '')).toString(),
      topic: (d['topic'] ?? '').toString(),
      isVoip: d['isVoip'] == true || d['callType'] == 'voip',
      status: (d['status'] ?? 'pending').toString(),
      requestedAt: parseTime(d['requestedAt'] ?? d['timestamp']),
      acceptedAt: parseNullable(d['acceptedAt']),
      heldAt: parseNullable(d['heldAt']),
      holdCount: ((d['holdCount'] ?? 0) as num).toInt(),
    );
  }

  factory Call.fromMap(Map<String, dynamic> map, String id) =>
      Call.fromFirestore(map, id);

  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isHeld => status == 'held';
  bool get isEnded => status == 'ended' || status == 'declined' || status == 'dropped';
}
