import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/kpi_card.dart';
import '../../../core/models/radio_admin/metrics_model.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _period = '7d';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<RadioAdminViewModel>();
      vm.loadMetrics(period: _period);
      vm.loadInsights();
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final sub = vm.subscription;
    final metrics = vm.metrics;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          _periodChip('7d'),
          const SizedBox(width: 8),
          _periodChip('30d'),
          const SizedBox(width: 8),
          _periodChip('90d'),
          const SizedBox(width: 16),
          Tooltip(
            message: 'Refresh',
            child: IconButton(
              icon: const Icon(Icons.refresh_outlined, size: 20),
              onPressed: () => vm.refreshAll(),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Subscription banner
            if (sub == null || sub.isExpired)
              _alertBanner(
                'Subscription expired',
                'Your radio is suspended. Renew now to resume broadcasting.',
                Icons.warning_amber_rounded,
                AppColors.error,
              )
            else if (sub.isExpiringSoon)
              _alertBanner(
                'Subscription expiring soon',
                '${sub.daysRemaining} day(s) remaining. Renew to avoid suspension.',
                Icons.schedule_outlined,
                AppColors.warning,
              ),
            const SizedBox(height: 20),
            // KPI row
            Row(
              children: [
                Expanded(child: KpiCard(
                  label: 'Total listeners',
                  value: _fmtNum(metrics.totalListeners),
                  icon: Icons.people_alt_outlined,
                  color: AppColors.primary,
                  growth: metrics.growthPercent,
                )),
                const SizedBox(width: 12),
                Expanded(child: KpiCard(
                  label: 'Peak listeners',
                  value: _fmtNum(metrics.peakListeners),
                  icon: Icons.show_chart,
                  color: AppColors.gold,
                )),
                const SizedBox(width: 12),
                Expanded(child: KpiCard(
                  label: 'Engagement rate',
                  value: '${(metrics.engagementRate * 100).toStringAsFixed(1)}%',
                  icon: Icons.favorite_border,
                  color: AppColors.success,
                )),
                const SizedBox(width: 12),
                Expanded(child: KpiCard(
                  label: 'Revenue (XAF)',
                  value: _fmtNum(vm.transactions.fold<double>(0, (s, t) => s + t.baseAmount).round()),
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.info,
                )),
              ],
            ),
            const SizedBox(height: 20),
            // Charts row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: _chartCard(
                    'Listener trend',
                    'Hourly aggregate',
                    SfCartesianChart(
                      margin: EdgeInsets.zero,
                      plotAreaBorderWidth: 0,
                      primaryXAxis: DateTimeAxis(
                        majorGridLines: const MajorGridLines(width: 0),
                        axisLine: const AxisLine(width: 0),
                        labelStyle: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                      primaryYAxis: NumericAxis(
                        majorGridLines: const MajorGridLines(color: AppColors.divider, width: 0.5),
                        axisLine: const AxisLine(width: 0),
                        labelStyle: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                      tooltipBehavior: TooltipBehavior(enable: true),
                      series: <CartesianSeries>[
                        SplineAreaSeries<ListenerPoint, DateTime>(
                          dataSource: metrics.trend,
                          xValueMapper: (p, _) => p.time,
                          yValueMapper: (p, _) => p.count,
                          color: AppColors.primary.withOpacity(0.25),
                          borderColor: AppColors.primary,
                          borderWidth: 2.5,
                          splineType: SplineType.cardinal,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: _chartCard(
                    'Category split',
                    'Show distribution',
                    SfCircularChart(
                      margin: EdgeInsets.zero,
                      legend: const Legend(
                        isVisible: true,
                        position: LegendPosition.bottom,
                        textStyle: TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
                      ),
                      series: <CircularSeries>[
                        DoughnutSeries<CategoryPoint, String>(
                          dataSource: metrics.byCategory,
                          xValueMapper: (p, _) => p.category,
                          yValueMapper: (p, _) => p.count,
                          pointColorMapper: (p, _) => p.color,
                          innerRadius: '55%',
                          dataLabelSettings: const DataLabelSettings(
                            isVisible: true,
                            labelPosition: ChartDataLabelPosition.outside,
                            textStyle: TextStyle(fontSize: 9.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Pending announcements + Recent transactions
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _buildPendingCard(vm)),
                const SizedBox(width: 16),
                Expanded(child: _buildTransactionsCard(vm)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _periodChip(String period) {
    final selected = _period == period;
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          setState(() => _period = period);
          context.read<RadioAdminViewModel>().loadMetrics(period: period);
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

  Widget _alertBanner(String title, String msg, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: color)),
                const SizedBox(height: 2),
                Text(msg, style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chartCard(String title, String sub, Widget chart) {
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
          SizedBox(height: 200, child: chart),
        ],
      ),
    );
  }

  Widget _buildPendingCard(RadioAdminViewModel vm) {
    final list = vm.pendingAnnouncements.take(5).toList();
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
          Row(
            children: [
              const Icon(Icons.campaign_outlined, size: 18, color: AppColors.gold),
              const SizedBox(width: 8),
              const Text('Pending announcements',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              _countBadge(vm.pendingAnnouncements.length, AppColors.gold),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No pending announcements',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ),
            )
          else
            ...list.map((a) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.campaign, size: 15, color: AppColors.gold),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${a.listenerName} · ${a.categoryLabel}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        Text(
                          '${a.baseAmount.toStringAsFixed(0)} ${a.currency} · ${a.diffusionsPerDay}x/day · ${a.days} days',
                          style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _buildTransactionsCard(RadioAdminViewModel vm) {
    final list = vm.transactions.take(5).toList();
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
          Row(
            children: [
              const Icon(Icons.receipt_long_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text('Recent transactions',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              const Spacer(),
              _countBadge(vm.transactions.length, AppColors.primary),
            ],
          ),
          const SizedBox(height: 12),
          if (list.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No transactions yet',
                    style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
              ),
            )
          else
            ...list.map((t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.receipt_long, size: 15, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${t.typeLabel} · ${t.totalAmount.toStringAsFixed(0)} ${t.currency}',
                            style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                        Text('${t.statusLabel} · ${t.paymentMethod ?? "-"}',
                            style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                      ],
                    ),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  Widget _countBadge(int count, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text('$count',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }

  String _fmtNum(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}
