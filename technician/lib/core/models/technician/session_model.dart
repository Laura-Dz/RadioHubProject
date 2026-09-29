import 'package:cloud_firestore/cloud_firestore.dart';
import '../../services/network_time_service.dart';
import '../../utils/firestore_parsers.dart';

enum SessionType { live, intermediary, special, flash }
enum SessionStatus { scheduled, onAir, ended, cancelled }

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
  final List<Map<String, String>> guests; // multiple guests: [{'name': '...', 'role': '...'}]
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
  final SessionType sessionType;
  final bool isRediffusion;
  final String? sourceSessionId;  // when rediffusion
  final String? sessionCode;      // host access code, set on start
  final String? recordingUrl;
  final int listenerCount;
  final double completionRate;
  final int engagementCount;
  final bool allowCalls;          // false on rediffusion
  final bool isSpecialEvent;      // true when sessionType == special or Firestore flag set
  final DateTime createdAt;
  final DateTime? updatedAt;

  Session({
    required this.id,
    required this.radioId,
    this.timetableSlotId,
    required this.programId,
    required this.programName,
    this.hostId = '',
    this.hostName = '',
    this.coHostIds = const [],
    this.coHostNames = const [],
    this.guests = const [],
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
    this.sessionType = SessionType.live,
    this.isRediffusion = false,
    this.sourceSessionId,
    this.sessionCode,
    this.recordingUrl,
    this.listenerCount = 0,
    this.completionRate = 0.0,
    this.engagementCount = 0,
    this.allowCalls = true,
    bool? isSpecialEvent,
    required this.createdAt,
    this.updatedAt,
  }) : coHostId = coHostId ?? (coHostIds.isNotEmpty ? coHostIds.first : null),
       coHostName = coHostName ?? (coHostNames.isNotEmpty ? coHostNames.first : null),
       isSpecialEvent = isSpecialEvent ?? (sessionType == SessionType.special);

  final String? coHostId;
  final String? coHostName;

  static String _statusKey(SessionStatus s) {
    switch (s) {
      case SessionStatus.scheduled: return 'scheduled';
      case SessionStatus.onAir: return 'on_air';
      case SessionStatus.ended: return 'ended';
      case SessionStatus.cancelled: return 'cancelled';
    }
  }

  static SessionStatus statusFromKey(String? k) {
    switch (k) {
      case 'on_air':
      case 'live':
        return SessionStatus.onAir;
      case 'ended':
        return SessionStatus.ended;
      case 'cancelled':
        return SessionStatus.cancelled;
      default:
        return SessionStatus.scheduled;
    }
  }

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

    List<Map<String, String>> parsedGuests = [];
    if (d['guests'] is List) {
      for (final item in (d['guests'] as List)) {
        if (item is Map) {
          parsedGuests.add({
            'name': (item['name'] ?? '').toString(),
            'role': (item['role'] ?? '').toString(),
          });
        }
      }
    } else if (d['guestName'] != null && d['guestName'].toString().isNotEmpty) {
      parsedGuests.add({
        'name': d['guestName'].toString(),
        'role': (d['guestRole'] ?? '').toString(),
      });
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
      guests: parsedGuests,
      guestName: d['guestName']?.toString() ?? (parsedGuests.isNotEmpty ? parsedGuests.first['name'] : null),
      guestRole: d['guestRole']?.toString() ?? (parsedGuests.isNotEmpty ? parsedGuests.first['role'] : null),
      thematic: d['thematic']?.toString(),
      description: d['description']?.toString(),
      format: d['format']?.toString(),
      scheduledStart: FSParsers.toDate(d['scheduledStart']) ?? DateTime.now(),
      scheduledEnd: FSParsers.toDate(d['scheduledEnd']) ?? DateTime.now(),
      actualStart: FSParsers.toDate(d['actualStart']),
      actualEnd: FSParsers.toDate(d['actualEnd']),
      status: SessionStatus.values.firstWhere(
        (e) => _statusKey(e) == d['status'],
        orElse: () => statusFromKey(d['status']?.toString()),
      ),
      sessionType: SessionType.values.firstWhere(
        (e) => e.name == d['sessionType']?.toString(),
        orElse: () {
          if (d['sessionType'] == 'special') return SessionType.special;
          if (d['sessionType'] == 'flash') return SessionType.flash;
          if (d['sessionType'] == 'intermediary') return SessionType.intermediary;
          return SessionType.live;
        },
      ),
      isRediffusion: d['isRediffusion'] == true,
      sourceSessionId: d['sourceSessionId']?.toString(),
      sessionCode: d['sessionCode']?.toString(),
      recordingUrl: (d['recordingUrl'] ??
              d['audioUrl'] ??
              d['mediaUrl'] ??
              d['recording'])
          ?.toString(),
      listenerCount: FSParsers.toInt(d['listenerCount']),
      completionRate: FSParsers.toDouble(d['completionRate']),
      engagementCount: FSParsers.toInt(d['engagementCount']),
      allowCalls: d['allowCalls'] != false,
      isSpecialEvent: d['isSpecialEvent'] == true || (d['sessionType']?.toString() == 'special'),
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
        'guests': guests,
        'guestName': guestName ?? (guests.isNotEmpty ? guests.first['name'] : null),
        'guestRole': guestRole ?? (guests.isNotEmpty ? guests.first['role'] : null),
        'thematic': thematic,
        'description': description,
        'format': format,
        'scheduledStart': Timestamp.fromDate(scheduledStart),
        'scheduledEnd': Timestamp.fromDate(scheduledEnd),
        'actualStart': actualStart != null ? Timestamp.fromDate(actualStart!) : null,
        'actualEnd': actualEnd != null ? Timestamp.fromDate(actualEnd!) : null,
        'status': _statusKey(status),
        'sessionType': sessionType.name,
        'isRediffusion': isRediffusion,
        'sourceSessionId': sourceSessionId,
        'sessionCode': sessionCode,
        'recordingUrl': recordingUrl,
        'listenerCount': listenerCount,
        'completionRate': completionRate,
        'engagementCount': engagementCount,
        'allowCalls': allowCalls,
        'isSpecialEvent': isSpecialEvent,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  /// True when playing right now (red dot on the schedule).
  bool get isOnAir => status == SessionStatus.onAir;

  /// True when the slot has passed.
  bool get isPassed =>
      status == SessionStatus.ended ||
      status == SessionStatus.cancelled ||
      (status == SessionStatus.scheduled &&
          scheduledEnd.isBefore(NetworkTimeService().now()));

  /// The content-type tags used for coloring the schedule slot.
  String get contentTag {
    if (isPassed) return 'passed';
    if (sessionType == SessionType.special) return 'special';
    if (sessionType == SessionType.flash) return 'flash';
    if (isRediffusion) return 'rediffusion';
    switch (sessionType) {
      case SessionType.live:
        return 'live';
      case SessionType.intermediary:
        return 'intermediary';
      case SessionType.special:
        return 'special';
      case SessionType.flash:
        return 'flash';
    }
  }

  /// Only live sessions (with hosts) can be rediffused later.
  bool get canBeRediffused =>
      sessionType == SessionType.live && !isRediffusion && !isPassed;

  /// True if current time is within 5 min before start.
  /// The session can be started only within 5 minutes of the scheduled start
  /// and before the scheduled end. No other session may be live.
  bool get isWithinStartWindow {
    final now = NetworkTimeService().now();
    final open = scheduledStart.subtract(const Duration(minutes: 5));
    return now.isAfter(open) && now.isBefore(scheduledEnd);
  }

  /// True when the technician should be able to press "Start".
  /// Actual live-collision check happens in the service layer.
  bool get canBeStarted =>
      status == SessionStatus.scheduled &&
      !isRediffusion &&
      isWithinStartWindow;

  /// Backward-compatible alias
  bool get canStartNow => canBeStarted;

  /// Live sessions can be ended at any time from the moment they start.
  bool get canBeEnded => status == SessionStatus.onAir;

  /// Minutes until the start window opens. Negative if already open.
  int get minutesUntilStart =>
      scheduledStart.difference(NetworkTimeService().now()).inMinutes;

  String get countdownLabel {
    final diff = scheduledStart.difference(NetworkTimeService().now());
    if (diff.inMinutes <= 0) return 'Starting now';
    if (diff.inMinutes < 60) return 'in ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'in ${diff.inHours}h ${diff.inMinutes % 60}m';
    return 'in ${diff.inDays}d';
  }

  /// Only scheduled sessions can be modified.
  bool get canBeEdited => status == SessionStatus.scheduled;

  /// Convenience — is this session in the past?
  bool get isPast =>
      status == SessionStatus.ended ||
      status == SessionStatus.cancelled ||
      scheduledEnd.isBefore(NetworkTimeService().now());

  bool get isLive => isOnAir;

  Duration get duration => scheduledEnd.difference(scheduledStart);

  String get statusLabel {
    switch (status) {
      case SessionStatus.scheduled: return 'Scheduled';
      case SessionStatus.onAir: return 'Live';
      case SessionStatus.ended: return 'Ended';
      case SessionStatus.cancelled: return 'Cancelled';
    }
  }

  /// Human-facing tag shown in the UI. Rediffusion always wins.
  String get displayTag {
    if (isRediffusion) return 'REDIFFUSION';
    switch (status) {
      case SessionStatus.onAir: return 'LIVE';
      case SessionStatus.scheduled: return 'UPCOMING';
      case SessionStatus.ended: return 'ENDED';
      case SessionStatus.cancelled: return 'CANCELLED';
    }
  }

  /// True only for genuine live broadcasts — no rediffusion.
  bool get showsLiveIndicator =>
      !isRediffusion && status == SessionStatus.onAir;

  bool get showsRediffusionIndicator => isRediffusion;
}
