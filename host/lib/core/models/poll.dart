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

  static Map<String, int> _parseVoteCounts(dynamic raw) {
    final Map<String, int> result = {};
    if (raw is Map) {
      raw.forEach((k, v) {
        result[k.toString()] = (v as num?)?.toInt() ?? 0;
      });
    } else if (raw is List) {
      for (int i = 0; i < raw.length; i++) {
        result[i.toString()] = (raw[i] as num?)?.toInt() ?? 0;
      }
    }
    return result;
  }

  static List<PollOption> _parseOptions(dynamic raw) {
    if (raw is List) {
      return raw.map((o) {
        if (o is Map) {
          return PollOption.fromMap(Map<String, dynamic>.from(o));
        }
        return PollOption(index: 0, text: o.toString());
      }).toList();
    } else if (raw is Map) {
      final list = <PollOption>[];
      raw.forEach((k, v) {
        final idx = int.tryParse(k.toString()) ?? 0;
        if (v is Map) {
          list.add(PollOption.fromMap(Map<String, dynamic>.from(v)));
        } else {
          list.add(PollOption(index: idx, text: v.toString()));
        }
      });
      list.sort((a, b) => a.index.compareTo(b.index));
      return list;
    }
    return [];
  }

  static DateTime? _parseDate(dynamic val) {
    if (val == null) return null;
    if (val is Timestamp) return val.toDate().toLocal();
    if (val is num) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
    if (val is String) return DateTime.tryParse(val);
    return null;
  }

  factory Poll.fromFirestore(Map<String, dynamic> d, String id) {
    return Poll(
      id: id,
      sessionId: (d['sessionId'] ?? '').toString(),
      radioId: (d['radioId'] ?? '').toString(),
      question: (d['question'] ?? '').toString(),
      options: _parseOptions(d['options']),
      status: (d['status'] ?? 'active').toString(),
      closesAt: _parseDate(d['closesAt']),
      totalVotes: (d['totalVotes'] as num?)?.toInt() ?? 0,
      voteCounts: _parseVoteCounts(d['voteCounts']),
      createdAt: _parseDate(d['createdAt']) ?? DateTime.now(),
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
    return Poll(
      id: id,
      sessionId: (d['sessionId'] ?? '').toString(),
      radioId: (d['radioId'] ?? '').toString(),
      question: (d['question'] ?? '').toString(),
      options: _parseOptions(d['options']),
      status: (d['status'] ?? 'active').toString(),
      closesAt: _parseDate(d['closesAt']),
      totalVotes: (d['totalVotes'] as num?)?.toInt() ?? 0,
      voteCounts: _parseVoteCounts(d['voteCounts']),
      createdAt: _parseDate(d['createdAt']) ?? DateTime.now(),
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
