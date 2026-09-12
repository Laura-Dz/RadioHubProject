import 'package:cloud_firestore/cloud_firestore.dart';

class SessionModel {
  final String id;
  final String programId;
  final String programName;
  final String? radioId;
  final String? radioName;
  final String? thematic;
  final String hostId;
  final String hostName;
  final String? guestName;
  final DateTime date;
  final DateTime? startTime;
  final DateTime? endTime;
  final DateTime? startedAt;
  final String status; // 'live', 'scheduled', 'recorded', 'ended'
  final int listenerCount;
  final String? recordingUrl;
  final DateTime createdAt;

  SessionModel({
    required this.id,
    required this.programId,
    required this.programName,
    this.radioId,
    this.radioName,
    this.thematic,
    required this.hostId,
    required this.hostName,
    this.guestName,
    required this.date,
    this.startTime,
    this.endTime,
    this.startedAt,
    this.status = 'scheduled',
    this.listenerCount = 0,
    this.recordingUrl,
    required this.createdAt,
  });

  bool get isLive => status == 'live';

  factory SessionModel.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val, [DateTime? defaultVal]) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return defaultVal ?? DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    return SessionModel(
      id: id,
      programId: data['programId'] ?? '',
      programName: data['programName'] ?? 'Unknown Show',
      radioId: data['radioId'] ?? data['programId'],
      radioName: data['radioName'] ?? data['programName'],
      thematic: data['thematic'],
      hostId: data['hostId'] ?? '',
      hostName: data['hostName'] ?? 'Unknown Host',
      guestName: data['guestName'],
      date: parseDate(data['date']),
      startTime: parseNullableDate(data['startTime']),
      endTime: parseNullableDate(data['endTime']),
      startedAt: parseNullableDate(data['startedAt']),
      status: data['status'] ?? 'scheduled',
      listenerCount: (data['listenerCount'] ?? 0) as int,
      recordingUrl: data['recordingUrl'],
      createdAt: parseDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'programId': programId,
      'programName': programName,
      'radioId': radioId ?? programId,
      'radioName': radioName ?? programName,
      'thematic': thematic,
      'hostId': hostId,
      'hostName': hostName,
      'guestName': guestName,
      'date': Timestamp.fromDate(date),
      'startTime': startTime != null ? Timestamp.fromDate(startTime!) : null,
      'endTime': endTime != null ? Timestamp.fromDate(endTime!) : null,
      'startedAt': startedAt != null ? Timestamp.fromDate(startedAt!) : null,
      'status': status,
      'listenerCount': listenerCount,
      'recordingUrl': recordingUrl,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'programId': programId,
      'programName': programName,
      'radioId': radioId ?? programId,
      'radioName': radioName ?? programName,
      'thematic': thematic,
      'hostId': hostId,
      'hostName': hostName,
      'guestName': guestName,
      'date': date,
      'startTime': startTime,
      'endTime': endTime,
      'startedAt': startedAt,
      'status': status,
      'listenerCount': listenerCount,
      'recordingUrl': recordingUrl,
    };
  }
}

