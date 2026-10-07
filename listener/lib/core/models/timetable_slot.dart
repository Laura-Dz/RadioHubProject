class TimetableSlot {
  final String id;
  final String radioId;
  final String programId;
  final String programName;
  final int weekday; // 1 = Monday … 7 = Sunday
  final int startHour;
  final int startMinute;
  final int endHour;
  final int endMinute;
  final List<String> hostNames;
  final bool isActive;

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
    this.hostNames = const [],
    this.isActive = true,
  });

  factory TimetableSlot.fromFirestore(Map<String, dynamic> d, String id) {
    return TimetableSlot(
      id: id,
      radioId: (d['radioId'] ?? '').toString(),
      programId: (d['programId'] ?? '').toString(),
      programName: (d['programName'] ?? '').toString(),
      weekday: (d['weekday'] ?? 1) as int,
      startHour: (d['startHour'] ?? 0) as int,
      startMinute: (d['startMinute'] ?? 0) as int,
      endHour: (d['endHour'] ?? 0) as int,
      endMinute: (d['endMinute'] ?? 0) as int,
      hostNames: List<String>.from(d['hostNames'] ?? []),
      isActive: d['isActive'] != false,
    );
  }

  String get timeRange {
    String fmt(int h, int m) =>
        '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}';
    return '${fmt(startHour, startMinute)}–${fmt(endHour, endMinute)}';
  }

  static const dayNames = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];
  static const dayShort = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
}
