import 'package:cloud_firestore/cloud_firestore.dart';

class DirectorMetrics {
  final int totalListeners;
  final int activeListeners;
  final int totalShows;
  final int activeShows;
  final int totalTechnicians;
  final int activeTechnicians;
  final int totalSubscriptions;
  final int activeSubscriptions;
  final double revenue;
  final double revenueGrowth;
  final double engagementRate;
  final double listenerGrowth;
  final int pendingRequests;
  final int totalRequests;
  final DateTime timestamp;

  DirectorMetrics({
    required this.totalListeners,
    required this.activeListeners,
    required this.totalShows,
    required this.activeShows,
    required this.totalTechnicians,
    required this.activeTechnicians,
    required this.totalSubscriptions,
    required this.activeSubscriptions,
    required this.revenue,
    required this.revenueGrowth,
    required this.engagementRate,
    required this.listenerGrowth,
    required this.pendingRequests,
    required this.totalRequests,
    required this.timestamp,
  });

  factory DirectorMetrics.fromFirestore(Map<String, dynamic> data, String id) {
    return DirectorMetrics(
      totalListeners: data['totalListeners'] ?? 0,
      activeListeners: data['activeListeners'] ?? 0,
      totalShows: data['totalShows'] ?? 0,
      activeShows: data['activeShows'] ?? 0,
      totalTechnicians: data['totalTechnicians'] ?? 0,
      activeTechnicians: data['activeTechnicians'] ?? 0,
      totalSubscriptions: data['totalSubscriptions'] ?? 0,
      activeSubscriptions: data['activeSubscriptions'] ?? 0,
      revenue: (data['revenue'] ?? 0.0).toDouble(),
      revenueGrowth: (data['revenueGrowth'] ?? 0.0).toDouble(),
      engagementRate: (data['engagementRate'] ?? 0.0).toDouble(),
      listenerGrowth: (data['listenerGrowth'] ?? 0.0).toDouble(),
      pendingRequests: data['pendingRequests'] ?? 0,
      totalRequests: data['totalRequests'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'totalListeners': totalListeners,
    'activeListeners': activeListeners,
    'totalShows': totalShows,
    'activeShows': activeShows,
    'totalTechnicians': totalTechnicians,
    'activeTechnicians': activeTechnicians,
    'totalSubscriptions': totalSubscriptions,
    'activeSubscriptions': activeSubscriptions,
    'revenue': revenue,
    'revenueGrowth': revenueGrowth,
    'engagementRate': engagementRate,
    'listenerGrowth': listenerGrowth,
    'pendingRequests': pendingRequests,
    'totalRequests': totalRequests,
    'timestamp': FieldValue.serverTimestamp(),
  };

  String get formattedRevenue {
    if (revenue >= 1000000) {
      return '\$${(revenue / 1000000).toStringAsFixed(1)}M';
    } else if (revenue >= 1000) {
      return '\$${(revenue / 1000).toStringAsFixed(1)}K';
    }
    return '\$${revenue.toStringAsFixed(0)}';
  }

  String get revenueTrend {
    if (revenueGrowth > 0) return '+${revenueGrowth.toStringAsFixed(1)}%';
    if (revenueGrowth < 0) return '${revenueGrowth.toStringAsFixed(1)}%';
    return '0%';
  }

  Color get revenueTrendColor {
    if (revenueGrowth > 0) return Colors.green;
    if (revenueGrowth < 0) return Colors.red;
    return Colors.grey;
  }
}
