import 'package:cloud_firestore/cloud_firestore.dart';

class Comment {
  final String id;
  final String sessionId;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final String status; // pending | replying | replied | hidden
  final String? hostReply;
  final DateTime? hostReplyAt;
  final DateTime? replyingSince;
  final bool pinned;

  Comment({
    required this.id,
    required this.sessionId,
    required this.userId,
    required this.userName,
    required this.text,
    required this.createdAt,
    required this.status,
    this.hostReply,
    this.hostReplyAt,
    this.replyingSince,
    this.pinned = false,
  });

  factory Comment.fromFirestore(Map<String, dynamic> d, String id) {
    return Comment(
      id: id,
      sessionId: (d['sessionId'] ?? '').toString(),
      userId: (d['userId'] ?? '').toString(),
      userName: (d['userName'] ?? 'Listener').toString(),
      text: (d['text'] ?? '').toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
      status: (d['status'] ?? 'pending').toString(),
      hostReply: d['hostReply']?.toString(),
      hostReplyAt: (d['hostReplyAt'] as Timestamp?)?.toDate().toLocal(),
      replyingSince: (d['replyingSince'] as Timestamp?)?.toDate().toLocal(),
      pinned: d['pinned'] == true,
    );
  }

  bool get isReplying => status == 'replying';
  bool get isReplied => status == 'replied';
}
