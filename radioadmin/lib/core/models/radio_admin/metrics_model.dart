import 'package:flutter/material.dart';

class ListenerPoint {
  final DateTime time;
  final int count;
  ListenerPoint(this.time, this.count);
}

class CategoryPoint {
  final String category;
  final int count;
  final Color color;
  CategoryPoint(this.category, this.count, this.color);
}

class ShowPerformance {
  final String showName;
  final int avgListeners;
  final double retention;
  ShowPerformance({
    required this.showName,
    required this.avgListeners,
    required this.retention,
  });
}

class RadioMetrics {
  final int totalListeners;
  final int peakListeners;
  final double engagementRate;
  final double growthPercent;
  final List<ListenerPoint> trend;
  final List<CategoryPoint> byCategory;
  final List<ShowPerformance> showPerformance;
  final Map<int, int> audienceByHour;

  RadioMetrics({
    required this.totalListeners,
    required this.peakListeners,
    required this.engagementRate,
    required this.growthPercent,
    required this.trend,
    required this.byCategory,
    required this.showPerformance,
    required this.audienceByHour,
  });

  factory RadioMetrics.empty() => RadioMetrics(
    totalListeners: 0,
    peakListeners: 0,
    engagementRate: 0.0,
    growthPercent: 0.0,
    trend: [],
    byCategory: [],
    showPerformance: [],
    audienceByHour: {},
  );

  factory RadioMetrics.mock() {
    final now = DateTime.now();
    return RadioMetrics(
      totalListeners: 12450,
      peakListeners: 3200,
      engagementRate: 0.73,
      growthPercent: 12.4,
      trend: List.generate(24, (i) => ListenerPoint(
        now.subtract(Duration(hours: 23 - i)),
        800 + (i * 80) + (i % 4 * 120),
      )),
      byCategory: [
        CategoryPoint('Music', 45, const Color(0xFF4A90D9)),
        CategoryPoint('News', 25, const Color(0xFFD4A017)),
        CategoryPoint('Talk', 20, const Color(0xFF22C55E)),
        CategoryPoint('Sports', 10, const Color(0xFFEF4444)),
      ],
      showPerformance: [
        ShowPerformance(showName: 'Morning Drive', avgListeners: 2456, retention: 0.82),
        ShowPerformance(showName: 'Midday Mix', avgListeners: 1870, retention: 0.71),
        ShowPerformance(showName: 'Evening Talk', avgListeners: 1430, retention: 0.65),
        ShowPerformance(showName: 'Night Beats', avgListeners: 980, retention: 0.58),
      ],
      audienceByHour: {
        6: 450, 7: 890, 8: 2456, 9: 2100, 10: 1870,
        11: 1650, 12: 1876, 13: 1540, 14: 1200, 15: 980,
        16: 1100, 17: 1430, 18: 1980, 19: 2100, 20: 1800,
        21: 1200, 22: 750, 23: 350,
      },
    );
  }
}
