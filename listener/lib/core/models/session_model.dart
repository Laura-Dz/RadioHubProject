import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionType { live, intermediary, special, flash }
enum SessionStatus { scheduled, onAir, ended, cancelled }

class SessionModel {
  final String id;
  final String radioId;
  final String programId;
  final String programName;
  final String? hostName;
  final List<String> coHostNames;
  final List<Map<String, String>> guests;
  final String? guestName;
  final String? guestRole;
  final String? thematic;
  final String? description;
  final String? imageUrl;
  final SessionType sessionType;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final SessionStatus status;
  final bool isRediffusion;
  final bool allowCalls;
  final bool allowComments;
  final int listenerCount;

  SessionModel({
    required this.id,
    required this.radioId,
    required this.programId,
    required this.programName,
    this.hostName,
    this.coHostNames = const [],
    this.guests = const [],
    this.guestName,
    this.guestRole,
    this.thematic,
    this.description,
    this.imageUrl,
    this.sessionType = SessionType.live,
    required this.scheduledStart,
    required this.scheduledEnd,
    this.status = SessionStatus.scheduled,
    this.isRediffusion = false,
    this.allowCalls = true,
    this.allowComments = true,
    this.listenerCount = 0,
  });

  factory SessionModel.fromFirestore(Map<String, dynamic> d, String id) {
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

    return SessionModel(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      programId: (d['programId'] ?? '').toString(),
      programName: (d['programName'] ?? '').toString(),
      hostName: d['hostName']?.toString(),
      coHostNames: List<String>.from(d['coHostNames'] ?? []),
      guests: parsedGuests,
      guestName: d['guestName']?.toString() ?? (parsedGuests.isNotEmpty ? parsedGuests.first['name'] : null),
      guestRole: d['guestRole']?.toString() ?? (parsedGuests.isNotEmpty ? parsedGuests.first['role'] : null),
      thematic: d['thematic']?.toString(),
      description: d['description']?.toString(),
      imageUrl: (d['imageUrl'] ?? d['posterUrl'] ?? d['coverUrl'] ?? d['bannerUrl'] ?? d['programImageUrl'] ?? d['photoUrl'] ?? d['image'])?.toString(),
      sessionType: SessionType.values.firstWhere(
        (e) => e.name == d['sessionType'],
        orElse: () => SessionType.live,
      ),
      scheduledStart:
          (d['scheduledStart'] as Timestamp?)?.toDate().toLocal() ??
              DateTime.now(),
      scheduledEnd:
          (d['scheduledEnd'] as Timestamp?)?.toDate().toLocal() ??
              DateTime.now(),
      status: SessionStatus.values.firstWhere(
        (e) => e.name == _statusKey(d['status']?.toString() ?? ''),
        orElse: () => SessionStatus.scheduled,
      ),
      isRediffusion: d['isRediffusion'] == true,
      allowCalls: d['allowCalls'] != false,
      allowComments: d['allowComments'] != false,
      listenerCount: (d['listenerCount'] ?? 0) as int,
    );
  }

  static String _statusKey(String s) {
    final clean = s.toLowerCase().replaceAll('_', '').replaceAll('-', '').trim();
    if (clean == 'onair' || clean == 'live' || clean == 'active') {
      return 'onAir';
    }
    if (clean == 'ended' || clean == 'closed' || clean == 'stopped' || clean == 'completed') {
      return 'ended';
    }
    if (clean == 'cancelled' || clean == 'canceled') {
      return 'cancelled';
    }
    return 'scheduled';
  }

  bool get isOnAir => status == SessionStatus.onAir;

  bool get isPast =>
      status == SessionStatus.ended ||
      status == SessionStatus.cancelled ||
      (status == SessionStatus.scheduled &&
          scheduledEnd.isBefore(DateTime.now()));

  /// Content tag — drives the slot color on the schedule.
  String get contentTag {
    if (isPast) return 'passed';
    if (isRediffusion) return 'rediffusion';
    switch (sessionType) {
      case SessionType.live: return 'live';
      case SessionType.intermediary: return 'intermediary';
      case SessionType.special: return 'special';
      case SessionType.flash: return 'flash';
    }
  }

  String get timeRange {
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(scheduledStart)}–${fmt(scheduledEnd)}';
  }

  String get displayTag {
    if (isRediffusion) return 'REDIFFUSION';
    if (isOnAir) return 'LIVE';
    if (isPast) return 'ENDED';
    return 'UPCOMING';
  }

  SessionModel copyWith({
    String? id,
    String? radioId,
    String? programId,
    String? programName,
    String? hostName,
    List<String>? coHostNames,
    String? guestName,
    String? guestRole,
    String? thematic,
    String? description,
    String? imageUrl,
    SessionType? sessionType,
    DateTime? scheduledStart,
    DateTime? scheduledEnd,
    SessionStatus? status,
    bool? isRediffusion,
    bool? allowCalls,
    bool? allowComments,
    int? listenerCount,
  }) {
    return SessionModel(
      id: id ?? this.id,
      radioId: radioId ?? this.radioId,
      programId: programId ?? this.programId,
      programName: programName ?? this.programName,
      hostName: hostName ?? this.hostName,
      coHostNames: coHostNames ?? this.coHostNames,
      guestName: guestName ?? this.guestName,
      guestRole: guestRole ?? this.guestRole,
      thematic: thematic ?? this.thematic,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      sessionType: sessionType ?? this.sessionType,
      scheduledStart: scheduledStart ?? this.scheduledStart,
      scheduledEnd: scheduledEnd ?? this.scheduledEnd,
      status: status ?? this.status,
      isRediffusion: isRediffusion ?? this.isRediffusion,
      allowCalls: allowCalls ?? this.allowCalls,
      allowComments: allowComments ?? this.allowComments,
      listenerCount: listenerCount ?? this.listenerCount,
    );
  }
}

typedef Session = SessionModel;
