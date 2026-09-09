import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum BackupStatus { pending, inProgress, completed, failed, restoring }

enum BackupType { full, incremental, database, media }

class Backup {
  final String id;
  final String name;
  final BackupType type;
  final BackupStatus status;
  final DateTime startTime;
  final DateTime? endTime;
  final int sizeBytes;
  final String? location;
  final String? description;
  final String? failureReason;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  Backup({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.startTime,
    this.endTime,
    this.sizeBytes = 0,
    this.location,
    this.description,
    this.failureReason,
    this.metadata = const {},
    required this.createdAt,
  });

  factory Backup.fromFirestore(Map<String, dynamic> data, String id) {
    return Backup(
      id: id,
      name: data['name'] ?? 'Unnamed Backup',
      type: BackupType.values.firstWhere(
        (e) => e.toString() == data['type'],
        orElse: () => BackupType.full,
      ),
      status: BackupStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => BackupStatus.pending,
      ),
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      sizeBytes: data['sizeBytes'] ?? 0,
      location: data['location'],
      description: data['description'],
      failureReason: data['failureReason'],
      metadata: data['metadata'] ?? {},
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'type': type.toString().split('.').last,
    'status': status.toString().split('.').last,
    'startTime': startTime,
    'endTime': endTime,
    'sizeBytes': sizeBytes,
    'location': location,
    'description': description,
    'failureReason': failureReason,
    'metadata': metadata,
    'createdAt': FieldValue.serverTimestamp(),
  };

  String get statusLabel {
    switch (status) {
      case BackupStatus.pending:
        return '⏳ Pending';
      case BackupStatus.inProgress:
        return '🔄 In Progress';
      case BackupStatus.completed:
        return '✅ Completed';
      case BackupStatus.failed:
        return '❌ Failed';
      case BackupStatus.restoring:
        return '♻️ Restoring';
    }
  }

  Color get statusColor {
    switch (status) {
      case BackupStatus.pending:
        return Colors.orange;
      case BackupStatus.inProgress:
        return Colors.blue;
      case BackupStatus.completed:
        return Colors.green;
      case BackupStatus.failed:
        return Colors.red;
      case BackupStatus.restoring:
        return Colors.purple;
    }
  }

  String get sizeDisplay {
    if (sizeBytes >= 1073741824) {
      return '${(sizeBytes / 1073741824).toStringAsFixed(1)} GB';
    } else if (sizeBytes >= 1048576) {
      return '${(sizeBytes / 1048576).toStringAsFixed(1)} MB';
    } else if (sizeBytes >= 1024) {
      return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${sizeBytes} B';
  }

  String get typeLabel {
    switch (type) {
      case BackupType.full:
        return '📦 Full';
      case BackupType.incremental:
        return '📋 Incremental';
      case BackupType.database:
        return '🗄️ Database';
      case BackupType.media:
        return '📁 Media';
    }
  }
}
