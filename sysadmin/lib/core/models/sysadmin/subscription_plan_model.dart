import 'package:cloud_firestore/cloud_firestore.dart';

class SubscriptionPlan {
  final String id;
  final String label;
  final int days;
  final double amount;
  final String currency;
  final bool isActive;
  final List<String> features;
  final String? description;
  final bool isPopular;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  SubscriptionPlan({
    required this.id,
    required this.label,
    required this.days,
    required this.amount,
    this.currency = 'XAF',
    this.isActive = true,
    this.features = const [],
    this.description,
    this.isPopular = false,
    this.createdAt,
    this.updatedAt,
  });

  factory SubscriptionPlan.fromFirestore(Map<String, dynamic> data, String id) {
    DateTime? parseDate(dynamic val) {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is String) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return null;
    }

    return SubscriptionPlan(
      id: id,
      label: data['label'] ?? data['name'] ?? '',
      days: (data['days'] ?? 30) as int,
      amount: ((data['amount'] ?? data['price'] ?? 0.0) as num).toDouble(),
      currency: data['currency'] ?? 'XAF',
      isActive: data['isActive'] ?? true,
      features: List<String>.from(data['features'] ?? []),
      description: data['description'],
      isPopular: data['isPopular'] ?? false,
      createdAt: parseDate(data['createdAt']),
      updatedAt: parseDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'label': label,
      'name': label,
      'days': days,
      'amount': amount,
      'price': amount,
      'currency': currency,
      'isActive': isActive,
      'features': features,
      'description': description,
      'isPopular': isPopular,
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }

  SubscriptionPlan copyWith({
    String? id,
    String? label,
    int? days,
    double? amount,
    String? currency,
    bool? isActive,
    List<String>? features,
    String? description,
    bool? isPopular,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return SubscriptionPlan(
      id: id ?? this.id,
      label: label ?? this.label,
      days: days ?? this.days,
      amount: amount ?? this.amount,
      currency: currency ?? this.currency,
      isActive: isActive ?? this.isActive,
      features: features ?? this.features,
      description: description ?? this.description,
      isPopular: isPopular ?? this.isPopular,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  String get durationLabel {
    if (days == 30) return '1 Month (30 days)';
    if (days == 90) return '3 Months (90 days)';
    if (days == 180) return '6 Months (180 days)';
    if (days == 365) return '1 Year (365 days)';
    return '$days days';
  }

  String get durationFormatted => durationLabel;

  String get formattedPrice {
    final formatted = amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        );
    return '$formatted $currency';
  }

  bool get hasAiInsights =>
      features.any((f) => f.toLowerCase().contains('ai'));
}
