import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

enum SubscriptionStatus { active, expired, suspended, pending }

class Subscription {
  final String id;
  final String radioId;
  final String planName;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double monthlyFee;
  final String currency;
  final List<String> features;
  final bool autoRenew;
  final String? paymentMethod;
  final DateTime? lastPaymentDate;
  final double? lastPaymentAmount;

  Subscription({
    required this.id,
    required this.radioId,
    required this.planName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.monthlyFee,
    this.currency = 'XAF',
    this.features = const [],
    this.autoRenew = false,
    this.paymentMethod,
    this.lastPaymentDate,
    this.lastPaymentAmount,
  });

  bool get isActive => status == SubscriptionStatus.active;
  bool get isExpired => status == SubscriptionStatus.expired || DateTime.now().isAfter(endDate);
  int get daysRemaining => endDate.difference(DateTime.now()).inDays;
  bool get isExpiringSoon => !isExpired && daysRemaining <= 7 && daysRemaining >= 0;

  factory Subscription.fromFirestore(Map<String, dynamic> d, String id) {
    final statusStr = (d['status'] ?? 'active').toString().toLowerCase();
    SubscriptionStatus statusEnum;
    switch (statusStr) {
      case 'expired': statusEnum = SubscriptionStatus.expired; break;
      case 'suspended': statusEnum = SubscriptionStatus.suspended; break;
      case 'pending': statusEnum = SubscriptionStatus.pending; break;
      default: statusEnum = SubscriptionStatus.active;
    }
    return Subscription(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      planName: (d['planName'] ?? d['label'] ?? 'Standard').toString(),
      status: statusEnum,
      startDate: FSParsers.toDate(d['startDate']) ?? DateTime.now(),
      endDate: FSParsers.toDate(d['endDate']) ?? DateTime.now().add(const Duration(days: 30)),
      monthlyFee: FSParsers.toDouble(d['monthlyFee'] ?? d['amount']),
      currency: (d['currency'] ?? 'XAF').toString(),
      features: FSParsers.toStringList(d['features']),
      autoRenew: FSParsers.toBool(d['autoRenew']),
      paymentMethod: d['paymentMethod']?.toString(),
      lastPaymentDate: FSParsers.toDate(d['lastPaymentDate']),
      lastPaymentAmount: d['lastPaymentAmount'] != null ? FSParsers.toDouble(d['lastPaymentAmount']) : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'planName': planName,
    'status': status.name,
    'startDate': Timestamp.fromDate(startDate),
    'endDate': Timestamp.fromDate(endDate),
    'monthlyFee': monthlyFee,
    'currency': currency,
    'features': features,
    'autoRenew': autoRenew,
    'paymentMethod': paymentMethod,
    'lastPaymentDate': lastPaymentDate != null ? Timestamp.fromDate(lastPaymentDate!) : null,
    'lastPaymentAmount': lastPaymentAmount,
    'updatedAt': FieldValue.serverTimestamp(),
  };
}
