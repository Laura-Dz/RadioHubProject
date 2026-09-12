import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/metric_model.dart';
import '../../../core/models/radio_admin/session_model.dart';
import '../../../core/models/radio_admin/program_model.dart';
import '../../../core/widgets/common_widgets.dart';

class AnalyticsTab extends StatelessWidget {
  final String radioId;

  const AnalyticsTab({Key? key, required this.radioId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final viewModel = context.watch<RadioAdminViewModel>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Analytics',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: RadioAdminColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Performance metrics and insights',
                    style: TextStyle(
                      fontSize: 14,
                      color: RadioAdminColors.textSecondary,
                    ),
                  ),
                ],
              ),
              ActionButton(
                label: 'Export Report',
                icon: Icons.download,
                onPressed: () {},
                outlined: true,
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Overview Metrics
          if (viewModel.metrics != null) ...[
            _buildMetricsCards(viewModel.metrics!),
            const SizedBox(height: 24),
          ],

          // Charts Placeholder
          _buildChartsSection(),
          const SizedBox(height: 24),

          // Top Content
          _buildTopContent(viewModel),
        ],
      ),
    );
  }

  Widget _buildMetricsCards(RadioMetrics metrics) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1200 ? 5 : (constraints.maxWidth > 800 ? 3 : 2);
        return GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: 1.6,
          children: [
            MetricCard(
              label: 'Total Sessions',
              value: metrics.totalSessions.toString(),
              subtitle: '+12% vs last month',
              icon: Icons.play_circle,
              iconColor: RadioAdminColors.primary,
            ),
            MetricCard(
              label: 'Total Listeners',
              value: _formatNumber(metrics.totalListeners),
              subtitle: '+8% vs last month',
              icon: Icons.headphones,
              iconColor: RadioAdminColors.success,
            ),
            MetricCard(
              label: 'Avg Listeners/Session',
              value: metrics.avgListeners.toString(),
              subtitle: 'Engagement metric',
              icon: Icons.analytics,
              iconColor: RadioAdminColors.warning,
            ),
            MetricCard(
              label: 'Live Sessions',
              value: metrics.liveSessions.toString(),
              subtitle: 'Currently on air',
              icon: Icons.live_tv,
              iconColor: RadioAdminColors.error,
            ),
            MetricCard(
              label: 'Revenue',
              value: '\$${_formatNumber(metrics.revenue.round())}',
              subtitle: '${metrics.revenueGrowth > 0 ? '+' : ''}${metrics.revenueGrowth.toStringAsFixed(1)}% growth',
              icon: Icons.attach_money,
              iconColor: RadioAdminColors.accent,
            ),
          ],
        );
      },
    );
  }

  Widget _buildChartsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performance Trends',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: RadioAdminColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                'Listeners Over Time',
                Icons.show_chart,
                'Line chart showing daily listener counts over the last 30 days',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                'Session Engagement',
                Icons.pie_chart,
                'Pie chart showing distribution of session types and engagement',
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildChartCard(
                'Peak Hours',
                Icons.access_time,
                'Bar chart showing listener activity by hour of day',
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildChartCard(
                'Program Popularity',
                Icons.bar_chart,
                'Horizontal bar chart of top programs by average listeners',
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildChartCard(String title, IconData icon, String description) {
    return Container(
      height: 250,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RadioAdminColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RadioAdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: RadioAdminColors.primary, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: RadioAdminColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 64, color: RadioAdminColors.textSecondary.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Chart Placeholder',
                    style: TextStyle(
                      fontSize: 18,
                      color: RadioAdminColors.textSecondary.withOpacity(0.6),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 12,
                      color: RadioAdminColors.textSecondary.withOpacity(0.6),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopContent(RadioAdminViewModel viewModel) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Top Performing Content',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: RadioAdminColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _buildTopList(
                'Top Programs',
                viewModel.programs.where((p) => p.isActive).take(5).map((p) {
                  return {
                    'name': p.name,
                    'metric': '${p.category.label} • Active',
                    'icon': p.category.iconData,
                    'color': p.category.iconColor,
                  };
                }).toList(),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildTopList(
                'Top Sessions',
                viewModel.sessions.where((s) => s.status == SessionStatus.ended).take(5).map((s) {
                  return {
                    'name': s.programName,
                    'metric': '${s.listenerCount} listeners • ${DateFormat('MMM d').format(s.date)}',
                    'icon': Icons.play_circle,
                    'color': RadioAdminColors.primary,
                  };
                }).toList(),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTopList(String title, List<Map<String, dynamic>> items) {
    return Container(
      decoration: BoxDecoration(
        color: RadioAdminColors.cardBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RadioAdminColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: RadioAdminColors.textPrimary,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (_, __) =>
                Divider(height: 1, color: RadioAdminColors.divider),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: (item['color'] as Color).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    size: 18,
                    color: item['color'] as Color,
                  ),
                ),
                title: Text(
                  item['name'] as String,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: RadioAdminColors.textPrimary,
                  ),
                ),
                subtitle: Text(
                  item['metric'] as String,
                  style: const TextStyle(
                    fontSize: 11,
                    color: RadioAdminColors.textSecondary,
                  ),
                ),
                trailing: Text(
                  '#${index + 1}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: RadioAdminColors.primary,
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}