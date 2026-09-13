import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

class NotificationItem {
  final String id;
  final String radioId;
  final String recipientRole;   // 'technician' | 'radio_admin' | 'host' | 'listener'
  final String? recipientId;    // optional targeted
  final String type;            // 'session_started' | 'program_updated' | ...
  final String title;
  final String body;
  final Map<String, dynamic>? data;
  final bool isRead;
  final DateTime createdAt;

  NotificationItem({
    required this.id,
    required this.radioId,
    required this.recipientRole,
    this.recipientId,
    required this.type,
    required this.title,
    required this.body,
    this.data,
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationItem.fromFirestore(Map<String, dynamic> d, String id) =>
      NotificationItem(
        id: id,
        radioId: (d['radioId'] ?? '').toString(),
        recipientRole: (d['recipientRole'] ?? 'technician').toString(),
        recipientId: d['recipientId']?.toString(),
        type: (d['type'] ?? '').toString(),
        title: (d['title'] ?? '').toString(),
        body: (d['body'] ?? '').toString(),
        data: d['data'] as Map<String, dynamic>?,
        isRead: d['isRead'] == true,
        createdAt: FSParsers.toDate(d['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestore() => {
        'radioId': radioId,
        'recipientRole': recipientRole,
        'recipientId': recipientId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'isRead': isRead,
        'createdAt': FieldValue.serverTimestamp(),
      };
}
