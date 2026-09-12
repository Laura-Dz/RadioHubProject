import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

enum SessionStatus { scheduled, live, ended, rediffusion, cancelled }

class Session {
  final String id;
  final String radioId;
  final String? timetableSlotId;         // links session to the slot it occupies
  final String programId;
  final String programName;
  final String hostId;
  final String hostName;
  final List<String> coHostIds;          // optional co-hosts for this session
  final List<String> coHostNames;
  final String? guestName;
  final String? guestRole;
  final String? thematic;
  final String? description;
  final String? format;           // interview | call_in | panel | solo
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final DateTime? actualStart;
  final DateTime? actualEnd;
  final SessionStatus status;
  final bool isRediffusion;
  final String? sourceSessionId;  // when rediffusion
  final String? sessionCode;      // host access code, set on start
  final String? recordingUrl;
  final int listenerCount;
  final double completionRate;
  final int engagementCount;
  final bool allowCalls;          // false on rediffusion
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
    String? coHostId,
    String? coHostName,
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
    this.completionRate = 0.0,
    this.engagementCount = 0,
    this.allowCalls = true,
    required this.createdAt,
    this.updatedAt,
  }) : coHostId = coHostId ?? (coHostIds.isNotEmpty ? coHostIds.first : null),
       coHostName = coHostName ?? (coHostNames.isNotEmpty ? coHostNames.first : null);

  final String? coHostId;
  final String? coHostName;

  factory Session.fromFirestore(Map<String, dynamic> d, String id) {
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
      scheduledStart: FSParsers.toDate(d['scheduledStart']) ?? DateTime.now(),
      scheduledEnd: FSParsers.toDate(d['scheduledEnd']) ?? DateTime.now(),
      actualStart: FSParsers.toDate(d['actualStart']),
      actualEnd: FSParsers.toDate(d['actualEnd']),
      status: SessionStatus.values.firstWhere(
        (e) => e.toString() == 'SessionStatus.${d['status']}',
        orElse: () => SessionStatus.scheduled,
      ),
      isRediffusion: d['isRediffusion'] == true,
      sourceSessionId: d['sourceSessionId']?.toString(),
      sessionCode: d['sessionCode']?.toString(),
      recordingUrl: d['recordingUrl']?.toString(),
      listenerCount: FSParsers.toInt(d['listenerCount']),
      completionRate: FSParsers.toDouble(d['completionRate']),
      engagementCount: FSParsers.toInt(d['engagementCount']),
      allowCalls: d['allowCalls'] != false,
      createdAt: FSParsers.toDate(d['createdAt']) ?? DateTime.now(),
      updatedAt: FSParsers.toDate(d['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'radioId': radioId,
        'timetableSlotId': timetableSlotId,
        'programId': programId,
        'programName': programName,
        'hostId': hostId,
        'hostName': hostName,
        'coHostIds': coHostIds,
        'coHostNames': coHostNames,
        'coHostId': coHostId,
        'coHostName': coHostName,
        'guestName': guestName,
        'guestRole': guestRole,
        'thematic': thematic,
        'description': description,
        'format': format,
        'scheduledStart': Timestamp.fromDate(scheduledStart),
        'scheduledEnd': Timestamp.fromDate(scheduledEnd),
        'actualStart': actualStart != null ? Timestamp.fromDate(actualStart!) : null,
        'actualEnd': actualEnd != null ? Timestamp.fromDate(actualEnd!) : null,
        'status': status.toString().split('.').last,
        'isRediffusion': isRediffusion,
        'sourceSessionId': sourceSessionId,
        'sessionCode': sessionCode,
        'recordingUrl': recordingUrl,
        'listenerCount': listenerCount,
        'completionRate': completionRate,
        'engagementCount': engagementCount,
        'allowCalls': allowCalls,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// True if current time is within 5 min before start.
  bool get canBeStarted {
    final now = DateTime.now();
    final windowStart = scheduledStart.subtract(const Duration(minutes: 5));
    return now.isAfter(windowStart) &&
        now.isBefore(scheduledEnd) &&
        status == SessionStatus.scheduled &&
        !isRediffusion;
  }

  bool get isLive => status == SessionStatus.live;

  Duration get duration => scheduledEnd.difference(scheduledStart);

  String get statusLabel {
    switch (status) {
      case SessionStatus.scheduled: return 'Scheduled';
      case SessionStatus.live: return 'Live';
      case SessionStatus.ended: return 'Ended';
      case SessionStatus.rediffusion: return 'Rediffusion';
      case SessionStatus.cancelled: return 'Cancelled';
    }
  }

  /// Human-facing tag shown in the UI. Rediffusion always wins.
  String get displayTag {
    if (isRediffusion) return 'REDIFFUSION';
    switch (status) {
      case SessionStatus.live: return 'LIVE';
      case SessionStatus.scheduled: return 'UPCOMING';
      case SessionStatus.ended: return 'ENDED';
      case SessionStatus.cancelled: return 'CANCELLED';
      case SessionStatus.rediffusion: return 'REDIFFUSION';
    }
  }

  /// True only for genuine live broadcasts — no rediffusion.
  bool get showsLiveIndicator =>
      !isRediffusion && status == SessionStatus.live;

  bool get showsRediffusionIndicator => isRediffusion;
}
