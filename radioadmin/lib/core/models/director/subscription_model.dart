import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

enum SubscriptionTier { free, premium, pro, enterprise }

enum SubscriptionStatus { active, expired, cancelled, pending }

class Subscription {
  final String id;
  final String userId;
  final String userName;
  final String userEmail;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final DateTime startDate;
  final DateTime endDate;
  final double amount;
  final String? paymentMethod;
  final bool autoRenew;
  final DateTime? cancelledAt;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Subscription({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userEmail,
    required this.tier,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.amount,
    this.paymentMethod,
    this.autoRenew = false,
    this.cancelledAt,
    required this.createdAt,
    this.updatedAt,
  });

  factory Subscription.fromFirestore(Map<String, dynamic> data, String id) {
    return Subscription(
      id: id,
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Unknown',
      userEmail: data['userEmail'] ?? '',
      tier: SubscriptionTier.values.firstWhere(
        (e) => e.toString() == data['tier'],
        orElse: () => SubscriptionTier.free,
      ),
      status: SubscriptionStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => SubscriptionStatus.pending,
      ),
      startDate: (data['startDate'] as Timestamp).toDate(),
      endDate: (data['endDate'] as Timestamp).toDate(),
      amount: (data['amount'] ?? 0.0).toDouble(),
      paymentMethod: data['paymentMethod'],
      autoRenew: data['autoRenew'] ?? false,
      cancelledAt: (data['cancelledAt'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'userName': userName,
    'userEmail': userEmail,
    'tier': tier.toString().split('.').last,
    'status': status.toString().split('.').last,
    'startDate': startDate,
    'endDate': endDate,
    'amount': amount,
    'paymentMethod': paymentMethod,
    'autoRenew': autoRenew,
    'cancelledAt': cancelledAt,
    'createdAt': FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  String get tierLabel {
    switch (tier) {
      case SubscriptionTier.free:
        return 'Free';
      case SubscriptionTier.premium:
        return 'Premium';
      case SubscriptionTier.pro:
        return 'Pro';
      case SubscriptionTier.enterprise:
        return 'Enterprise';
    }
  }

  String get statusLabel {
    switch (status) {
      case SubscriptionStatus.active:
        return '🟢 Active';
      case SubscriptionStatus.expired:
        return '🔴 Expired';
      case SubscriptionStatus.cancelled:
        return '⚫ Cancelled';
      case SubscriptionStatus.pending:
        return '🟡 Pending';
    }
  }

  Color get statusColor {
    switch (status) {
      case SubscriptionStatus.active:
        return Colors.green;
      case SubscriptionStatus.expired:
        return Colors.red;
      case SubscriptionStatus.cancelled:
        return Colors.grey;
      case SubscriptionStatus.pending:
        return Colors.orange;
    }
  }

  bool get isExpiringSoon {
    final daysLeft = endDate.difference(DateTime.now()).inDays;
    return daysLeft <= 7 && daysLeft > 0;
  }

  bool get isExpired {
    return endDate.isBefore(DateTime.now());
  }
}
