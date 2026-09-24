import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

class TechnicianAnnouncementSlot {
  final DateTime startTime;
  final int durationSeconds;
  final String slotType; // 'between' | 'within'
  final String? showId;
  final String? showName;

  TechnicianAnnouncementSlot({
    required this.startTime,
    this.durationSeconds = 15,
    required this.slotType,
    this.showId,
    this.showName,
  });

  factory TechnicianAnnouncementSlot.fromJson(Map<String, dynamic> j) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return TechnicianAnnouncementSlot(
      startTime: parseTime(j['startTime'] ?? j['date']),
      durationSeconds: (j['durationSeconds'] ?? 15) as int,
      slotType: (j['slotType'] ?? 'between').toString(),
      showId: j['showId']?.toString(),
      showName: j['showName']?.toString(),
    );
  }

  String get timeLabel =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
}

class TechnicianAnnouncement {
  final String id;
  final String radioId;
  final String category;
  final String listenerName;
  final String finalText;
  final String originalText;
  final int durationSeconds;
  final String priority;
  final String status;
  final DateTime scheduledFor;
  final List<TechnicianAnnouncementSlot> assignedSlots;
  final DateTime? airedAt;
  final String? airedBy;
  final String? airedRole;

  TechnicianAnnouncement({
    required this.id,
    required this.radioId,
    required this.category,
    required this.listenerName,
    required this.finalText,
    this.originalText = '',
    this.durationSeconds = 30,
    this.priority = 'standard',
    this.status = 'scheduled',
    required this.scheduledFor,
    this.assignedSlots = const [],
    this.airedAt,
    this.airedBy,
    this.airedRole,
  });

  factory TechnicianAnnouncement.fromFirestore(Map<String, dynamic> d, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    List<TechnicianAnnouncementSlot> slots = [];
    if (d['assignedSlots'] is List) {
      slots = (d['assignedSlots'] as List)
          .whereType<Map>()
          .map((m) => TechnicianAnnouncementSlot.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    return TechnicianAnnouncement(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      category: (d['category'] ?? 'General').toString(),
      listenerName: (d['listenerName'] ?? 'Listener').toString(),
      finalText: (d['finalText'] ?? d['text'] ?? d['message'] ?? '').toString(),
      originalText: (d['originalText'] ?? '').toString(),
      durationSeconds: (d['durationSeconds'] ?? d['estimatedDurationSeconds'] ?? 30) as int,
      priority: (d['priority'] ?? 'standard').toString(),
      status: (d['status'] ?? 'scheduled').toString(),
      scheduledFor: parseDate(d['scheduledFor'] ?? d['desiredStartDate'] ?? d['startDate']),
      assignedSlots: slots,
      airedAt: FSParsers.toDate(d['airedAt']),
      airedBy: d['airedBy']?.toString(),
      airedRole: d['airedRole']?.toString(),
    );
  }

  bool get isAired => status == 'broadcasted' || status == 'aired';
  bool get isBetweenSlot => assignedSlots.any((s) => s.slotType == 'between') || priority.toLowerCase() == 'standard';
  bool get isWithinShowSlot => assignedSlots.any((s) => s.slotType == 'within');

  bool isDueNow(DateTime now) {
    if (isAired) return false;
    final diff = now.difference(scheduledFor).inMinutes;
    if (diff >= -5 && diff <= 30) return true;

    for (final s in assignedSlots) {
      final slotDiff = now.difference(s.startTime).inMinutes;
      if (slotDiff >= -5 && slotDiff <= 30) return true;
    }
    return false;
  }
}
