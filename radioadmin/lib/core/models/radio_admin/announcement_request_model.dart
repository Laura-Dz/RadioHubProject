import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';
import 'announcement_tariff_model.dart';
import 'announcement_slot_model.dart';

enum AnnouncementRequestStatus {
  pendingPayment,
  pendingValidation,
  validated,
  scheduled,
  rejected,
  broadcasted,
  refunded,
}

class AnnouncementRequest {
  final String id;
  final String radioId;
  final String radioName;

  // Listener
  final String listenerId;
  final String listenerName;
  final String listenerEmail;

  // Content
  final String originalText;
  final String finalText;
  final AnnouncementCategory category;
  final int wordCount;
  final int durationSeconds;

  // Diffusion plan
  final int diffusionsPerDay;
  final int days;
  final DateTime desiredStartDate;

  // Assigned slots (populated on validation)
  final List<AnnouncementSlot> assignedSlots;

  // Pricing
  final double baseAmount;
  final double transferFee;
  final double finalPrice;
  final String currency;

  // Payment
  final String? paymentMethod;
  final String? escrowTransactionId;
  final AnnouncementRequestStatus status;

  // Admin actions
  final String? validatedBy;
  final DateTime? validatedAt;
  final DateTime? scheduledFor;
  final String? rejectionReason;
  final DateTime? rejectedAt;
  final DateTime? refundedAt;

  // Output
  final String? pdfUrl;
  final bool isPrinted;
  final DateTime? printedAt;

  final DateTime createdAt;

  AnnouncementRequest({
    required this.id,
    required this.radioId,
    required this.radioName,
    required this.listenerId,
    required this.listenerName,
    required this.listenerEmail,
    required this.originalText,
    required this.finalText,
    required this.category,
    required this.wordCount,
    required this.durationSeconds,
    required this.diffusionsPerDay,
    required this.days,
    required this.desiredStartDate,
    this.assignedSlots = const [],
    required this.baseAmount,
    required this.transferFee,
    required this.finalPrice,
    this.currency = 'XAF',
    this.paymentMethod,
    this.escrowTransactionId,
    this.status = AnnouncementRequestStatus.pendingPayment,
    this.validatedBy,
    this.validatedAt,
    this.scheduledFor,
    this.rejectionReason,
    this.rejectedAt,
    this.refundedAt,
    this.pdfUrl,
    this.isPrinted = false,
    this.printedAt,
    required this.createdAt,
  });

  factory AnnouncementRequest.fromFirestore(Map<String, dynamic> d, String id) {
    return AnnouncementRequest(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      radioName: (d['radioName'] ?? '').toString(),
      listenerId: (d['listenerId'] ?? '').toString(),
      listenerName: (d['listenerName'] ?? '').toString(),
      listenerEmail: (d['listenerEmail'] ?? '').toString(),
      originalText: (d['originalText'] ?? d['message'] ?? '').toString(),
      finalText: (d['finalText'] ?? d['message'] ?? '').toString(),
      category: AnnouncementCategory.values.firstWhere(
        (e) => e.name == (d['category'] ?? 'general'),
        orElse: () => AnnouncementCategory.general,
      ),
      wordCount: FSParsers.toInt(d['wordCount']),
      durationSeconds: FSParsers.toInt(d['durationSeconds'] ?? d['estimatedDurationSeconds'], fallback: 30),
      diffusionsPerDay: FSParsers.toInt(d['diffusionsPerDay'] ?? d['diffusionCount'], fallback: 1),
      days: FSParsers.toInt(d['days'] ?? d['diffusionPeriodDays'], fallback: 1),
      desiredStartDate: FSParsers.toDate(d['desiredStartDate']) ?? DateTime.now(),
      assignedSlots: (d['assignedSlots'] as List? ?? [])
          .map((s) => AnnouncementSlot.fromJson(s as Map<String, dynamic>))
          .toList(),
      baseAmount: FSParsers.toDouble(d['baseAmount'] ?? d['baseTariff'] ?? d['amount']),
      transferFee: FSParsers.toDouble(d['transferFee']),
      finalPrice: FSParsers.toDouble(d['finalPrice'] ?? d['amount']),
      currency: (d['currency'] ?? 'XAF').toString(),
      paymentMethod: d['paymentMethod']?.toString(),
      escrowTransactionId: d['escrowTransactionId']?.toString(),
      status: AnnouncementRequestStatus.values.firstWhere(
        (e) => e.name == (d['status'] ?? 'pendingValidation'),
        orElse: () => AnnouncementRequestStatus.pendingValidation,
      ),
      validatedBy: d['validatedBy']?.toString(),
      validatedAt: FSParsers.toDate(d['validatedAt']),
      scheduledFor: FSParsers.toDate(d['scheduledFor']),
      rejectionReason: d['rejectionReason']?.toString(),
      rejectedAt: FSParsers.toDate(d['rejectedAt']),
      refundedAt: FSParsers.toDate(d['refundedAt']),
      printedAt: FSParsers.toDate(d['printedAt']),
      createdAt: FSParsers.toDate(d['createdAt']) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'radioId': radioId,
    'radioName': radioName,
    'listenerId': listenerId,
    'listenerName': listenerName,
    'listenerEmail': listenerEmail,
    'originalText': originalText,
    'finalText': finalText,
    'category': category.name,
    'wordCount': wordCount,
    'durationSeconds': durationSeconds,
    'diffusionsPerDay': diffusionsPerDay,
    'days': days,
    'desiredStartDate': Timestamp.fromDate(desiredStartDate),
    'assignedSlots': assignedSlots.map((s) => s.toJson()).toList(),
    'baseAmount': baseAmount,
    'transferFee': transferFee,
    'finalPrice': finalPrice,
    'currency': currency,
    'paymentMethod': paymentMethod,
    'escrowTransactionId': escrowTransactionId,
    'status': status.name,
    'validatedBy': validatedBy,
    'validatedAt': validatedAt != null ? Timestamp.fromDate(validatedAt!) : null,
    'scheduledFor': scheduledFor != null ? Timestamp.fromDate(scheduledFor!) : null,
    'rejectionReason': rejectionReason,
    'rejectedAt': rejectedAt != null ? Timestamp.fromDate(rejectedAt!) : null,
    'refundedAt': refundedAt != null ? Timestamp.fromDate(refundedAt!) : null,
    'pdfUrl': pdfUrl,
    'isPrinted': isPrinted,
    'createdAt': FieldValue.serverTimestamp(),
  };

  String get categoryLabel {
    final n = category.name;
    return n[0].toUpperCase() + n.substring(1);
  }

  String get statusLabel {
    switch (status) {
      case AnnouncementRequestStatus.pendingPayment: return 'Awaiting payment';
      case AnnouncementRequestStatus.pendingValidation: return 'Awaiting validation';
      case AnnouncementRequestStatus.validated: return 'Validated';
      case AnnouncementRequestStatus.scheduled: return 'Scheduled';
      case AnnouncementRequestStatus.rejected: return 'Rejected';
      case AnnouncementRequestStatus.broadcasted: return 'Broadcasted';
      case AnnouncementRequestStatus.refunded: return 'Refunded';
    }
  }

  bool get isPending =>
      status == AnnouncementRequestStatus.pendingValidation ||
      status == AnnouncementRequestStatus.pendingPayment;

  bool get isScheduled => status == AnnouncementRequestStatus.scheduled;
}
