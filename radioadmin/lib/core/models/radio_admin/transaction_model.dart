import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

enum RadioTransactionType { announcement, subscription, refund, payout }
enum RadioTransactionStatus { inEscrow, released, refunded, failed, pending }

typedef TransactionType = RadioTransactionType;
typedef TransactionStatus = RadioTransactionStatus;

class RadioTransaction {
  final String id;
  final String radioId;
  final RadioTransactionType type;
  final RadioTransactionStatus status;
  final double baseAmount;
  final double transferFee;
  final double totalAmount;
  final String currency;
  final String? paymentMethod;
  final String? escrowReference;
  final String? announcementId;
  final String? subscriptionId;
  final String? initiatorName;
  final String? initiatorEmail;
  final DateTime createdAt;
  final DateTime? releasedAt;
  final DateTime? refundedAt;

  RadioTransaction({
    required this.id,
    required this.radioId,
    required this.type,
    required this.status,
    required this.baseAmount,
    this.transferFee = 0.0,
    required this.totalAmount,
    this.currency = 'XAF',
    this.paymentMethod,
    this.escrowReference,
    this.announcementId,
    this.subscriptionId,
    this.initiatorName,
    this.initiatorEmail,
    required this.createdAt,
    this.releasedAt,
    this.refundedAt,
  });

  factory RadioTransaction.fromFirestore(Map<String, dynamic> d, String id) {
    final typeStr = (d['type'] ?? 'announcement').toString().toLowerCase();
    RadioTransactionType typeEnum;
    switch (typeStr) {
      case 'subscription': typeEnum = RadioTransactionType.subscription; break;
      case 'refund': typeEnum = RadioTransactionType.refund; break;
      case 'payout': typeEnum = RadioTransactionType.payout; break;
      default: typeEnum = RadioTransactionType.announcement;
    }
    final statusStr = (d['status'] ?? 'pending').toString().toLowerCase();
    RadioTransactionStatus statusEnum;
    switch (statusStr) {
      case 'inescrow': case 'held': statusEnum = RadioTransactionStatus.inEscrow; break;
      case 'released': statusEnum = RadioTransactionStatus.released; break;
      case 'refunded': statusEnum = RadioTransactionStatus.refunded; break;
      case 'failed': statusEnum = RadioTransactionStatus.failed; break;
      default: statusEnum = RadioTransactionStatus.pending;
    }
    return RadioTransaction(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      type: typeEnum,
      status: statusEnum,
      baseAmount: FSParsers.toDouble(d['baseAmount']),
      transferFee: FSParsers.toDouble(d['transferFee']),
      totalAmount: FSParsers.toDouble(d['totalAmount'] ?? d['amount']),
      currency: (d['currency'] ?? 'XAF').toString(),
      paymentMethod: d['paymentMethod']?.toString(),
      escrowReference: d['escrowReference']?.toString(),
      announcementId: d['announcementId']?.toString(),
      subscriptionId: d['subscriptionId']?.toString(),
      initiatorName: (d['initiatorName'] ?? d['listenerName'])?.toString(),
      initiatorEmail: (d['initiatorEmail'] ?? d['listenerEmail'])?.toString(),
      createdAt: FSParsers.toDate(d['createdAt']) ?? DateTime.now(),
      releasedAt: FSParsers.toDate(d['releasedAt']),
      refundedAt: FSParsers.toDate(d['refundedAt']),
    );
  }

  String get typeLabel {
    switch (type) {
      case RadioTransactionType.announcement: return 'Announcement';
      case RadioTransactionType.subscription: return 'Subscription';
      case RadioTransactionType.refund: return 'Refund';
      case RadioTransactionType.payout: return 'Payout';
    }
  }

  String get statusLabel {
    switch (status) {
      case RadioTransactionStatus.inEscrow: return 'In Escrow';
      case RadioTransactionStatus.released: return 'Released';
      case RadioTransactionStatus.refunded: return 'Refunded';
      case RadioTransactionStatus.failed: return 'Failed';
      case RadioTransactionStatus.pending: return 'Pending';
    }
  }
}
