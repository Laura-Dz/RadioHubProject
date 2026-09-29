import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

enum AnnouncementStatus {
  pending,
  validated,
  rejected,
  printed,
  broadcasted,
}

class Announcement {
  final String id;
  final String radioId;
  final String radioName;
  final String listenerId;
  final String listenerName;
  final String message;
  final double amount;
  final AnnouncementStatus status;
  final DateTime createdAt;
  final DateTime? validatedAt;
  final String? validatedBy;
  final String? pdfUrl;
  final bool isPrinted;
  final String? announcementCategory;
  final int? wordCount;
  final int? durationSeconds;
  final String? finalText;
  final DateTime? airedAt;
  final String? airedBy;
  final String? airedProgram;

  Announcement({
    required this.id,
    required this.radioId,
    required this.radioName,
    required this.listenerId,
    required this.listenerName,
    required this.message,
    required this.amount,
    required this.status,
    required this.createdAt,
    this.validatedAt,
    this.validatedBy,
    this.pdfUrl,
    this.isPrinted = false,
    this.announcementCategory,
    this.wordCount,
    this.durationSeconds,
    this.finalText,
    this.airedAt,
    this.airedBy,
    this.airedProgram,
  });

  factory Announcement.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return DateTime.now();
    }

    DateTime? parseNullableDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      return null;
    }

    final statusStr = (data['status'] ?? 'pending').toString().toLowerCase();
    AnnouncementStatus statusEnum;
    if (statusStr.contains('broadcast') || statusStr.contains('aired')) {
      statusEnum = AnnouncementStatus.broadcasted;
    } else if (statusStr.contains('printed')) {
      statusEnum = AnnouncementStatus.printed;
    } else if (statusStr.contains('validated')) {
      statusEnum = AnnouncementStatus.validated;
    } else if (statusStr.contains('rejected')) {
      statusEnum = AnnouncementStatus.rejected;
    } else {
      statusEnum = AnnouncementStatus.pending;
    }

    return Announcement(
      id: id,
      radioId: (data['radioId'] ?? '').toString(),
      radioName: (data['radioName'] ?? '').toString(),
      listenerId: (data['listenerId'] ?? '').toString(),
      listenerName: (data['listenerName'] ?? 'Listener').toString(),
      message: (data['message'] ?? '').toString(),
      amount: FSParsers.toDouble(data['amount']),
      status: statusEnum,
      createdAt: FSParsers.toDate(data['createdAt']) ?? DateTime.now(),
      validatedAt: FSParsers.toDate(data['validatedAt']),
      validatedBy: data['validatedBy']?.toString(),
      pdfUrl: data['pdfUrl']?.toString(),
      isPrinted: FSParsers.toBool(data['isPrinted']),
      announcementCategory: data['announcementCategory']?.toString(),
      wordCount: data['wordCount'] != null ? FSParsers.toInt(data['wordCount']) : null,
      durationSeconds: data['durationSeconds'] != null ? FSParsers.toInt(data['durationSeconds']) : null,
      finalText: data['finalText']?.toString(),
      airedAt: FSParsers.toDate(data['airedAt']),
      airedBy: data['airedBy']?.toString(),
      airedProgram: data['airedProgram']?.toString(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'radioId': radioId,
      'radioName': radioName,
      'listenerId': listenerId,
      'listenerName': listenerName,
      'message': message,
      'amount': amount,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'validatedAt': validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
      'validatedBy': validatedBy,
      'pdfUrl': pdfUrl,
      'isPrinted': isPrinted,
      'announcementCategory': announcementCategory,
      'wordCount': wordCount,
      'durationSeconds': durationSeconds,
      'finalText': finalText,
      'airedAt': airedAt != null ? Timestamp.fromDate(airedAt!) : null,
      'airedBy': airedBy,
      'airedProgram': airedProgram,
    };
  }

  String get statusLabel {
    switch (status) {
      case AnnouncementStatus.pending:
        return 'Pending';
      case AnnouncementStatus.validated:
        return 'Validated';
      case AnnouncementStatus.rejected:
        return 'Rejected';
      case AnnouncementStatus.printed:
        return 'Printed';
      case AnnouncementStatus.broadcasted:
        return 'Broadcasted Live';
    }
  }
}
