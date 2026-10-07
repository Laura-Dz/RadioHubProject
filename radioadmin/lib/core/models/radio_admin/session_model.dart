import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';
import 'program_model.dart';

enum SessionStatus {
  scheduled,
  live,
  ended,
  rediffusion,
}

class Session {
  final String id;
  final String radioId;
  final String programId;
  final String programName;
  final ProgramCategory programCategory;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String? hostId;
  final String? hostName;
  final List<String> coHostIds;
  final List<String> coHostNames;
  final String? coHostId;
  final String? coHostName;
  final String? guestId;
  final List<Map<String, String>> guests;
  final String? guestName;
  final String? guestRole;
  final String? thematic;
  final String? description;
  final SessionStatus status;
  final int listenerCount;
  final double completionRate;
  final int engagementCount;
  final String? format;
  final String? tone;
  final String? languageRegister;
  final ThemeInfo? theme;
  final AudienceInfo? audience;
  final String? recordingUrl;
  final String? rediffusionSourceId;
  final DateTime createdAt;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final bool isSpecialEvent;

  Session({
    required this.id,
    this.radioId = '',
    required this.programId,
    required this.programName,
    this.programCategory = ProgramCategory.music,
    DateTime? date,
    required this.startTime,
    required this.endTime,
    this.hostId,
    this.hostName,
    this.coHostIds = const [],
    this.coHostNames = const [],
    String? coHostId,
    String? coHostName,
    this.guestId,
    this.guests = const [],
    String? guestName,
    this.guestRole,
    this.thematic,
    this.description,
    this.status = SessionStatus.scheduled,
    this.listenerCount = 0,
    this.completionRate = 0.0,
    this.engagementCount = 0,
    this.format,
    this.tone,
    this.languageRegister,
    this.theme,
    this.audience,
    this.recordingUrl,
    this.rediffusionSourceId,
    DateTime? createdAt,
    this.startedAt,
    this.endedAt,
    this.isSpecialEvent = false,
  })  : date = date ?? startTime,
        coHostId = coHostId ?? (coHostIds.isNotEmpty ? coHostIds.first : null),
        coHostName = coHostName ?? (coHostNames.isNotEmpty ? coHostNames.first : null),
        guestName = guestName ?? (guests.isNotEmpty ? guests.first['name'] : null),
        createdAt = createdAt ?? startTime;

  factory Session.fromFirestore(Map<String, dynamic> data, String id) {
    final start = FSParsers.toDate(data['actualStart']) ??
        FSParsers.toDate(data['scheduledStart']) ??
        FSParsers.toDate(data['startTime']) ??
        FSParsers.toDate(data['date']) ??
        FSParsers.toDate(data['createdAt']) ??
        DateTime.now();
    final end = FSParsers.toDate(data['actualEnd']) ??
        FSParsers.toDate(data['scheduledEnd']) ??
        FSParsers.toDate(data['endTime']) ??
        start.add(const Duration(hours: 2));

    List<String> parsedCoHostIds = [];
    if (data['coHostIds'] is List) {
      parsedCoHostIds = List<String>.from(data['coHostIds']);
    } else if (data['coHostId'] != null && data['coHostId'].toString().isNotEmpty) {
      parsedCoHostIds = [data['coHostId'].toString()];
    }

    List<String> parsedCoHostNames = [];
    if (data['coHostNames'] is List) {
      parsedCoHostNames = List<String>.from(data['coHostNames']);
    } else if (data['coHostName'] != null && data['coHostName'].toString().isNotEmpty) {
      parsedCoHostNames = [data['coHostName'].toString()];
    }

    List<Map<String, String>> parsedGuests = [];
    if (data['guests'] is List) {
      for (final item in (data['guests'] as List)) {
        if (item is Map) {
          parsedGuests.add({
            'name': (item['name'] ?? '').toString(),
            'role': (item['role'] ?? '').toString(),
          });
        }
      }
    } else if (data['guestName'] != null && data['guestName'].toString().isNotEmpty) {
      parsedGuests.add({
        'name': data['guestName'].toString(),
        'role': (data['guestRole'] ?? '').toString(),
      });
    }

    final rawStatus = (data['status'] ?? '').toString().toLowerCase();
    SessionStatus parsedStatus;
    if (rawStatus == 'on_air' || rawStatus == 'live') {
      parsedStatus = SessionStatus.live;
    } else if (rawStatus == 'ended') {
      parsedStatus = SessionStatus.ended;
    } else if (rawStatus == 'rediffusion') {
      parsedStatus = SessionStatus.rediffusion;
    } else {
      parsedStatus = SessionStatus.scheduled;
    }

    return Session(
      id: id,
      radioId: (data['radioId'] ?? '').toString(),
      programId: (data['programId'] ?? '').toString(),
      programName: (data['programName'] ?? 'Untitled Program').toString(),
      programCategory: ProgramCategory.values.firstWhere(
        (e) => e.toString() == data['programCategory'] || e.name == data['programCategory'],
        orElse: () => ProgramCategory.music,
      ),
      date: FSParsers.toDate(data['date']) ?? start,
      startTime: start,
      endTime: end,
      hostId: data['hostId']?.toString(),
      hostName: data['hostName']?.toString(),
      coHostIds: parsedCoHostIds,
      coHostNames: parsedCoHostNames,
      coHostId: data['coHostId']?.toString(),
      coHostName: data['coHostName']?.toString(),
      guestId: data['guestId']?.toString(),
      guests: parsedGuests,
      guestName: data['guestName']?.toString() ?? (parsedGuests.isNotEmpty ? parsedGuests.first['name'] : null),
      guestRole: data['guestRole']?.toString() ?? (parsedGuests.isNotEmpty ? parsedGuests.first['role'] : null),
      thematic: data['thematic']?.toString(),
      description: data['description']?.toString(),
      status: parsedStatus,
      listenerCount: FSParsers.toInt(data['listenerCount']),
      completionRate: FSParsers.toDouble(data['completionRate']),
      engagementCount: FSParsers.toInt(data['engagementCount']),
      format: data['format']?.toString(),
      tone: data['tone']?.toString(),
      languageRegister: data['languageRegister']?.toString(),
      theme: data['theme'] is Map ? ThemeInfo.fromMap(Map<String, dynamic>.from(data['theme'])) : null,
      audience: data['audience'] is Map ? AudienceInfo.fromMap(Map<String, dynamic>.from(data['audience'])) : null,
      recordingUrl: data['recordingUrl']?.toString(),
      rediffusionSourceId: data['rediffusionSourceId']?.toString(),
      createdAt: FSParsers.toDate(data['createdAt']) ?? start,
      startedAt: FSParsers.toDate(data['startedAt']),
      endedAt: FSParsers.toDate(data['endedAt']),
      isSpecialEvent: FSParsers.toBool(data['isSpecialEvent']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'programId': programId,
    'programName': programName,
    'programCategory': programCategory.toString().split('.').last,
    'date': date,
    'startTime': startTime,
    'endTime': endTime,
    'hostId': hostId,
    'hostName': hostName,
    'coHostIds': coHostIds,
    'coHostNames': coHostNames,
    'coHostId': coHostId,
    'coHostName': coHostName,
    'guestId': guestId,
    'guests': guests,
    'guestName': guestName ?? (guests.isNotEmpty ? guests.first['name'] : null),
    'guestRole': guestRole ?? (guests.isNotEmpty ? guests.first['role'] : null),
    'thematic': thematic,
    'description': description,
    'status': status.toString().split('.').last,
    'listenerCount': listenerCount,
    'completionRate': completionRate,
    'engagementCount': engagementCount,
    if (format != null) 'format': format,
    if (tone != null) 'tone': tone,
    if (languageRegister != null) 'languageRegister': languageRegister,
    if (theme != null) 'theme': theme!.toMap(),
    if (audience != null) 'audience': audience!.toMap(),
    'recordingUrl': recordingUrl,
    'rediffusionSourceId': rediffusionSourceId,
    'createdAt': FieldValue.serverTimestamp(),
    'startedAt': startedAt,
    'endedAt': endedAt,
    'isSpecialEvent': isSpecialEvent,
  };

  Program get program => Program(
    id: programId,
    radioId: radioId,
    name: programName,
    description: description ?? '',
    category: programCategory,
    duration: Duration.zero,
    createdAt: createdAt,
  );
}

class ThemeInfo {
  final String? category;
  final String? specificTopic;
  final bool isRecurring;

  ThemeInfo({
    this.category,
    this.specificTopic,
    this.isRecurring = false,
  });

  factory ThemeInfo.fromMap(Map<String, dynamic> m) => ThemeInfo(
    category: m['category']?.toString(),
    specificTopic: m['specificTopic']?.toString(),
    isRecurring: FSParsers.toBool(m['isRecurring']),
  );

  Map<String, dynamic> toMap() => {
    if (category != null) 'category': category,
    if (specificTopic != null) 'specificTopic': specificTopic,
    'isRecurring': isRecurring,
  };
}

class AudienceInfo {
  final Map<String, double> ageDistribution;
  final Map<String, double> genderSplit;
  final List<String> topLocations;
  final Map<String, double> newVsReturning;

  AudienceInfo({
    this.ageDistribution = const {},
    this.genderSplit = const {},
    this.topLocations = const [],
    this.newVsReturning = const {},
  });

  factory AudienceInfo.fromMap(Map<String, dynamic> m) {
    return AudienceInfo(
      ageDistribution: FSParsers.toDoubleMap(m['ageDistribution']),
      genderSplit: FSParsers.toDoubleMap(m['genderSplit']),
      topLocations: FSParsers.toStringList(m['topLocations']),
      newVsReturning: FSParsers.toDoubleMap(m['newVsReturning']),
    );
  }

  Map<String, dynamic> toMap() => {
    'ageDistribution': ageDistribution,
    'genderSplit': genderSplit,
    'topLocations': topLocations,
    'newVsReturning': newVsReturning,
  };
}