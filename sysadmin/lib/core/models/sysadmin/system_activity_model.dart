import 'package:cloud_firestore/cloud_firestore.dart';

class SystemActivity {
  final String id;
  final String type;
  final String message;
  final String? radioId;
  final DateTime timestamp;
  final String? adminId;

  SystemActivity({
    required this.id,
    required this.type,
    required this.message,
    this.radioId,
    required this.timestamp,
    this.adminId,
  });

  factory SystemActivity.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    return SystemActivity(
      id: id,
      type: data['type'] ?? 'general',
      message: data['message'] ?? '',
      radioId: data['radioId'],
      timestamp: parseDate(data['timestamp']),
      adminId: data['adminId'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'type': type,
      'message': message,
      'radioId': radioId,
      'timestamp': Timestamp.fromDate(timestamp),
      'adminId': adminId,
    };
  }

  String get iconType {
    if (type.contains('radio')) return '📻';
    if (type.contains('user')) return '👤';
    if (type.contains('transaction') || type.contains('paid')) return '💰';
    if (type.contains('announce')) return '📝';
    if (type.contains('security')) return '🔐';
    if (type.contains('session')) return '🎙️';
    return '🟢';
  }
}

