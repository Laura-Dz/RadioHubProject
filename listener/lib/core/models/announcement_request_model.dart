import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementCategory {
  general,
  birthday,
  anniversary,
  congratulations,
  condolence,
  promotional,
  event,
  dedication,
  other,
}

enum AnnouncementStatus {
  pending,
  approved,
  rejected,
  broadcasted,
  cancelled,
}

class AnnouncementRequest {
  final String id;
  final String radioId;
  final String userId;
  final String userName;
  final String message;
  final AnnouncementCategory category;
  final int durationSeconds;
  final double price;
  final AnnouncementStatus status;
  final DateTime? scheduledTime;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? rejectionReason;

  AnnouncementRequest({
    required this.id,
    required this.radioId,
    required this.userId,
    required this.userName,
    required this.message,
    required this.category,
    required this.durationSeconds,
    required this.price,
    required this.status,
    this.scheduledTime,
    required this.createdAt,
    this.processedAt,
    this.rejectionReason,
  });

  factory AnnouncementRequest.fromFirestore(Map<String, dynamic> data, String id) {
    return AnnouncementRequest(
      id: id,
      radioId: data['radioId'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      message: data['message'] ?? '',
      category: AnnouncementCategory.values.firstWhere(
        (e) => e.toString() == data['category'],
        orElse: () => AnnouncementCategory.general,
      ),
      durationSeconds: data['durationSeconds'] ?? 30,
      price: (data['price'] ?? 0.0).toDouble(),
      status: AnnouncementStatus.values.firstWhere(
        (e) => e.toString() == data['status'],
        orElse: () => AnnouncementStatus.pending,
      ),
      scheduledTime: (data['scheduledTime'] as Timestamp?)?.toDate(),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      processedAt: (data['processedAt'] as Timestamp?)?.toDate(),
      rejectionReason: data['rejectionReason'],
    );
  }

  String get durationDisplay {
    final minutes = durationSeconds ~/ 60;
    final seconds = durationSeconds % 60;
    if (minutes > 0) return '${minutes}m${seconds}s';
    return '${seconds}s';
  }

  String get categoryLabel {
    switch (category) {
      case AnnouncementCategory.general:
        return 'General';
      case AnnouncementCategory.birthday:
        return '🎂 Birthday';
      case AnnouncementCategory.anniversary:
        return '💍 Anniversary';
      case AnnouncementCategory.congratulations:
        return '🎉 Congratulations';
      case AnnouncementCategory.condolence:
        return '🕊️ Condolence';
      case AnnouncementCategory.promotional:
        return '📢 Promotional';
      case AnnouncementCategory.event:
        return '📅 Event';
      case AnnouncementCategory.dedication:
        return '❤️ Dedication';
      case AnnouncementCategory.other:
        return 'Other';
    }
  }
}

class AnnouncementPricing {
  final String id;
  final String radioId;
  final Map<AnnouncementCategory, List<PriceTier>> pricingTiers;
  final DateTime updatedAt;
  final bool isActive;

  AnnouncementPricing({
    required this.id,
    required this.radioId,
    required this.pricingTiers,
    required this.updatedAt,
    this.isActive = true,
  });

  factory AnnouncementPricing.fromFirestore(Map<String, dynamic> data, String id) {
    final pricingMap = <AnnouncementCategory, List<PriceTier>>{};
    final dataMap = data['pricingTiers'] as Map<String, dynamic>? ?? {};
    for (final entry in dataMap.entries) {
      final category = AnnouncementCategory.values.firstWhere(
        (e) => e.toString() == entry.key,
        orElse: () => AnnouncementCategory.general,
      );
      final tiers = (entry.value as List)
          .map((tier) => PriceTier.fromJson(tier))
          .toList();
      pricingMap[category] = tiers;
    }
    return AnnouncementPricing(
      id: id,
      radioId: data['radioId'] ?? '',
      pricingTiers: pricingMap,
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      isActive: data['isActive'] ?? true,
    );
  }

  PriceTier? getPriceTier(AnnouncementCategory category, int durationSeconds) {
    final tiers = pricingTiers[category] ?? pricingTiers[AnnouncementCategory.general];
    if (tiers == null || tiers.isEmpty) return null;
    PriceTier? selected;
    for (final tier in tiers) {
      if (durationSeconds <= tier.maxDurationSeconds) {
        if (selected == null || tier.price < selected.price) {
          selected = tier;
        }
      }
    }
    return selected ?? tiers.last;
  }
}

class PriceTier {
  final int minDurationSeconds;
  final int maxDurationSeconds;
  final double price;
  final String? label;

  PriceTier({
    required this.minDurationSeconds,
    required this.maxDurationSeconds,
    required this.price,
    this.label,
  });

  factory PriceTier.fromJson(Map<String, dynamic> json) {
    return PriceTier(
      minDurationSeconds: json['minDurationSeconds'] ?? 0,
      maxDurationSeconds: json['maxDurationSeconds'] ?? 30,
      price: (json['price'] ?? 0.0).toDouble(),
      label: json['label'],
    );
  }

  Map<String, dynamic> toJson() => {
    'minDurationSeconds': minDurationSeconds,
    'maxDurationSeconds': maxDurationSeconds,
    'price': price,
    'label': label,
  };
}
