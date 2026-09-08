import 'package:flutter/material.dart';
import '../../../core/models/director/metric_model.dart';

class MetricsScreen extends StatelessWidget {
  final DirectorMetrics? metrics;

  const MetricsScreen({Key? key, this.metrics}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('📊 Dashboard Metrics', style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Real-time overview of your radio station performance',
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
          const SizedBox(height: 24),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.4,
              children: [
                _buildMetricCard(icon: Icons.people, label: 'Listeners',
                    value: metrics?.totalListeners.toString() ?? '0',
                    subtext: '${metrics?.activeListeners ?? 0} active', color: Colors.blue),
                _buildMetricCard(icon: Icons.mic, label: 'Shows',
                    value: metrics?.totalShows.toString() ?? '0',
                    subtext: '${metrics?.activeShows ?? 0} active', color: Colors.purple),
                _buildMetricCard(icon: Icons.build, label: 'Technicians',
                    value: metrics?.totalTechnicians.toString() ?? '0',
                    subtext: '${metrics?.activeTechnicians ?? 0} active', color: Colors.orange),
                _buildMetricCard(icon: Icons.subscriptions, label: 'Subscriptions',
                    value: metrics?.totalSubscriptions.toString() ?? '0',
                    subtext: '${metrics?.activeSubscriptions ?? 0} active', color: Colors.green),
                _buildMetricCard(icon: Icons.attach_money, label: 'Revenue',
                    value: metrics?.formattedRevenue ?? '\$0',
                    subtext: metrics?.revenueTrend ?? '0%',
                    color: Colors.teal, subtextColor: metrics?.revenueTrendColor ?? Colors.green),
                _buildMetricCard(icon: Icons.trending_up, label: 'Engagement',
                    value: '${(metrics?.engagementRate ?? 0).toStringAsFixed(1)}%',
                    subtext: '${(metrics?.listenerGrowth ?? 0).toStringAsFixed(1)}% growth', color: Colors.indigo),
                _buildMetricCard(icon: Icons.request_page, label: 'Requests',
                    value: metrics?.totalRequests.toString() ?? '0',
                    subtext: '${metrics?.pendingRequests ?? 0} pending', color: Colors.red),
                _buildMetricCard(icon: Icons.timeline, label: 'Listeners Growth',
                    value: '${(metrics?.listenerGrowth ?? 0).toStringAsFixed(1)}%',
                    subtext: 'vs last month', color: Colors.cyan),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
    required String subtext,
    required Color color,
    Color? subtextColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text(subtext, style: TextStyle(fontSize: 11, color: subtextColor ?? Colors.grey.shade500)),
        ],
      ),
    );
  }
}
