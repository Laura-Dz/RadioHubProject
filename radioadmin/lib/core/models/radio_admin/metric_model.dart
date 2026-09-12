import 'package:cloud_firestore/cloud_firestore.dart';

class RadioMetrics {
  final int totalPrograms;
  final int activePrograms;
  final int totalHosts;
  final int activeHosts;
  final int totalSessions;
  final int liveSessions;
  final int pastSessions;
  final int totalListeners;
  final int avgListeners;
  final int totalMedia;
  final double avgRating;
  final double revenue;
  final double revenueGrowth;
  final DateTime timestamp;

  RadioMetrics({
    required this.totalPrograms,
    required this.activePrograms,
    required this.totalHosts,
    required this.activeHosts,
    required this.totalSessions,
    required this.liveSessions,
    required this.pastSessions,
    required this.totalListeners,
    required this.avgListeners,
    required this.totalMedia,
    required this.avgRating,
    required this.revenue,
    required this.revenueGrowth,
    required this.timestamp,
  });

  factory RadioMetrics.fromFirestore(Map<String, dynamic> data, String id) {
    return RadioMetrics(
      totalPrograms: data['totalPrograms'] ?? 0,
      activePrograms: data['activePrograms'] ?? 0,
      totalHosts: data['totalHosts'] ?? 0,
      activeHosts: data['activeHosts'] ?? 0,
      totalSessions: data['totalSessions'] ?? 0,
      liveSessions: data['liveSessions'] ?? 0,
      pastSessions: data['pastSessions'] ?? 0,
      totalListeners: data['totalListeners'] ?? 0,
      avgListeners: data['avgListeners'] ?? 0,
      totalMedia: data['totalMedia'] ?? 0,
      avgRating: (data['avgRating'] ?? 0.0).toDouble(),
      revenue: (data['revenue'] ?? 0.0).toDouble(),
      revenueGrowth: (data['revenueGrowth'] ?? 0.0).toDouble(),
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'totalPrograms': totalPrograms,
    'activePrograms': activePrograms,
    'totalHosts': totalHosts,
    'activeHosts': activeHosts,
    'totalSessions': totalSessions,
    'liveSessions': liveSessions,
    'pastSessions': pastSessions,
    'totalListeners': totalListeners,
    'avgListeners': avgListeners,
    'totalMedia': totalMedia,
    'avgRating': avgRating,
    'revenue': revenue,
    'revenueGrowth': revenueGrowth,
    'timestamp': FieldValue.serverTimestamp(),
  };
}