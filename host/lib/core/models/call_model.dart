import 'package:cloud_firestore/cloud_firestore.dart';

enum CallStatus { waiting, accepted, declined, completed }

class Call {
  final String id;
  final String programId;
  final String listenerId;
  final String listenerName;
  final String? phoneNumber;
  final String? topic;
  final CallStatus status;
  final DateTime timestamp;
  final DateTime? acceptedAt;
  final DateTime? declinedAt;

  Call({
    required this.id,
    required this.programId,
    required this.listenerId,
    required this.listenerName,
    this.phoneNumber,
    this.topic,
    this.status = CallStatus.waiting,
    required this.timestamp,
    this.acceptedAt,
    this.declinedAt,
  });

  factory Call.fromFirestore(Map<String, dynamic> data, String id) {
    CallStatus parsed;
    final statusStr = data['status'] as String? ?? 'waiting';
    switch (statusStr) {
      case 'accepted':
        parsed = CallStatus.accepted;
        break;
      case 'declined':
        parsed = CallStatus.declined;
        break;
      case 'completed':
        parsed = CallStatus.completed;
        break;
      default:
        parsed = CallStatus.waiting;
    }

    return Call(
      id: id,
      programId: data['programId'] ?? '',
      listenerId: data['listenerId'] ?? data['userId'] ?? '',
      listenerName: data['listenerName'] ?? data['userName'] ?? 'Caller',
      phoneNumber: data['phoneNumber'],
      topic: data['topic'],
      status: parsed,
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (data['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
            ),
      acceptedAt: data['acceptedAt'] != null
          ? (data['acceptedAt'] as Timestamp).toDate()
          : null,
      declinedAt: data['declinedAt'] != null
          ? (data['declinedAt'] as Timestamp).toDate()
          : null,
    );
  }
}
