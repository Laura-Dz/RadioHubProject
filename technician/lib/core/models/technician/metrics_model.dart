import 'package:cloud_firestore/cloud_firestore.dart';

class RadioMetrics {
  // Audimat
  final int totalListeners;
  final int peakListeners;
  final int avgListeners;
  final double growthPercent;

  // Interactions
  final int totalComments;
  final int totalCalls;
  final int totalLikes;
  final int totalShares;
  final int totalInteractions;
  final double interactionsPerListener;

  // Time series
  final List<ListenerPoint> trend;
  final List<HourPoint> byHour;
  final List<DayPoint> byDay;

  // Per-program
  final List<ProgramPerformance> byProgram;

  // Top sessions
  final List<SessionPerformance> topByAudience;
  final List<SessionPerformance> topByInteraction;

  RadioMetrics({
    this.totalListeners = 0,
    this.peakListeners = 0,
    this.avgListeners = 0,
    this.growthPercent = 0.0,
    this.totalComments = 0,
    this.totalCalls = 0,
    this.totalLikes = 0,
    this.totalShares = 0,
    this.totalInteractions = 0,
    this.interactionsPerListener = 0.0,
    this.trend = const [],
    this.byHour = const [],
    this.byDay = const [],
    this.byProgram = const [],
    this.topByAudience = const [],
    this.topByInteraction = const [],
  });
}

class ListenerPoint {
  final DateTime time;
  final int count;
  final int comments;
  final int calls;
  ListenerPoint(this.time, this.count, {this.comments = 0, this.calls = 0});
}

class HourPoint {
  final String label;
  final int avgListeners;
  HourPoint(this.label, this.avgListeners);
}

class DayPoint {
  final String label;
  final int totalListeners;
  DayPoint(this.label, this.totalListeners);
}

class ProgramPerformance {
  final String programName;
  final int avgListeners;
  final int peakListeners;
  final int totalSessions;
  final int totalInteractions;
  final double avgRetention;
  ProgramPerformance({
    required this.programName,
    required this.avgListeners,
    required this.peakListeners,
    required this.totalSessions,
    required this.totalInteractions,
    required this.avgRetention,
  });

  double get interactionsPerListener =>
      avgListeners == 0 ? 0 : totalInteractions / (avgListeners * totalSessions);
}

class SessionPerformance {
  final String id;
  final String programName;
  final DateTime start;
  final int peakListeners;
  final int avgListeners;
  final int comments;
  final int calls;
  final int likes;
  final int shares;
  final double retention;
  SessionPerformance({
    required this.id,
    required this.programName,
    required this.start,
    required this.peakListeners,
    required this.avgListeners,
    required this.comments,
    required this.calls,
    required this.likes,
    required this.shares,
    required this.retention,
  });

  int get totalInteractions => comments + calls + likes + shares;
}

/// Live session snapshot — updated in real time.
class LiveMetrics {
  final String sessionId;
  final int currentListeners;
  final int peakListeners;
  final int comments;
  final int calls;
  final int likes;
  final int shares;
  final DateTime since;
  final List<ListenerPoint> recentTrend; // last N minutes
  final int waitingCalls;
  final int acceptedCalls;
  final int rejectedCalls;
  final double avgListenDurationSeconds;
  final Map<String, int> listenersByRegion;
  final DateTime? updatedAt;

  LiveMetrics({
    this.sessionId = '',
    this.currentListeners = 0,
    this.peakListeners = 0,
    int? comments,
    int? totalComments,
    int? calls,
    int? totalCalls,
    this.likes = 0,
    this.shares = 0,
    DateTime? since,
    this.recentTrend = const [],
    this.waitingCalls = 0,
    this.acceptedCalls = 0,
    this.rejectedCalls = 0,
    this.avgListenDurationSeconds = 0.0,
    this.listenersByRegion = const {},
    this.updatedAt,
  })  : comments = comments ?? totalComments ?? 0,
        calls = calls ?? totalCalls ?? 0,
        since = since ?? DateTime.fromMillisecondsSinceEpoch(0);

  int get totalInteractions => comments + calls + likes + shares;
  double get interactionsPerListener =>
      currentListeners == 0 ? 0 : totalInteractions / currentListeners;

  int get totalComments => comments;
  int get totalCalls => calls;

  Map<String, dynamic> toFirestore() => {
        'sessionId': sessionId,
        'currentListeners': currentListeners,
        'peakListeners': peakListeners,
        'comments': comments,
        'calls': calls,
        'likes': likes,
        'shares': shares,
        'waitingCalls': waitingCalls,
        'acceptedCalls': acceptedCalls,
        'rejectedCalls': rejectedCalls,
        'avgListenDurationSeconds': avgListenDurationSeconds,
        'listenersByRegion': listenersByRegion,
        'since': Timestamp.fromDate(since),
        'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
      };
}
