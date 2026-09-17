import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementPriority { standard, high, priority }

extension AnnouncementPriorityX on AnnouncementPriority {
  String get label => switch (this) {
        AnnouncementPriority.standard => 'Standard',
        AnnouncementPriority.high => 'High',
        AnnouncementPriority.priority => 'Priority',
      };

  String get description => switch (this) {
        AnnouncementPriority.standard => 'Plays in music and filler slots',
        AnnouncementPriority.high => 'Plays in music and inside shows',
        AnnouncementPriority.priority => 'Plays anywhere, first in line',
      };

  String get key => name;
}

class AnnouncementRequest {
  final String id;
  final String radioId;
  final String radioName;
  final String listenerId;
  final String listenerName;

  final String category;
  final bool isCustomCategory;

  final String originalText;
  final String finalText;

  final AnnouncementPriority priority;
  final int diffusionsPerDay;
  final int days;

  // Computed
  final int wordCount;
  final int units; // 15-second units the announcement occupies
  final double baseAmount; // rate × units × diffusions × days
  final double transferFee; // 4%
  final double finalPrice;

  final String status; // pendingPayment | pendingValidation | ...
  final DateTime createdAt;

  AnnouncementRequest({
    required this.id,
    required this.radioId,
    required this.radioName,
    required this.listenerId,
    required this.listenerName,
    required this.category,
    this.isCustomCategory = false,
    required this.originalText,
    required this.finalText,
    this.priority = AnnouncementPriority.standard,
    required this.diffusionsPerDay,
    required this.days,
    required this.wordCount,
    required this.units,
    required this.baseAmount,
    required this.transferFee,
    required this.finalPrice,
    this.status = 'pendingPayment',
    required this.createdAt,
  });

  factory AnnouncementRequest.fromFirestore(Map<String, dynamic> d, String id) {
    return AnnouncementRequest(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      radioName: (d['radioName'] ?? '').toString(),
      listenerId: (d['listenerId'] ?? '').toString(),
      listenerName: (d['listenerName'] ?? '').toString(),
      category: (d['category'] ?? '').toString(),
      isCustomCategory: d['isCustomCategory'] == true,
      originalText: (d['originalText'] ?? '').toString(),
      finalText: (d['finalText'] ?? '').toString(),
      priority: AnnouncementPriority.values.firstWhere(
        (e) => e.name == d['priority'],
        orElse: () => AnnouncementPriority.standard,
      ),
      diffusionsPerDay: (d['diffusionsPerDay'] ?? 1) as int,
      days: (d['days'] ?? 1) as int,
      wordCount: (d['wordCount'] ?? 0) as int,
      units: (d['units'] ?? 1) as int,
      baseAmount: (d['baseAmount'] ?? 0.0).toDouble(),
      transferFee: (d['transferFee'] ?? 0.0).toDouble(),
      finalPrice: (d['finalPrice'] ?? 0.0).toDouble(),
      status: (d['status'] ?? 'pendingPayment').toString(),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
    );
  }
}
