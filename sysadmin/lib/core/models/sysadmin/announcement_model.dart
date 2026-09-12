import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementStatus {
  pending,
  validated,
  rejected,
  printed,
}

class Announcement {
  final String id;
  final String radioId;
  final String radioName;
  final String listenerId;
  final String listenerName;
  final String message;
  final double amount;
  AnnouncementStatus status;
  final DateTime createdAt;
  DateTime? validatedAt;
  String? validatedBy;
  String? pdfUrl;
  bool isPrinted;

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
    if (statusStr.contains('printed')) {
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
      radioId: data['radioId'] ?? '',
      radioName: data['radioName'] ?? '',
      listenerId: data['listenerId'] ?? '',
      listenerName: data['listenerName'] ?? 'Listener',
      message: data['message'] ?? '',
      amount: ((data['amount'] ?? 0.0) as num).toDouble(),
      status: statusEnum,
      createdAt: parseDate(data['createdAt']),
      validatedAt: parseNullableDate(data['validatedAt']),
      validatedBy: data['validatedBy'],
      pdfUrl: data['pdfUrl'],
      isPrinted: data['isPrinted'] ?? false,
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
    };
  }

  String get statusLabel {
    switch (status) {
      case AnnouncementStatus.pending:
        return '⏳ Pending';
      case AnnouncementStatus.validated:
        return '✅ Validated';
      case AnnouncementStatus.rejected:
        return '❌ Rejected';
      case AnnouncementStatus.printed:
        return '📄 Printed';
    }
  }
}

