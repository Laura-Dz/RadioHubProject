import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/models/radio_admin/metrics_model.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({Key? key}) : super(key: key);

  @override
  State<MetricsScreen> createState() => _MetricsScreenState();
}

class _MetricsScreenState extends State<MetricsScreen> {
  String _period = '7d';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioAdminViewModel>().loadMetrics(period: _period);
    });
  }

  Future<void> _pickCustomDateRange() async {
    final vm = context.read<RadioAdminViewModel>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365 * 10)),
      lastDate: now,
      initialDateRange: (vm.customStartDate != null && vm.customEndDate != null)
          ? DateTimeRange(start: vm.customStartDate!, end: vm.customEndDate!)
          : DateTimeRange(start: now.subtract(const Duration(days: 30)), end: now),
      helpText: 'SELECT METRICS PERIOD (MAX 5 YEARS)',
      confirmText: 'APPLY',
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      final days = picked.end.difference(picked.start).inDays;
      if (days > 1826) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('The selected interval ($days days) exceeds the 5-year maximum limit (1,826 days).'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      vm.setCustomDateRange(picked.start, picked.end);
      setState(() => _period = 'custom');
      vm.loadMetrics(startDate: picked.start, endDate: picked.end);
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final m = vm.metrics;

    // Convert audience by hour map to chart list
    final hourPoints = m.audienceByHour.entries
        .map((e) => _HourPoint(e.key, e.value))
        .toList()
      ..sort((a, b) => a.hour.compareTo(b.hour));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Metrics & Audimat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          _periodChip('7d', vm),
          const SizedBox(width: 8),
          _periodChip('30d', vm),
          const SizedBox(width: 8),
          _periodChip('90d', vm),
          const SizedBox(width: 8),
          _customRangeChip(vm),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KPI row
            Row(
              children: [
                Expanded(child: KpiCard(
                  label: 'Total listeners',
                  value: m.totalListeners.toString(),
                  icon: Icons.people_alt_outlined,
                  color: AppColors.primary,
                  growth: m.growthPercent,
                )),
                const SizedBox(width: 12),
                Expanded(child: KpiCard(
                  label: 'Peak audience',
                  value: m.peakListeners.toString(),
                  icon: Icons.show_chart,
                  color: AppColors.gold,
                )),
                const SizedBox(width: 12),
                Expanded(child: KpiCard(
                  label: 'Engagement rate',
                  value: '${(m.engagementRate * 100).toStringAsFixed(1)}%',
                  icon: Icons.thumb_up_alt_outlined,
                  color: AppColors.success,
                )),
                const SizedBox(width: 12),
                Expanded(child: KpiCard(
                  label: 'Audience growth',
                  value: '+${m.growthPercent.toStringAsFixed(1)}%',
                  icon: Icons.trending_up,
                  color: AppColors.info,
                )),
              ],
            ),
            const SizedBox(height: 20),

            // Top chart row: Listener trend + Category split
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _card(
                    'Listener Trend',
                    'Hourly listening timeline',
                    SfCartesianChart(
                      margin: EdgeInsets.zero,
                      primaryXAxis: DateTimeAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                        axisLine: const AxisLine(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        majorGridLines: const MajorGridLines(color: AppColors.divider, width: 0.5),
                        axisLine: const AxisLine(width: 0),
                      ),
                      series: <CartesianSeries>[
                        SplineAreaSeries<ListenerPoint, DateTime>(
                          dataSource: m.trend,
                          xValueMapper: (p, _) => p.time,
                          yValueMapper: (p, _) => p.count,
                          color: AppColors.primary.withOpacity(0.25),
                          borderColor: AppColors.primary,
                          borderWidth: 2,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _card(
                    'Category Share',
                    'Broadcast distribution',
                    SfCircularChart(
                      margin: EdgeInsets.zero,
                      legend: const Legend(isVisible: true, position: LegendPosition.bottom),
                      series: <CircularSeries>[
                        DoughnutSeries<CategoryPoint, String>(
                          dataSource: m.byCategory,
                          xValueMapper: (p, _) => p.category,
                          yValueMapper: (p, _) => p.count,
                          pointColorMapper: (p, _) => p.color,
                          innerRadius: '60%',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Bottom chart row: Show performance + Audience by hour
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _card(
                    'Show Performance',
                    'Average audience per show',
                    SfCartesianChart(
                      margin: EdgeInsets.zero,
                      primaryXAxis: CategoryAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                      ),
                      primaryYAxis: NumericAxis(
                        majorGridLines: const MajorGridLines(color: AppColors.divider, width: 0.5),
                      ),
                      series: <CartesianSeries>[
                        BarSeries<ShowPerformance, String>(
                          dataSource: m.showPerformance,
                          xValueMapper: (s, _) => s.showName,
                          yValueMapper: (s, _) => s.avgListeners,
                          color: AppColors.gold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _card(
                    'Audience by Hour',
                    'Average active listeners throughout the day',
                    SfCartesianChart(
                      margin: EdgeInsets.zero,
                      primaryXAxis: NumericAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                        interval: 2,
                        labelFormat: '{value}h',
                      ),
                      primaryYAxis: NumericAxis(
                        majorGridLines: const MajorGridLines(color: AppColors.divider, width: 0.5),
                      ),
                      series: <CartesianSeries>[
                        ColumnSeries<_HourPoint, num>(
                          dataSource: hourPoints,
                          xValueMapper: (h, _) => h.hour,
                          yValueMapper: (h, _) => h.listeners,
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String period, RadioAdminViewModel vm) {
    final selected = _period == period;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          vm.clearCustomDateRange();
          setState(() => _period = period);
          vm.loadMetrics(period: period);
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            period,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _customRangeChip(RadioAdminViewModel vm) {
    final selected = _period == 'custom';
    final hasRange = vm.customStartDate != null && vm.customEndDate != null;
    final label = (selected && hasRange)
        ? '${vm.customStartDate!.day}/${vm.customStartDate!.month}/${vm.customStartDate!.year} - ${vm.customEndDate!.day}/${vm.customEndDate!.month}/${vm.customEndDate!.year}'
        : 'Custom (≤5 yrs)';

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _pickCustomDateRange,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: selected ? AppColors.primary : AppColors.primary.withOpacity(0.25)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.date_range,
                size: 14,
                color: selected ? Colors.white : AppColors.primary,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: selected ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(String title, String sub, Widget chart) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(height: 210, child: chart),
        ],
      ),
    );
  }
}

class _HourPoint {
  final int hour;
  final int listeners;
  _HourPoint(this.hour, this.listeners);
}
