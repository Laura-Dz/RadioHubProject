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

  double get multiplier => switch (this) {
        AnnouncementPriority.standard => 1.0,
        AnnouncementPriority.high => 1.5,
        AnnouncementPriority.priority => 2.0,
      };
}

class AnnouncementSlot {
  final DateTime date;
  final DateTime startTime;
  final int durationSeconds;
  /// 'between' = slot between shows | 'within' = inside announcement-friendly show
  final String slotType;
  final String? showId;
  final String? showName;
  final bool isAired;
  final DateTime? airedAt;

  AnnouncementSlot({
    required this.date,
    required this.startTime,
    this.durationSeconds = 15,
    required this.slotType,
    this.showId,
    this.showName,
    this.isAired = false,
    this.airedAt,
  });

  factory AnnouncementSlot.fromJson(Map<String, dynamic> j) {
    DateTime parseTime(dynamic val) {
      if (val is Timestamp) return val.toDate().toLocal();
      if (val is DateTime) return val.toLocal();
      if (val is String) return DateTime.tryParse(val)?.toLocal() ?? DateTime.now();
      return DateTime.now();
    }

    return AnnouncementSlot(
      date: parseTime(j['date'] ?? j['startTime']),
      startTime: parseTime(j['startTime'] ?? j['date']),
      durationSeconds: (j['durationSeconds'] ?? 15) as int,
      slotType: (j['slotType'] ?? 'between').toString(),
      showId: j['showId']?.toString(),
      showName: j['showName']?.toString(),
      isAired: j['isAired'] == true,
      airedAt: j['airedAt'] != null ? parseTime(j['airedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'startTime': startTime.toIso8601String(),
    'durationSeconds': durationSeconds,
    'slotType': slotType,
    'showId': showId,
    'showName': showName,
    'isAired': isAired,
    'airedAt': airedAt?.toIso8601String(),
  };

  String get timeLabel =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

  String get dateLabel => '${startTime.day}/${startTime.month}/${startTime.year}';

  bool get isWithinShow => slotType == 'within';
  bool get isBetweenShows => slotType == 'between';
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

  final String status; // pendingPayment | inEscrow | pendingValidation | scheduled | validated | broadcasted | rejected | refunded
  final DateTime createdAt;

  // Validation & Airing Details
  final DateTime? scheduledFor;
  final DateTime? validatedAt;
  final String? validatedBy;
  final DateTime? airedAt;
  final String? airedBy;
  final String? rejectionReason;
  final List<AnnouncementSlot> assignedSlots;

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
    this.scheduledFor,
    this.validatedAt,
    this.validatedBy,
    this.airedAt,
    this.airedBy,
    this.rejectionReason,
    this.assignedSlots = const [],
  });

  factory AnnouncementRequest.fromFirestore(Map<String, dynamic> d, String id) {
    DateTime? parseDate(dynamic val) {
      if (val == null) return null;
      if (val is Timestamp) return val.toDate().toLocal();
      if (val is DateTime) return val.toLocal();
      if (val is String) return DateTime.tryParse(val)?.toLocal();
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val).toLocal();
      return null;
    }

    double parseDouble(dynamic val, [double def = 0.0]) {
      if (val == null) return def;
      if (val is num) return val.toDouble();
      if (val is String) return double.tryParse(val) ?? def;
      return def;
    }

    int parseInt(dynamic val, [int def = 1]) {
      if (val == null) return def;
      if (val is num) return val.toInt();
      if (val is String) return int.tryParse(val) ?? def;
      return def;
    }

    final rawSlots = d['assignedSlots'];
    final List<AnnouncementSlot> slots = [];
    if (rawSlots is List) {
      for (final s in rawSlots) {
        if (s is Map) {
          try {
            slots.add(AnnouncementSlot.fromJson(Map<String, dynamic>.from(s)));
          } catch (_) {}
        }
      }
    }

    // Flexible extraction for message
    final original = (d['originalText'] ?? d['message'] ?? d['content'] ?? d['body'] ?? d['text'] ?? '').toString();
    final improved = (d['finalText'] ?? d['improvedText'] ?? original).toString();

    // Flexible extraction for price
    final base = parseDouble(d['baseAmount'] ?? d['baseTariff'] ?? d['price'] ?? d['amount']);
    final fee = parseDouble(d['transferFee'], base * 0.04);
    final total = parseDouble(d['finalPrice'] ?? d['totalAmount'] ?? d['totalPrice'] ?? d['amount'], base + fee);

    // Flexible extraction for priority
    final priorityStr = (d['priority'] ?? 'standard').toString().toLowerCase();
    AnnouncementPriority prio = AnnouncementPriority.standard;
    if (priorityStr.contains('high')) {
      prio = AnnouncementPriority.high;
    } else if (priorityStr.contains('priority')) {
      prio = AnnouncementPriority.priority;
    }

    // Flexible extraction for date
    final created = parseDate(d['createdAt']) ??
        parseDate(d['timestamp']) ??
        parseDate(d['date']) ??
        parseDate(d['startDate']) ??
        parseDate(d['desiredStartDate']) ??
        DateTime.now();

    return AnnouncementRequest(
      id: id,
      radioId: (d['radioId'] ?? d['stationId'] ?? '').toString(),
      radioName: (d['radioName'] ?? d['stationName'] ?? d['station'] ?? d['radio'] ?? '').toString(),
      listenerId: (d['listenerId'] ?? d['userId'] ?? '').toString(),
      listenerName: (d['listenerName'] ?? d['userName'] ?? 'Listener').toString(),
      category: (d['category'] ?? 'General').toString(),
      isCustomCategory: d['isCustomCategory'] == true,
      originalText: original,
      finalText: improved,
      priority: prio,
      diffusionsPerDay: parseInt(d['diffusionsPerDay'] ?? d['diffusions_per_day'], 1),
      days: parseInt(d['days'] ?? d['diffusionPeriodDays'] ?? d['diffusion_period_days'], 1),
      wordCount: parseInt(d['wordCount'] ?? d['word_count'], improved.isNotEmpty ? improved.split(RegExp(r'\s+')).where((w) => w.isNotEmpty).length : 0),
      units: parseInt(d['units'], 1),
      baseAmount: base,
      transferFee: fee,
      finalPrice: total > 0 ? total : (base + fee),
      status: (d['status'] ?? d['state'] ?? 'pending').toString(),
      createdAt: created,
      scheduledFor: parseDate(d['scheduledFor']) ?? parseDate(d['desiredStartDate']),
      validatedAt: parseDate(d['validatedAt']),
      validatedBy: d['validatedBy']?.toString(),
      airedAt: parseDate(d['airedAt']),
      airedBy: d['airedBy']?.toString(),
      rejectionReason: (d['rejectionReason'] ?? d['reason'])?.toString(),
      assignedSlots: slots,
    );
  }

  /// Primary message text (finalText if available, otherwise originalText)
  String get message => finalText.isNotEmpty ? finalText : originalText;

  /// Station / Radio display name
  String get station => radioName.isNotEmpty ? radioName : 'Radio Station';

  /// Effective total price (finalPrice if > 0, otherwise baseAmount)
  double get price => finalPrice > 0 ? finalPrice : (baseAmount > 0 ? baseAmount : 0.0);

  /// Primary display date (scheduledFor or validatedAt or createdAt)
  DateTime get date => scheduledFor ?? validatedAt ?? createdAt;

  /// Formatted price label
  String get formattedPrice => '${price.toStringAsFixed(0)} XAF';

  /// Human-readable status label
  String get statusLabel {
    if (isValidated) return 'Scheduled / Airing';
    if (isBroadcasted) return 'Aired';
    if (isRejected) return 'Rejected';
    if (isPendingValidation) return 'Awaiting validation';
    if (isPendingPayment) return 'Pending payment';
    return status.isNotEmpty ? (status[0].toUpperCase() + status.substring(1)) : 'Pending';
  }

  bool get isValidated {
    final s = status.toLowerCase();
    return s == 'validated' || s == 'scheduled' || s == 'printed' || s == 'approved';
  }

  bool get isBroadcasted {
    final s = status.toLowerCase();
    return s == 'broadcasted' || s == 'aired' || s == 'completed';
  }

  bool get isPendingValidation {
    final s = status.toLowerCase();
    return s == 'pendingvalidation' ||
        s == 'inescrow' ||
        s == 'in_escrow' ||
        s == 'held' ||
        s == 'pending';
  }

  bool get isRejected {
    final s = status.toLowerCase();
    return s == 'rejected' || s == 'declined' || s == 'cancelled';
  }

  bool get isPendingPayment {
    final s = status.toLowerCase();
    return s == 'pendingpayment' || s == 'unpaid';
  }

  /// Returns the next upcoming slot or the earliest slot
  AnnouncementSlot? get nextAiringSlot {
    if (assignedSlots.isEmpty) return null;
    final now = DateTime.now();
    // find first slot in future
    for (final s in assignedSlots) {
      if (s.startTime.isAfter(now)) return s;
    }
    // fallback to first slot
    return assignedSlots.first;
  }

  /// Summary of scheduled airing time
  String get airingTimeSummary {
    if (assignedSlots.isNotEmpty) {
      final next = nextAiringSlot!;
      final prefix = next.isWithinShow
          ? 'Live read during "${next.showName ?? "Show"}"'
          : 'Break / Intermediary slot';
      return '${next.dateLabel} at ${next.timeLabel} ($prefix)';
    }
    if (scheduledFor != null) {
      return '${scheduledFor!.day}/${scheduledFor!.month}/${scheduledFor!.year} at ${scheduledFor!.hour.toString().padLeft(2, '0')}:${scheduledFor!.minute.toString().padLeft(2, '0')}';
    }
    return 'Slot scheduling in progress';
  }
}
