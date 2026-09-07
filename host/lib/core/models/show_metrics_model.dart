class ShowMetrics {
  final String programId;
  final int listenerCount;
  final int peakListeners;
  final double engagementRate;
  final String duration;
  final int commentsCount;
  final int callsCount;
  final double rating;

  ShowMetrics({
    required this.programId,
    required this.listenerCount,
    required this.peakListeners,
    required this.engagementRate,
    required this.duration,
    required this.commentsCount,
    required this.callsCount,
    required this.rating,
  });

  factory ShowMetrics.empty() {
    return ShowMetrics(
      programId: '',
      listenerCount: 0,
      peakListeners: 0,
      engagementRate: 0.0,
      duration: '0h 0m',
      commentsCount: 0,
      callsCount: 0,
      rating: 0.0,
    );
  }

  factory ShowMetrics.fromFirestore(Map<String, dynamic> data, String id) {
    return ShowMetrics(
      programId: id,
      listenerCount: data['listenerCount'] ?? 0,
      peakListeners: data['peakListeners'] ?? 0,
      engagementRate: (data['engagementRate'] as num?)?.toDouble() ?? 0.0,
      duration: data['duration'] ?? '0h 0m',
      commentsCount: data['commentsCount'] ?? 0,
      callsCount: data['callsCount'] ?? 0,
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
