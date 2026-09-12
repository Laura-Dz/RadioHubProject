import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus {
  scheduled,
  live,
  ended,
  cancelled,
  rediffusion,
}

class Session {
  final String id;
  final String radioId;
  final String? timetableSlotId;
  final String programId;
  final String programName;
  final String hostId;
  final String hostName;
  final List<String> coHostIds;
  final List<String> coHostNames;
  final String? guestName;
  final String? guestRole;
  final String? thematic;
  final String? description;
  final String? format;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final SessionStatus status;
  final bool isRediffusion;
  final String? sourceSessionId;
  final String? sessionCode;
  final String? recordingUrl;
  final int listenerCount;
  final double completionRate;
  final int engagementCount;
  final bool allowCalls;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Session({
    required this.id,
    required this.radioId,
    this.timetableSlotId,
    required this.programId,
    required this.programName,
    required this.hostId,
    required this.hostName,
    this.coHostIds = const [],
    this.coHostNames = const [],
    this.guestName,
    this.guestRole,
    this.thematic,
    this.description,
    this.format,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.actualStart,
    this.actualEnd,
    this.status = SessionStatus.scheduled,
    this.isRediffusion = false,
    this.sourceSessionId,
    this.sessionCode,
    this.recordingUrl,
    this.listenerCount = 0,
    this.completionRate = 0,
    this.engagementCount = 0,
    this.allowCalls = true,
    required this.createdAt,
    this.updatedAt,
  });

  factory Session.fromFirestore(Map<String, dynamic> d, String id) {
    DateTime? toDate(dynamic v) {
      if (v == null) return null;
      if (v is Timestamp) return v.toDate();
      if (v is DateTime) return v;
      if (v is String) return DateTime.tryParse(v);
      return null;
    }

    int toInt(dynamic v, {int fallback = 0}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    double toDouble(dynamic v, {double fallback = 0.0}) {
      if (v == null) return fallback;
      if (v is double) return v;
      if (v is num) return v.toDouble();
      return double.tryParse(v.toString()) ?? fallback;
    }

    List<String> parsedCoHostIds = [];
    if (d['coHostIds'] is List) {
      parsedCoHostIds = List<String>.from(d['coHostIds']);
    } else if (d['coHostId'] != null && d['coHostId'].toString().isNotEmpty) {
      parsedCoHostIds = [d['coHostId'].toString()];
    }

    List<String> parsedCoHostNames = [];
    if (d['coHostNames'] is List) {
      parsedCoHostNames = List<String>.from(d['coHostNames']);
    } else if (d['coHostName'] != null && d['coHostName'].toString().isNotEmpty) {
      parsedCoHostNames = [d['coHostName'].toString()];
    }

    final statusStr = (d['status'] ?? 'scheduled').toString();
    SessionStatus parsedStatus;
    switch (statusStr) {
      case 'live':
        parsedStatus = SessionStatus.live;
        break;
      case 'ended':
        parsedStatus = SessionStatus.ended;
        break;
      case 'cancelled':
        parsedStatus = SessionStatus.cancelled;
        break;
      case 'rediffusion':
        parsedStatus = SessionStatus.rediffusion;
        break;
      default:
        parsedStatus = SessionStatus.scheduled;
    }

    return Session(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      timetableSlotId: d['timetableSlotId']?.toString(),
      programId: (d['programId'] ?? '').toString(),
      programName: (d['programName'] ?? '').toString(),
      hostId: (d['hostId'] ?? '').toString(),
      hostName: (d['hostName'] ?? '').toString(),
      coHostIds: parsedCoHostIds,
      coHostNames: parsedCoHostNames,
      guestName: d['guestName']?.toString(),
      guestRole: d['guestRole']?.toString(),
      thematic: d['thematic']?.toString(),
      description: d['description']?.toString(),
      format: d['format']?.toString(),
      scheduledStart: toDate(d['scheduledStart']) ?? DateTime.now(),
      scheduledEnd: toDate(d['scheduledEnd']) ?? DateTime.now(),
      actualStart: toDate(d['actualStart']),
      actualEnd: toDate(d['actualEnd']),
      status: parsedStatus,
      isRediffusion: d['isRediffusion'] == true || parsedStatus == SessionStatus.rediffusion,
      sourceSessionId: d['sourceSessionId']?.toString(),
      sessionCode: d['sessionCode']?.toString(),
      recordingUrl: d['recordingUrl']?.toString(),
      listenerCount: toInt(d['listenerCount']),
      completionRate: toDouble(d['completionRate']),
      engagementCount: toInt(d['engagementCount']),
      allowCalls: d['allowCalls'] != false,
      createdAt: toDate(d['createdAt']) ?? DateTime.now(),
      updatedAt: toDate(d['updatedAt']),
    );
  }

  /// Human-facing tag shown in the UI. Rediffusion always wins.
  String get displayTag {
    if (isRediffusion) return 'REDIFFUSION';
    switch (status) {
      case SessionStatus.live:
        return 'LIVE';
      case SessionStatus.scheduled:
        return 'UPCOMING';
      case SessionStatus.ended:
        return 'ENDED';
      case SessionStatus.cancelled:
        return 'CANCELLED';
      case SessionStatus.rediffusion:
        return 'REDIFFUSION';
    }
  }

  /// True only for genuine live broadcasts — no rediffusion.
  bool get showsLiveIndicator =>
      !isRediffusion && status == SessionStatus.live;

  bool get showsRediffusionIndicator => isRediffusion;

  bool get isLive => status == SessionStatus.live;

  Duration get duration => scheduledEnd.difference(scheduledStart);
}
