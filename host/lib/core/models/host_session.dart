import 'package:cloud_firestore/cloud_firestore.dart';

class HostSession {
  final String id;
  final String radioId;
  final String programName;
  final String hostName;
  final String? guestName;
  final String? guestRole;
  final List<Map<String, String>> guests;
  final List<String> coHostNames;
  final String? thematic;
  final DateTime scheduledStart;
  final DateTime scheduledEnd;
  final String status;
  final int listenerCount;
  final int peakListeners;
  final int commentsCount;
  final int callsCount;
  final int likesCount;
  final bool allowCalls;
  final bool allowComments;

  HostSession({
    required this.id,
    required this.radioId,
    required this.programName,
    required this.hostName,
    this.guestName,
    this.guestRole,
    this.guests = const [],
    this.coHostNames = const [],
    this.thematic,
    required this.scheduledStart,
    required this.scheduledEnd,
    required this.status,
    this.listenerCount = 0,
    this.peakListeners = 0,
    this.commentsCount = 0,
    this.callsCount = 0,
    this.likesCount = 0,
    this.allowCalls = true,
    this.allowComments = true,
  });

  factory HostSession.fromFirestore(Map<String, dynamic> d, String id) {
    final List<Map<String, String>> parsedGuests = [];
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

    return HostSession(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      programName: (d['programName'] ?? '').toString(),
      hostName: (d['hostName'] ?? '').toString(),
      guestName: d['guestName']?.toString() ?? (parsedGuests.isNotEmpty ? parsedGuests.first['name'] : null),
      guestRole: d['guestRole']?.toString() ?? (parsedGuests.isNotEmpty ? parsedGuests.first['role'] : null),
      guests: parsedGuests,
      coHostNames: List<String>.from(d['coHostNames'] ?? []),
      thematic: d['thematic']?.toString(),
      scheduledStart: (d['scheduledStart'] as Timestamp?)?.toDate().toLocal() ??
          DateTime.now(),
      scheduledEnd: (d['scheduledEnd'] as Timestamp?)?.toDate().toLocal() ??
          DateTime.now(),
      status: (d['status'] ?? 'scheduled').toString(),
      listenerCount: (d['listenerCount'] ?? 0) as int,
      peakListeners: (d['peakListeners'] ?? 0) as int,
      commentsCount: (d['commentsCount'] ?? 0) as int,
      callsCount: (d['callsCount'] ?? 0) as int,
      likesCount: (d['likesCount'] ?? 0) as int,
      allowCalls: d['allowCalls'] != false,
      allowComments: d['allowComments'] != false,
    );
  }

  bool get isOnAir => status == 'on_air';
  bool get isEnded => status == 'ended';
}
