import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

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

class AnnouncementTariff {
  final String id;
  final String radioId;
  final AnnouncementCategory category;
  /// Price for one 15-second unit of diffusion.
  final double ratePer15SecUnit;
  final bool isActive;
  final DateTime updatedAt;

  AnnouncementTariff({
    required this.id,
    required this.radioId,
    required this.category,
    required this.ratePer15SecUnit,
    this.isActive = true,
    required this.updatedAt,
  });

  factory AnnouncementTariff.fromFirestore(Map<String, dynamic> d, String id) {
    return AnnouncementTariff(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      category: AnnouncementCategory.values.firstWhere(
        (e) => e.name == (d['category'] ?? 'general'),
        orElse: () => AnnouncementCategory.general,
      ),
      ratePer15SecUnit: FSParsers.toDouble(d['ratePer15SecUnit'] ?? d['ratePerSecond']),
      isActive: FSParsers.toBool(d['isActive'], fallback: true),
      updatedAt: FSParsers.toDate(d['updatedAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'category': category.name,
    'ratePer15SecUnit': ratePer15SecUnit,
    'isActive': isActive,
    'updatedAt': FieldValue.serverTimestamp(),
  };

  /// LOCKED FORMULA: final_price = ratePer15SecUnit × diffusionsPerDay × days
  static double calculateFinalPrice({
    required double ratePer15SecUnit,
    required int diffusionsPerDay,
    required int days,
  }) => ratePer15SecUnit * diffusionsPerDay * days;

  static double calculateTransferFee(double base) => base * 0.04;

  static double calculateTotal(double base) => base + calculateTransferFee(base);

  String get categoryLabel {
    final n = category.name;
    return n[0].toUpperCase() + n.substring(1);
  }
}
