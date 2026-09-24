import 'package:cloud_firestore/cloud_firestore.dart';

class HostAnnouncementSlot {
  final DateTime startTime;
  final int durationSeconds;
  final String slotType; // 'between' | 'within'
  final String? showId;
  final String? showName;

  HostAnnouncementSlot({
    required this.startTime,
    this.durationSeconds = 15,
    required this.slotType,
    this.showId,
    this.showName,
  });

  factory HostAnnouncementSlot.fromJson(Map<String, dynamic> j) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    return HostAnnouncementSlot(
      startTime: parseTime(j['startTime'] ?? j['date']),
      durationSeconds: (j['durationSeconds'] ?? 15) as int,
      slotType: (j['slotType'] ?? 'within').toString(),
      showId: j['showId']?.toString(),
      showName: j['showName']?.toString(),
    );
  }

  String get timeLabel =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';
}

class HostAnnouncement {
  final String id;
  final String radioId;
  final String category;
  final String listenerName;
  final String finalText;
  final String originalText;
  final int wordCount;
  final int durationSeconds;
  final String priority;
  final String status;
  final DateTime scheduledFor;
  final List<HostAnnouncementSlot> assignedSlots;
  final DateTime? airedAt;
  final String? airedBy;

  HostAnnouncement({
    required this.id,
    required this.radioId,
    required this.category,
    required this.listenerName,
    required this.finalText,
    this.originalText = '',
    this.wordCount = 0,
    this.durationSeconds = 30,
    this.priority = 'high',
    this.status = 'scheduled',
    required this.scheduledFor,
    this.assignedSlots = const [],
    this.airedAt,
    this.airedBy,
  });

  factory HostAnnouncement.fromFirestore(Map<String, dynamic> d, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val) ?? DateTime.now();
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is String) return DateTime.tryParse(val);
      return null;
    }

    List<HostAnnouncementSlot> slots = [];
    if (d['assignedSlots'] is List) {
      slots = (d['assignedSlots'] as List)
          .whereType<Map>()
          .map((m) => HostAnnouncementSlot.fromJson(Map<String, dynamic>.from(m)))
          .toList();
    }

    final words = (d['wordCount'] as num?)?.toInt() ??
        ((d['finalText'] ?? '').toString().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length);

    return HostAnnouncement(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      category: (d['category'] ?? 'General').toString(),
      listenerName: (d['listenerName'] ?? 'Listener').toString(),
      finalText: (d['finalText'] ?? d['text'] ?? d['message'] ?? '').toString(),
      originalText: (d['originalText'] ?? '').toString(),
      wordCount: words,
      durationSeconds: (d['durationSeconds'] ?? d['estimatedDurationSeconds'] ?? 30) as int,
      priority: (d['priority'] ?? 'high').toString(),
      status: (d['status'] ?? 'scheduled').toString(),
      scheduledFor: parseDate(d['scheduledFor'] ?? d['desiredStartDate'] ?? d['startDate']),
      assignedSlots: slots,
      airedAt: parseNullableDate(d['airedAt']),
      airedBy: d['airedBy']?.toString(),
    );
  }

  bool get isAired => status == 'broadcasted' || status == 'aired';

  bool isDueNow(DateTime now) {
    if (isAired) return false;
    // Check if within 10 minutes of scheduledFor or any assigned slot
    final diff = now.difference(scheduledFor).inMinutes;
    if (diff >= -5 && diff <= 30) return true;

    for (final s in assignedSlots) {
      final slotDiff = now.difference(s.startTime).inMinutes;
      if (slotDiff >= -5 && slotDiff <= 30) return true;
    }
    return false;
  }
}
