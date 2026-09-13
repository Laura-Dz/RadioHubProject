import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

enum RecurrenceType { none, daily, weekdays, weekends, weekly }

extension RecurrenceTypeX on RecurrenceType {
  String get label => switch (this) {
        RecurrenceType.none => 'No auto-schedule',
        RecurrenceType.daily => 'Every day',
        RecurrenceType.weekdays => 'Weekdays (Mon–Fri)',
        RecurrenceType.weekends => 'Weekends (Sat–Sun)',
        RecurrenceType.weekly => 'Weekly (pick days)',
      };

  /// Returns 1..7 weekday numbers for the pattern.
  List<int> resolveDays(List<int> custom) {
    switch (this) {
      case RecurrenceType.none:
        return [];
      case RecurrenceType.daily:
        return [1, 2, 3, 4, 5, 6, 7];
      case RecurrenceType.weekdays:
        return [1, 2, 3, 4, 5];
      case RecurrenceType.weekends:
        return [6, 7];
      case RecurrenceType.weekly:
        return custom;
    }
  }
}

class Program {
  final String id;
  final String radioId;
  final String name;
  final String description;
  final List<String> categories;
  final int defaultDurationMinutes;
  final List<String> hostIds;
  final List<String> hostNames;
  final bool allowsCalls;
  final bool allowsComments;
  final bool isActive;
  final String? imageUrl;
  final RecurrenceType recurrenceType;
  final List<int> recurrenceDays; // 1..7, only used for weekly
  final int? defaultStartHour; // 0..23
  final int? defaultStartMinute; // 0..59
  final DateTime createdAt;
  final DateTime? updatedAt;

  Program({
    required this.id,
    required this.radioId,
    required this.name,
    required this.description,
    List<String>? categories,
    String? category,
    this.defaultDurationMinutes = 60,
    this.hostIds = const [],
    this.hostNames = const [],
    this.allowsCalls = true,
    this.allowsComments = true,
    this.isActive = true,
    this.imageUrl,
    this.recurrenceType = RecurrenceType.none,
    this.recurrenceDays = const [],
    this.defaultStartHour,
    this.defaultStartMinute,
    required this.createdAt,
    this.updatedAt,
  }) : categories = categories ??
            (category != null && category.isNotEmpty ? [category] : const []);

  factory Program.fromFirestore(Map<String, dynamic> d, String id) {
    List<String> parsedCategories = [];
    if (d['categories'] is List) {
      parsedCategories = List<String>.from(d['categories']);
    } else if (d['category'] != null && d['category'].toString().isNotEmpty) {
      parsedCategories = [d['category'].toString()];
    }

    return Program(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      name: (d['name'] ?? '').toString(),
      description: (d['description'] ?? '').toString(),
      categories: parsedCategories,
      defaultDurationMinutes:
          FSParsers.toInt(d['defaultDurationMinutes'], fallback: 60),
      hostIds: List<String>.from(d['hostIds'] ?? []),
      hostNames: List<String>.from(d['hostNames'] ?? []),
      allowsCalls: d['allowsCalls'] != false,
      allowsComments: d['allowsComments'] != false,
      isActive: d['isActive'] != false,
      imageUrl: d['imageUrl']?.toString(),
      recurrenceType: RecurrenceType.values.firstWhere(
        (e) => e.toString() == 'RecurrenceType.${d['recurrenceType']}',
        orElse: () => RecurrenceType.none,
      ),
      recurrenceDays: List<int>.from(d['recurrenceDays'] ?? []),
      defaultStartHour: d['defaultStartHour'] != null
          ? FSParsers.toInt(d['defaultStartHour'])
          : null,
      defaultStartMinute: d['defaultStartMinute'] != null
          ? FSParsers.toInt(d['defaultStartMinute'])
          : null,
      createdAt: FSParsers.toDate(d['createdAt']) ?? DateTime.now(),
      updatedAt: FSParsers.toDate(d['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'radioId': radioId,
        'name': name,
        'description': description,
        'categories': categories,
        'category': primaryCategory,
        'defaultDurationMinutes': defaultDurationMinutes,
        'hostIds': hostIds,
        'hostNames': hostNames,
        'allowsCalls': allowsCalls,
        'allowsComments': allowsComments,
        'isActive': isActive,
        'imageUrl': imageUrl,
        'recurrenceType': recurrenceType.toString().split('.').last,
        'recurrenceDays': recurrenceDays,
        'defaultStartHour': defaultStartHour,
        'defaultStartMinute': defaultStartMinute,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  String get primaryCategory =>
      categories.isEmpty ? 'General' : categories.first;

  String get categoriesLabel => categories.isEmpty
      ? 'General'
      : categories
          .map((c) =>
              c.isNotEmpty ? c[0].toUpperCase() + c.substring(1) : '')
          .join(' · ');

  String get hostsLabel =>
      hostNames.isEmpty ? 'No hosts' : hostNames.join(', ');

  String get category => primaryCategory;
  String get categoryLabel => categoriesLabel;
}
