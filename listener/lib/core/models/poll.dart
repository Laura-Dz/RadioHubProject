import 'package:cloud_firestore/cloud_firestore.dart';

class PollOption {
  final int index;
  final String text;
  PollOption({required this.index, required this.text});
  factory PollOption.fromMap(Map<String, dynamic> m) =>
      PollOption(index: m['index'] ?? 0, text: (m['text'] ?? '').toString());
}

class Poll {
  final String id;
  final String sessionId;
  final String radioId;
  final String question;
  final List<PollOption> options;
  final String status; // active | closed
  final DateTime? closesAt;
  final int totalVotes;
  final Map<String, int> voteCounts;
  final DateTime createdAt;

  Poll({
    required this.id,
    required this.sessionId,
    required this.radioId,
    required this.question,
    required this.options,
    required this.status,
    this.closesAt,
    required this.totalVotes,
    required this.voteCounts,
    required this.createdAt,
  });

  factory Poll.fromFirestore(Map<String, dynamic> d, String id) {
    final optsRaw = (d['options'] as List?) ?? [];
    final countsRaw = (d['voteCounts'] as Map?) ?? {};
    return Poll(
      id: id,
      sessionId: (d['sessionId'] ?? '').toString(),
      radioId: (d['radioId'] ?? '').toString(),
      question: (d['question'] ?? '').toString(),
      options: optsRaw
          .map((o) => PollOption.fromMap(Map<String, dynamic>.from(o)))
          .toList(),
      status: (d['status'] ?? 'active').toString(),
      closesAt: (d['closesAt'] as Timestamp?)?.toDate().toLocal(),
      totalVotes: (d['totalVotes'] ?? 0) as int,
      voteCounts: countsRaw.map((k, v) => MapEntry(k.toString(), (v ?? 0) as int)),
      createdAt: (d['createdAt'] as Timestamp?)?.toDate().toLocal() ?? DateTime.now(),
    );
  }

  Poll copyWith({
    String? id,
    String? sessionId,
    String? radioId,
    String? question,
    List<PollOption>? options,
    String? status,
    DateTime? closesAt,
    int? totalVotes,
    Map<String, int>? voteCounts,
    DateTime? createdAt,
  }) {
    return Poll(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      radioId: radioId ?? this.radioId,
      question: question ?? this.question,
      options: options ?? this.options,
      status: status ?? this.status,
      closesAt: closesAt ?? this.closesAt,
      totalVotes: totalVotes ?? this.totalVotes,
      voteCounts: voteCounts ?? this.voteCounts,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Poll.fromMap(Map<String, dynamic> d, String id) {
    final optsRaw = (d['options'] as List?) ?? [];
    final countsRaw = (d['voteCounts'] as Map?) ?? {};
    DateTime? closesAtDate;
    if (d['closesAt'] is Timestamp) {
      closesAtDate = (d['closesAt'] as Timestamp).toDate().toLocal();
    } else if (d['closesAt'] is int) {
      closesAtDate = DateTime.fromMillisecondsSinceEpoch(d['closesAt'] as int);
    }
    DateTime createdAtDate = DateTime.now();
    if (d['createdAt'] is Timestamp) {
      createdAtDate = (d['createdAt'] as Timestamp).toDate().toLocal();
    } else if (d['createdAt'] is int) {
      createdAtDate = DateTime.fromMillisecondsSinceEpoch(d['createdAt'] as int);
    }

    return Poll(
      id: id,
      sessionId: (d['sessionId'] ?? '').toString(),
      radioId: (d['radioId'] ?? '').toString(),
      question: (d['question'] ?? '').toString(),
      options: optsRaw.map((o) {
        if (o is Map) {
          return PollOption.fromMap(Map<String, dynamic>.from(o));
        }
        return PollOption(index: 0, text: o.toString());
      }).toList(),
      status: (d['status'] ?? 'active').toString(),
      closesAt: closesAtDate,
      totalVotes: (d['totalVotes'] as num?)?.toInt() ?? 0,
      voteCounts: countsRaw.map((k, v) => MapEntry(k.toString(), (v as num?)?.toInt() ?? 0)),
      createdAt: createdAtDate,
    );
  }

  bool get isActive => status == 'active';
  bool get isExpired =>
      closesAt != null && closesAt!.isBefore(DateTime.now());

  int countFor(int index) => voteCounts[index.toString()] ?? 0;

  double pctFor(int index) {
    if (totalVotes == 0) return 0;
    return countFor(index) / totalVotes;
  }
}
