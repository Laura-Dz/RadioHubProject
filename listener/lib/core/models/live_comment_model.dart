/// A live chat comment from Firebase Realtime Database.
class LiveComment {
  final String id;
  final String userId;
  final String userName;
  final String message;
  final DateTime timestamp;

  const LiveComment({
    required this.id,
    required this.userId,
    required this.userName,
    required this.message,
    required this.timestamp,
  });

  factory LiveComment.fromMap(Map<String, dynamic> map) {
    final tsMs = (map['timestamp'] as num?)?.toInt() ?? 0;
    return LiveComment(
      id: map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      userName: map['userName'] as String? ?? 'Anonymous',
      message: map['message'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(tsMs),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'message': message,
        'timestamp': timestamp.millisecondsSinceEpoch,
      };
}
