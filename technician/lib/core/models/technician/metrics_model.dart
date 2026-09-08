import 'package:cloud_firestore/cloud_firestore.dart';

class LiveMetrics {
  final String sessionId;
  final int currentListeners;
  final int peakListeners;
  final int totalComments;
  final int totalCalls;
  final int waitingCalls;
  final int acceptedCalls;
  final int rejectedCalls;
  final double? avgListenDurationSeconds;
  final Map<String, int> listenersByRegion;
  final DateTime? updatedAt;

  const LiveMetrics({
    required this.sessionId,
    this.currentListeners = 0,
    this.peakListeners = 0,
    this.totalComments = 0,
    this.totalCalls = 0,
    this.waitingCalls = 0,
    this.acceptedCalls = 0,
    this.rejectedCalls = 0,
    this.avgListenDurationSeconds,
    this.listenersByRegion = const {},
    this.updatedAt,
  });

  factory LiveMetrics.fromFirestore(Map<String, dynamic> data, String sessionId) {
    return LiveMetrics(
      sessionId: sessionId,
      currentListeners: data['currentListeners'] ?? 0,
      peakListeners: data['peakListeners'] ?? 0,
      totalComments: data['totalComments'] ?? 0,
      totalCalls: data['totalCalls'] ?? 0,
      waitingCalls: data['waitingCalls'] ?? 0,
      acceptedCalls: data['acceptedCalls'] ?? 0,
      rejectedCalls: data['rejectedCalls'] ?? 0,
      avgListenDurationSeconds: (data['avgListenDurationSeconds'] is num)
          ? (data['avgListenDurationSeconds'] as num).toDouble()
          : null,
      listenersByRegion: Map<String, int>.from(data['listenersByRegion'] ?? {}),
      updatedAt: (data['updatedAt'] is Timestamp)
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'sessionId': sessionId,
        'currentListeners': currentListeners,
        'peakListeners': peakListeners,
        'totalComments': totalComments,
        'totalCalls': totalCalls,
        'waitingCalls': waitingCalls,
        'acceptedCalls': acceptedCalls,
        'rejectedCalls': rejectedCalls,
        'avgListenDurationSeconds': avgListenDurationSeconds,
        'listenersByRegion': listenersByRegion,
        'updatedAt': FieldValue.serverTimestamp(),
      };

  LiveMetrics copyWith({
    int? currentListeners,
    int? peakListeners,
    int? totalComments,
    int? totalCalls,
    int? waitingCalls,
    int? acceptedCalls,
    int? rejectedCalls,
    double? avgListenDurationSeconds,
    Map<String, int>? listenersByRegion,
    DateTime? updatedAt,
  }) {
    return LiveMetrics(
      sessionId: sessionId,
      currentListeners: currentListeners ?? this.currentListeners,
      peakListeners: peakListeners ?? this.peakListeners,
      totalComments: totalComments ?? this.totalComments,
      totalCalls: totalCalls ?? this.totalCalls,
      waitingCalls: waitingCalls ?? this.waitingCalls,
      acceptedCalls: acceptedCalls ?? this.acceptedCalls,
      rejectedCalls: rejectedCalls ?? this.rejectedCalls,
      avgListenDurationSeconds:
          avgListenDurationSeconds ?? this.avgListenDurationSeconds,
      listenersByRegion: listenersByRegion ?? this.listenersByRegion,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
