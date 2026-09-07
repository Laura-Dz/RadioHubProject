import 'package:flutter/material.dart';
import '../../../core/models/show_metrics_model.dart';

class MetricsCard extends StatelessWidget {
  final ShowMetrics metrics;
  final VoidCallback onAnalyticsTap;

  const MetricsCard({
    Key? key,
    required this.metrics,
    required this.onAnalyticsTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '📊 Live Metrics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              ElevatedButton.icon(
                onPressed: onAnalyticsTap,
                icon: const Icon(Icons.analytics, size: 16),
                label: const Text('View Analytics'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metricItem(Icons.people, 'Listeners', _formatCount(metrics.listenerCount)),
              _metricItem(Icons.trending_up, 'Peak', _formatCount(metrics.peakListeners)),
              _metricItem(Icons.favorite, 'Engagement', '${(metrics.engagementRate * 100).toInt()}%'),
              _metricItem(Icons.timer, 'Duration', metrics.duration),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metricItem(IconData icon, String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Column(
          children: [
            Icon(icon, size: 18, color: Colors.grey.shade600),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}k';
    return count.toString();
  }
}
