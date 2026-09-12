import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlan {
  final String id;
  final String label;
  final int days;
  final double amount;
  final String currency;
  final bool isActive;
  final List<String> features;

  SubscriptionPlan({
    required this.id,
    required this.label,
    required this.days,
    required this.amount,
    this.currency = 'XAF',
    this.isActive = true,
    this.features = const [],
  });

  factory SubscriptionPlan.fromFirestore(Map<String, dynamic> d, String id) => SubscriptionPlan(
    id: id,
    label: d['label'] ?? '',
    days: (d['days'] ?? 30) as int,
    amount: ((d['amount'] ?? 0.0) as num).toDouble(),
    currency: d['currency'] ?? 'XAF',
    isActive: d['isActive'] ?? true,
    features: List<String>.from(d['features'] ?? []),
  );
}

class SubscriptionPlanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Read-only — SysAdmin sets these globally in subscription_plans collection.
  Stream<List<SubscriptionPlan>> streamPlans() {
    return _db
        .collection('subscription_plans')
        .where('isActive', isEqualTo: true)
        .orderBy('days')
        .snapshots()
        .map((s) => s.docs.map((d) => SubscriptionPlan.fromFirestore(d.data(), d.id)).toList());
  }

  /// Fallback plans when Firestore is unavailable
  List<SubscriptionPlan> get fallbackPlans => [
    SubscriptionPlan(id: 'monthly', label: 'Monthly', days: 30, amount: 15000, features: ['Unlimited Announcements', 'HD Streaming', 'Analytics']),
    SubscriptionPlan(id: 'quarterly', label: 'Quarterly', days: 90, amount: 40000, features: ['Unlimited Announcements', 'HD Streaming', 'Analytics', 'AI Insights']),
    SubscriptionPlan(id: 'yearly', label: 'Yearly', days: 365, amount: 140000, features: ['Unlimited Announcements', 'HD Streaming', 'Analytics', 'AI Insights', 'Priority Support']),
  ];
}
