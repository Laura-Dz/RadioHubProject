import 'package:cloud_firestore/cloud_firestore.dart';

enum TransactionType {
  subscription,
  announcement,
}

enum TransactionStatus {
  pending,
  paid,
  validated,
  failed,
  refunded,
}

class Transaction {
  final String id;
  final String radioId;
  final String radioName;
  final TransactionType type;
  final double amount;
  final String? announcementId;
  final String? subscriptionId;
  final TransactionStatus status;
  final DateTime createdAt;
  final DateTime? validatedAt;
  final String? validatedBy;
  final String? pdfUrl;

  // Enhanced fields for announcement payments & payer/payee metadata
  final String? initiatorId; // Listener ID
  final String? initiatorName; // Listener name
  final String? initiatorEmail; // Listener email
  final String? receiverRadioId; // Radio ID (receiver)
  final String? receiverRadioName; // Radio name
  final String? paymentMethod; // "MoMo", "OM", "Ecobank", "Card", etc.
  final String? announcementCategory; // "Birthday", "Condolence", "Promotional", etc.
  final int? wordCount; // Number of words in announcement
  final int? durationSeconds; // Duration of the announcement
  final bool isAnnouncement; // true if this is an announcement payment
  final String? finalText; // The final announcement text (for radio admin only, not for sysadmin)

  Transaction({
    required this.id,
    required this.radioId,
    required this.radioName,
    required this.type,
    required this.amount,
    this.announcementId,
    this.subscriptionId,
    required this.status,
    required this.createdAt,
    this.validatedAt,
    this.validatedBy,
    this.pdfUrl,
    this.initiatorId,
    this.initiatorName,
    this.initiatorEmail,
    this.receiverRadioId,
    this.receiverRadioName,
    this.paymentMethod,
    this.announcementCategory,
    this.wordCount,
    this.durationSeconds,
    bool? isAnnouncement,
    this.finalText,
  }) : isAnnouncement = isAnnouncement ?? (type == TransactionType.announcement);

  factory Transaction.fromFirestore(Map<String, dynamic> data, String id) {
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

    final typeStr = (data['type'] ?? 'subscription').toString().toLowerCase();
    final isAnn = data['isAnnouncement'] == true || typeStr.contains('announcement');
    final typeEnum = isAnn ? TransactionType.announcement : TransactionType.subscription;

    final statusStr = (data['status'] ?? 'pending').toString().toLowerCase();
    TransactionStatus statusEnum;
    if (statusStr.contains('paid')) {
      statusEnum = TransactionStatus.paid;
    } else if (statusStr.contains('validated')) {
      statusEnum = TransactionStatus.validated;
    } else if (statusStr.contains('failed')) {
      statusEnum = TransactionStatus.failed;
    } else if (statusStr.contains('refunded')) {
      statusEnum = TransactionStatus.refunded;
    } else {
      statusEnum = TransactionStatus.pending;
    }

    final radioIdVal = data['receiverRadioId'] ?? data['radioId'] ?? '';
    final radioNameVal = data['receiverRadioName'] ?? data['radioName'] ?? 'Unknown Radio';

    return Transaction(
      id: id,
      radioId: radioIdVal,
      radioName: radioNameVal,
      type: typeEnum,
      amount: ((data['amount'] ?? 0.0) as num).toDouble(),
      announcementId: data['announcementId'],
      subscriptionId: data['subscriptionId'],
      status: statusEnum,
      createdAt: parseDate(data['createdAt']),
      validatedAt: parseNullableDate(data['validatedAt']),
      validatedBy: data['validatedBy'],
      pdfUrl: data['pdfUrl'],
      initiatorId: data['initiatorId'],
      initiatorName: data['initiatorName'] ?? (isAnn ? 'Listener' : null),
      initiatorEmail: data['initiatorEmail'],
      receiverRadioId: radioIdVal,
      receiverRadioName: radioNameVal,
      paymentMethod: data['paymentMethod'] ?? (isAnn ? 'MoMo' : 'Credit Card'),
      announcementCategory: data['announcementCategory'],
      wordCount: data['wordCount'] != null ? (data['wordCount'] as num).toInt() : null,
      durationSeconds: data['durationSeconds'] != null ? (data['durationSeconds'] as num).toInt() : null,
      isAnnouncement: isAnn,
      finalText: data['finalText'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'radioId': radioId,
      'radioName': radioName,
      'receiverRadioId': receiverRadioId ?? radioId,
      'receiverRadioName': receiverRadioName ?? radioName,
      'type': isAnnouncement ? 'announcement' : 'subscription',
      'amount': amount,
      'announcementId': announcementId,
      'subscriptionId': subscriptionId,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'validatedAt': validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
      'validatedBy': validatedBy,
      'pdfUrl': pdfUrl,
      'initiatorId': initiatorId,
      'initiatorName': initiatorName,
      'initiatorEmail': initiatorEmail,
      'paymentMethod': paymentMethod,
      'announcementCategory': announcementCategory,
      'wordCount': wordCount,
      'durationSeconds': durationSeconds,
      'isAnnouncement': isAnnouncement,
      'finalText': finalText,
    };
  }

  String get typeLabel {
    switch (type) {
      case TransactionType.subscription:
        return '💰 Subscription';
      case TransactionType.announcement:
        return '📢 Announcement';
    }
  }

  String get statusLabel {
    switch (status) {
      case TransactionStatus.pending:
        return '⏳ Pending';
      case TransactionStatus.paid:
        return '✅ Paid';
      case TransactionStatus.validated:
        return '📄 Validated';
      case TransactionStatus.failed:
        return '❌ Failed';
      case TransactionStatus.refunded:
        return '🔄 Refunded';
    }
  }
}

