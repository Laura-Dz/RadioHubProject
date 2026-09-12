import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

class ProgramCategory {
  final String id;
  final String radioId;
  final String name;
  final bool isCustom;
  final DateTime createdAt;

  ProgramCategory({
    required this.id,
    required this.radioId,
    required this.name,
    this.isCustom = false,
    required this.createdAt,
  });

  factory ProgramCategory.fromFirestore(Map<String, dynamic> d, String id) =>
      ProgramCategory(
        id: id,
        radioId: (d['radioId'] ?? '').toString(),
        name: (d['name'] ?? '').toString(),
        isCustom: d['isCustom'] == true,
        createdAt: FSParsers.toDate(d['createdAt']) ?? DateTime.now(),
      );

  Map<String, dynamic> toFirestore() => {
        'radioId': radioId,
        'name': name,
        'isCustom': isCustom,
        'createdAt': FieldValue.serverTimestamp(),
      };

  static const defaultNames = [
    'music', 'talk', 'news', 'sports', 'comedy',
    'education', 'entertainment', 'religious', 'general',
  ];
}
