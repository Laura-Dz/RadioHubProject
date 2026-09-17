enum MarkType { favouriteProgram, reminder, listenLater }

class UserMark {
  final String id;              // '{uid}_{type}_{targetId}'
  final String userId;
  final MarkType type;
  final String targetId;        // programId or sessionId
  final String radioId;
  final String? radioName;
  final String? targetName;     // cached label for display
  final DateTime? reminderAt;   // only for reminders
  final DateTime createdAt;

  UserMark({
    required this.id,
    required this.userId,
    required this.type,
    required this.targetId,
    required this.radioId,
    this.radioName,
    this.targetName,
    this.reminderAt,
    required this.createdAt,
  });

  static String buildId(String uid, MarkType t, String targetId) =>
      '${uid}_${t.name}_$targetId';
}
