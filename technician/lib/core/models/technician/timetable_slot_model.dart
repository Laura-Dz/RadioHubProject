import 'package:cloud_firestore/cloud_firestore.dart';
import '../../utils/firestore_parsers.dart';

class TimetableSlot {
  final String id;
  final String radioId;
  final String programId;
  final String programName;
  final int weekday;
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final List<String> hostIds;
  final List<String> hostNames;
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TimetableSlot({
    required this.id,
    required this.radioId,
    required this.programId,
    required this.programName,
    required this.weekday,
    required this.startHour,
    this.startMinute = 0,
    required this.endHour,
    this.endMinute = 0,
    List<String> hostIds = const [],
    List<String> hostNames = const [],
    String? defaultHostId,
    String? defaultHostName,
    this.isActive = true,
    required this.createdAt,
    this.updatedAt,
  }) : hostIds = hostIds.isNotEmpty ? hostIds : (defaultHostId != null ? [defaultHostId] : const []),
       hostNames = hostNames.isNotEmpty ? hostNames : (defaultHostName != null ? [defaultHostName] : const []);

  factory TimetableSlot.fromFirestore(Map<String, dynamic> d, String id) {
    List<String> parsedHostIds = [];
    if (d['hostIds'] is List) {
      parsedHostIds = List<String>.from(d['hostIds']);
    } else if (d['defaultHostId'] != null) {
      parsedHostIds = [d['defaultHostId'].toString()];
    }

    List<String> parsedHostNames = [];
    if (d['hostNames'] is List) {
      parsedHostNames = List<String>.from(d['hostNames']);
    } else if (d['defaultHostName'] != null) {
      parsedHostNames = [d['defaultHostName'].toString()];
    }

    return TimetableSlot(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      programId: (d['programId'] ?? '').toString(),
      programName: (d['programName'] ?? '').toString(),
      weekday: FSParsers.toInt(d['weekday'], fallback: 1),
      startHour: FSParsers.toInt(d['startHour']),
      startMinute: FSParsers.toInt(d['startMinute']),
      endHour: FSParsers.toInt(d['endHour']),
      endMinute: FSParsers.toInt(d['endMinute']),
      hostIds: parsedHostIds,
      hostNames: parsedHostNames,
      isActive: d['isActive'] != false,
      createdAt: FSParsers.toDate(d['createdAt']) ?? DateTime.now(),
      updatedAt: FSParsers.toDate(d['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'radioId': radioId,
        'programId': programId,
        'programName': programName,
        'weekday': weekday,
        'startHour': startHour,
        'startMinute': startMinute,
        'endHour': endHour,
        'endMinute': endMinute,
        'hostIds': hostIds,
        'hostNames': hostNames,
        'defaultHostId': defaultHostId,
        'defaultHostName': defaultHostName,
        'isActive': isActive,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  String? get defaultHostId => hostIds.isNotEmpty ? hostIds.first : null;
  String? get defaultHostName => hostNames.isNotEmpty ? hostNames.join(', ') : null;

  String get timeRange =>
      '${startHour.toString().padLeft(2, '0')}:${startMinute.toString().padLeft(2, '0')}'
      '–'
      '${endHour.toString().padLeft(2, '0')}:${endMinute.toString().padLeft(2, '0')}';

  /// Compute the actual DateTime for this slot on the given calendar day.
  DateTime dateFor(DateTime day) =>
      DateTime(day.year, day.month, day.day, startHour, startMinute);

  DateTime endDateFor(DateTime day) =>
      DateTime(day.year, day.month, day.day, endHour, endMinute);

  static const dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}
