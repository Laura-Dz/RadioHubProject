import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String programId;
  final String listenerId;
  final String listenerName;
  final String text;
  final DateTime timestamp;
  final String? hostReply;
  final DateTime? repliedAt;
  final bool isReplied;

  Comment({
    required this.id,
    required this.programId,
    required this.listenerId,
    required this.listenerName,
    required this.text,
    required this.timestamp,
    this.hostReply,
    this.repliedAt,
    this.isReplied = false,
  });

  factory Comment.fromFirestore(Map<String, dynamic> data, String id) {
    return Comment(
      id: id,
      programId: data['programId'] ?? '',
      listenerId: data['listenerId'] ?? data['userId'] ?? '',
      listenerName: data['listenerName'] ?? data['userName'] ?? 'Listener',
      text: data['text'] ?? data['message'] ?? '',
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : DateTime.fromMillisecondsSinceEpoch(
              (data['timestamp'] as num?)?.toInt() ?? 0,
            ),
      hostReply: data['hostReply'],
      repliedAt: data['repliedAt'] != null
          ? (data['repliedAt'] is Timestamp
              ? (data['repliedAt'] as Timestamp).toDate()
              : DateTime.fromMillisecondsSinceEpoch(
                  (data['repliedAt'] as num?)?.toInt() ?? 0,
                ))
          : null,
      isReplied: data['isReplied'] ?? data['hostReply'] != null,
    );
  }
}
