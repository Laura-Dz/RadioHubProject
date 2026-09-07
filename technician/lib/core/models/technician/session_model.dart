import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

enum SessionStatus {
  scheduled,
  live,
  paused,
  ended,
  rediffusion,
}

class Session {
  final String id;
  final String programId;
  final String programName;
  final DateTime date;
  final DateTime startTime;
  final DateTime endTime;
  final String? hostId;
  final String? hostName;
  final String? coHostId;
  final String? coHostName;
  final String? guestId;
  final String? guestName;
  final String? thematic;
  final String? description;
  final String? format;
  final bool isInteractive;
  final SessionStatus status;
  final Map<String, dynamic> metadata;
  final String? recordingUrl;
  final String? rediffusionSourceId;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Session({
    required this.id,
    required this.programId,
    required this.programName,
    required this.date,
    required this.startTime,
    required this.endTime,
    this.hostId,
    this.hostName,
    this.coHostId,
    this.coHostName,
    this.guestId,
    this.guestName,
    this.thematic,
    this.description,
    this.format,
    this.isInteractive = false,
    this.status = SessionStatus.scheduled,
    this.metadata = const {},
    this.recordingUrl,
    this.rediffusionSourceId,
    required this.createdAt,
    this.updatedAt,
  });

  factory Session.fromFirestore(Map<String, dynamic> data, String id) {
    return Session(
      id: id,
      programId: data['programId'] ?? '',
      programName: data['programName'] ?? 'Untitled Program',
      date: (data['date'] is Timestamp)
          ? (data['date'] as Timestamp).toDate()
          : DateTime.now(),
      startTime: (data['startTime'] is Timestamp)
          ? (data['startTime'] as Timestamp).toDate()
          : DateTime.now(),
      endTime: (data['endTime'] is Timestamp)
          ? (data['endTime'] as Timestamp).toDate()
          : DateTime.now().add(const Duration(hours: 1)),
      hostId: data['hostId'],
      hostName: data['hostName'],
      coHostId: data['coHostId'],
      coHostName: data['coHostName'],
      guestId: data['guestId'],
      guestName: data['guestName'],
      thematic: data['thematic'],
      description: data['description'],
      format: data['format'],
      isInteractive: data['isInteractive'] ?? false,
      status: SessionStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => SessionStatus.scheduled,
      ),
      metadata: Map<String, dynamic>.from(data['metadata'] ?? {}),
      recordingUrl: data['recordingUrl'],
      rediffusionSourceId: data['rediffusionSourceId'],
      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'programId': programId,
        'programName': programName,
        'date': date,
        'startTime': startTime,
        'endTime': endTime,
        'hostId': hostId,
        'hostName': hostName,
        'coHostId': coHostId,
        'coHostName': coHostName,
        'guestId': guestId,
        'guestName': guestName,
        'thematic': thematic,
        'description': description,
        'format': format,
        'isInteractive': isInteractive,
        'status': status.toString().split('.').last,
        'metadata': metadata,
        'recordingUrl': recordingUrl,
        'rediffusionSourceId': rediffusionSourceId,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  String get timeRange {
    String fmt(DateTime t) =>
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return '${fmt(startTime)} - ${fmt(endTime)}';
  }

  Duration get duration => endTime.difference(startTime);

  String get statusLabel {
    switch (status) {
      case SessionStatus.scheduled:
        return '📅 Scheduled';
      case SessionStatus.live:
        return '🟢 Live';
      case SessionStatus.paused:
        return '⏸️ Paused';
      case SessionStatus.ended:
        return '🔴 Ended';
      case SessionStatus.rediffusion:
        return '🔄 Rediffusion';
    }
  }

  Color get statusColor {
    switch (status) {
      case SessionStatus.scheduled:
        return Colors.blue;
      case SessionStatus.live:
        return Colors.green;
      case SessionStatus.paused:
        return Colors.orange;
      case SessionStatus.ended:
        return Colors.red;
      case SessionStatus.rediffusion:
        return Colors.purple;
    }
  }

  bool get isReplay => rediffusionSourceId != null;
}
