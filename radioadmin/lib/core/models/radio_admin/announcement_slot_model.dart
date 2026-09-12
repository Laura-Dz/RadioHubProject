class AnnouncementSlot {
  final DateTime date;
  final DateTime startTime;
  final int durationSeconds;
  /// 'between' = slot between shows | 'within' = inside announcement_friendly show
  final String slotType;
  final String? showId;
  final String? showName;

  AnnouncementSlot({
    required this.date,
    required this.startTime,
    required this.durationSeconds,
    required this.slotType,
    this.showId,
    this.showName,
  });

  factory AnnouncementSlot.fromJson(Map<String, dynamic> j) => AnnouncementSlot(
    date: DateTime.parse(j['date']),
    startTime: DateTime.parse(j['startTime']),
    durationSeconds: j['durationSeconds'] ?? 15,
    slotType: j['slotType'] ?? 'between',
    showId: j['showId'],
    showName: j['showName'],
  );

  Map<String, dynamic> toJson() => {
    'date': date.toIso8601String(),
    'startTime': startTime.toIso8601String(),
    'durationSeconds': durationSeconds,
    'slotType': slotType,
    'showId': showId,
    'showName': showName,
  };

  String get timeLabel =>
      '${startTime.hour.toString().padLeft(2, '0')}:${startTime.minute.toString().padLeft(2, '0')}';

  String get dateLabel => '${date.day}/${date.month}';
}
