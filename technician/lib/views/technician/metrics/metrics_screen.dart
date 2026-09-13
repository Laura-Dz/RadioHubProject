import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:intl/intl.dart';

import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../core/models/technician/metrics_model.dart';
import '../../../core/constants/app_colors.dart';

class MetricsScreen extends StatefulWidget {
  const MetricsScreen({Key? key}) : super(key: key);

  @override
  State<MetricsScreen> createState() => _State();
}

class _State extends State<MetricsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final vm = context.read<TechnicianViewModel>();
      vm.loadMetrics(period: '7d');
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();
    final live = vm.currentLiveSession;

    // When a live session starts/stops, attach/detach the live metrics stream
    if (live != null && vm.liveMetrics == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) vm.watchLiveMetrics(live.id);
      });
    } else if (live == null && vm.liveMetrics != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) vm.stopWatchingLiveMetrics();
      });
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Metrics & Audimat'),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: '24h', label: Text('24h')),
                ButtonSegment(value: '7d', label: Text('7d')),
                ButtonSegment(value: '30d', label: Text('30d')),
                ButtonSegment(value: '90d', label: Text('90d')),
              ],
              selected: {vm.metricsPeriod},
              onSelectionChanged: (v) {
                context.read<TechnicianViewModel>().loadMetrics(period: v.first);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: WidgetStateProperty.resolveWith((s) =>
                    s.contains(WidgetState.selected)
                        ? Colors.white
                        : AppColors.textSecondary),
                backgroundColor: WidgetStateProperty.resolveWith((s) =>
                    s.contains(WidgetState.selected)
                        ? AppColors.primary
                        : AppColors.surface),
              ),
            ),
          ),
        ],
      ),
      body: vm.loadingMetrics
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => vm.loadMetrics(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ========== LIVE CARD ==========
                    if (live != null && vm.liveMetrics != null) ...[
                      _LiveMetricsPanel(
                        session: live,
                        metrics: vm.liveMetrics!,
                      ),
                      const SizedBox(height: 20),
                    ],

                    // ========== AUDIMAT KPIs ==========
                    _sectionLabel('Audimat'),
                    const SizedBox(height: 8),
                    _audimatRow(vm.metrics),
                    const SizedBox(height: 20),

                    // ========== INTERACTION KPIs ==========
                    _sectionLabel('Interactions'),
                    const SizedBox(height: 8),
                    _interactionRow(vm.metrics),
                    const SizedBox(height: 20),

                    // ========== TREND ==========
                    _trendChart(vm.metrics),
                    const SizedBox(height: 16),

                    // ========== HOUR / DAY ==========
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 2, child: _hourChart(vm.metrics)),
                        const SizedBox(width: 16),
                        Expanded(child: _dayChart(vm.metrics)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ========== PER PROGRAM ==========
                    _perProgramTable(vm.metrics),
                    const SizedBox(height: 16),

                    // ========== TOP SESSIONS ==========
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _topList(
                            'Top by audience',
                            Icons.people_alt_outlined,
                            vm.metrics.topByAudience,
                            valueOf: (s) => s.avgListeners,
                            labelOf: (s) => '${_fmt(s.avgListeners)} listeners',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _topList(
                            'Top by interactions',
                            Icons.forum_outlined,
                            vm.metrics.topByInteraction,
                            valueOf: (s) => s.totalInteractions,
                            labelOf: (s) =>
                                '${s.totalInteractions} interactions',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ==================== LIVE PANEL ====================

  Widget _sectionLabel(String s) => Text(s,
      style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w800,
          color: AppColors.textSecondary,
          letterSpacing: 0.4));

  // ==================== AUDIMAT ROW ====================

  Widget _audimatRow(RadioMetrics m) {
    return Row(
      children: [
        Expanded(
          child: _kpi(
            'Total listeners',
            _fmt(m.totalListeners),
            Icons.people_alt_outlined,
            AppColors.primary,
            growth: m.growthPercent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpi(
            'Peak',
            _fmt(m.peakListeners),
            Icons.trending_up,
            AppColors.gold,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _kpi(
            'Avg / session',
            _fmt(m.avgListeners),
            Icons.bar_chart,
            AppColors.success,
          ),
        ),
      ],
    );
  }

  // ==================== INTERACTION ROW ====================

  Widget _interactionRow(RadioMetrics m) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _kpi(
                'Comments',
                _fmt(m.totalComments),
                Icons.comment_outlined,
                AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpi(
                'Calls',
                _fmt(m.totalCalls),
                Icons.call_outlined,
                AppColors.success,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpi(
                'Likes',
                _fmt(m.totalLikes),
                Icons.favorite_border,
                AppColors.error,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _kpi(
                'Shares',
                _fmt(m.totalShares),
                Icons.share_outlined,
                AppColors.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.primary.withOpacity(0.15)),
          ),
          child: Row(
            children: [
              const Icon(Icons.insights,
                  size: 16, color: AppColors.primary),
              const SizedBox(width: 10),
              Text('${_fmt(m.totalInteractions)} total interactions',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(
                '${m.interactionsPerListener.toStringAsFixed(2)} per listener',
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==================== KPI ====================

  Widget _kpi(
    String label,
    String value,
    IconData icon,
    Color color, {
    double? growth,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const Spacer(),
              if (growth != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: (growth >= 0 ? AppColors.success : AppColors.error)
                        .withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        growth >= 0
                            ? Icons.arrow_upward
                            : Icons.arrow_downward,
                        size: 11,
                        color: growth >= 0
                            ? AppColors.success
                            : AppColors.error,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${growth.abs().toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 10.5,
                          color: growth >= 0
                              ? AppColors.success
                              : AppColors.error,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  // ==================== CHARTS ====================

  Widget _trendChart(RadioMetrics m) {
    return _card(
      title: 'Listener & interaction trend',
      subtitle: 'Audience with comments and calls over the period',
      height: 260,
      child: m.trend.isEmpty
          ? _emptyChart('No samples in this period')
          : SfCartesianChart(
              primaryXAxis: DateTimeAxis(
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: const TextStyle(
                    fontSize: 10.5, color: AppColors.textSecondary),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: const MajorGridLines(
                    color: AppColors.divider, width: 0.5),
                labelStyle: const TextStyle(
                    fontSize: 10.5, color: AppColors.textSecondary),
              ),
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: TextStyle(
                    fontSize: 11, color: AppColors.textSecondary),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: [
                SplineAreaSeries<ListenerPoint, DateTime>(
                  name: 'Listeners',
                  dataSource: m.trend,
                  xValueMapper: (p, _) => p.time,
                  yValueMapper: (p, _) => p.count,
                  borderColor: AppColors.primary,
                  borderWidth: 2,
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primary.withOpacity(0.35),
                      AppColors.primary.withOpacity(0.02),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                LineSeries<ListenerPoint, DateTime>(
                  name: 'Comments',
                  dataSource: m.trend,
                  xValueMapper: (p, _) => p.time,
                  yValueMapper: (p, _) => p.comments,
                  color: AppColors.success,
                  width: 1.5,
                ),
                LineSeries<ListenerPoint, DateTime>(
                  name: 'Calls',
                  dataSource: m.trend,
                  xValueMapper: (p, _) => p.time,
                  yValueMapper: (p, _) => p.calls,
                  color: AppColors.gold,
                  width: 1.5,
                ),
              ],
            ),
    );
  }

  Widget _hourChart(RadioMetrics m) {
    return _card(
      title: 'Audience by hour',
      subtitle: 'Best times of day',
      height: 220,
      child: m.byHour.isEmpty
          ? _emptyChart('No hourly data')
          : SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: const MajorGridLines(
                    color: AppColors.divider, width: 0.5),
                labelStyle: const TextStyle(
                    fontSize: 10.5, color: AppColors.textSecondary),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: [
                AreaSeries<HourPoint, String>(
                  dataSource: m.byHour,
                  xValueMapper: (p, _) => p.label,
                  yValueMapper: (p, _) => p.avgListeners,
                  color: AppColors.success.withOpacity(0.35),
                  borderColor: AppColors.success,
                  borderWidth: 2,
                ),
              ],
            ),
    );
  }

  Widget _dayChart(RadioMetrics m) {
    return _card(
      title: 'Audience by day',
      subtitle: 'Total daily',
      height: 220,
      child: m.byDay.isEmpty
          ? _emptyChart('No daily data')
          : SfCartesianChart(
              primaryXAxis: CategoryAxis(
                labelStyle: const TextStyle(
                    fontSize: 10, color: AppColors.textSecondary),
                majorGridLines: const MajorGridLines(width: 0),
              ),
              primaryYAxis: NumericAxis(
                majorGridLines: const MajorGridLines(
                    color: AppColors.divider, width: 0.5),
                labelStyle: const TextStyle(
                    fontSize: 10.5, color: AppColors.textSecondary),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: [
                ColumnSeries<DayPoint, String>(
                  dataSource: m.byDay,
                  xValueMapper: (p, _) => p.label,
                  yValueMapper: (p, _) => p.totalListeners,
                  color: AppColors.primary,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(6)),
                ),
              ],
            ),
    );
  }

  // ==================== PER-PROGRAM TABLE ====================

  Widget _perProgramTable(RadioMetrics m) {
    return _card(
      title: 'Performance by program',
      subtitle: 'Audience and interactions per show',
      height: m.byProgram.isEmpty ? 100 : (56.0 + m.byProgram.length * 44.0),
      child: m.byProgram.isEmpty
          ? _emptyChart('No ended sessions in this period')
          : Column(
              children: [
                // header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: const BoxDecoration(
                    border: Border(
                        bottom: BorderSide(color: AppColors.divider)),
                  ),
                  child: Row(
                    children: const [
                      Expanded(
                          flex: 3,
                          child: Text('Program',
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary))),
                      Expanded(
                          child: Text('Sessions',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary))),
                      Expanded(
                          child: Text('Avg',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary))),
                      Expanded(
                          child: Text('Peak',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary))),
                      Expanded(
                          child: Text('Interact.',
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary))),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: m.byProgram.length,
                    itemBuilder: (_, i) {
                      final p = m.byProgram[i];
                      return Container(
                        padding:
                            const EdgeInsets.symmetric(vertical: 10),
                        decoration: const BoxDecoration(
                          border: Border(
                              bottom: BorderSide(color: AppColors.divider)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Text(p.programName,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ),
                            Expanded(
                              child: Text('${p.totalSessions}',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 12.5)),
                            ),
                            Expanded(
                              child: Text(_fmt(p.avgListeners),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w700)),
                            ),
                            Expanded(
                              child: Text(_fmt(p.peakListeners),
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary)),
                            ),
                            Expanded(
                              child: Text(
                                  '${p.interactionsPerListener.toStringAsFixed(2)}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                      fontSize: 12.5,
                                      color: AppColors.textSecondary)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  // ==================== TOP LISTS ====================

  Widget _topList(
    String title,
    IconData icon,
    List<SessionPerformance> items, {
    required int Function(SessionPerformance) valueOf,
    required String Function(SessionPerformance) labelOf,
  }) {
    return _card(
      title: title,
      subtitle: 'Highest in the period',
      height: 240,
      icon: icon,
      child: items.isEmpty
          ? _emptyChart('No ended sessions')
          : ListView.separated(
              itemCount: items.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, i) {
                final s = items[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 22,
                        height: 22,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('${i + 1}',
                            style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary)),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(s.programName,
                                style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            Text(
                              DateFormat('d MMM · HH:mm').format(s.start),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      Text(labelOf(s),
                          style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                );
              },
            ),
    );
  }

  // ==================== SHARED ====================

  Widget _card({
    required String title,
    required String subtitle,
    required double height,
    required Widget child,
    IconData? icon,
  }) {
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
              if (icon != null) ...[
                Icon(icon, size: 16, color: AppColors.primary),
                const SizedBox(width: 8),
              ],
              Text(title,
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 2),
          Text(subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 16),
          SizedBox(height: height, child: child),
        ],
      ),
    );
  }

  Widget _emptyChart(String msg) => Center(
        child: Text(msg,
            style: const TextStyle(
                fontSize: 13, color: AppColors.textMuted)),
      );

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }
}

class _LiveMetricsPanel extends StatelessWidget {
  final Session session;
  final LiveMetrics metrics;
  const _LiveMetricsPanel({
    required this.session,
    required this.metrics,
  });

  @override
  Widget build(BuildContext context) {
    final elapsed = DateTime.now().difference(metrics.since);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.12),
            AppColors.success.withOpacity(0.02),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.success.withOpacity(0.4), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const _LiveDot(),
              const SizedBox(width: 10),
              const Text('LIVE NOW',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppColors.success,
                      letterSpacing: 0.8)),
              const Spacer(),
              Text(_elapsedLabel(elapsed),
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontFamily: 'monospace',
                      color: AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: 12),
          Text(session.programName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text(session.hostName,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),

          // Metrics grid
          Row(
            children: [
              Expanded(
                child: _liveBlock(
                  'Listeners',
                  '${metrics.currentListeners}',
                  Icons.headphones,
                  AppColors.primary,
                  sub: 'peak ${metrics.peakListeners}',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _liveBlock(
                  'Comments',
                  '${metrics.comments}',
                  Icons.comment_outlined,
                  AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _liveBlock(
                  'Calls',
                  '${metrics.calls}',
                  Icons.call_outlined,
                  AppColors.gold,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _liveBlock(
                  'Likes',
                  '${metrics.likes}',
                  Icons.favorite_border,
                  AppColors.error,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _liveBlock(
                  'Shares',
                  '${metrics.shares}',
                  Icons.share_outlined,
                  AppColors.info,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Live trend chart
          if (metrics.recentTrend.isNotEmpty) ...[
            const Text('Audience — last 30 samples',
                style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            SizedBox(
              height: 120,
              child: SfCartesianChart(
                primaryXAxis: DateTimeAxis(
                  majorGridLines: const MajorGridLines(width: 0),
                  labelStyle: const TextStyle(
                      fontSize: 9, color: AppColors.textSecondary),
                ),
                primaryYAxis: NumericAxis(
                  majorGridLines: const MajorGridLines(
                      color: AppColors.divider, width: 0.5),
                  labelStyle: const TextStyle(
                      fontSize: 9, color: AppColors.textSecondary),
                ),
                tooltipBehavior: TooltipBehavior(enable: true),
                series: [
                  SplineAreaSeries<ListenerPoint, DateTime>(
                    dataSource: metrics.recentTrend,
                    xValueMapper: (p, _) => p.time,
                    yValueMapper: (p, _) => p.count,
                    borderColor: AppColors.success,
                    borderWidth: 2,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.success.withOpacity(0.35),
                        AppColors.success.withOpacity(0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _liveBlock(
    String label,
    String value,
    IconData icon,
    Color color, {
    String? sub,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary)),
          if (sub != null)
            Text(sub,
                style: const TextStyle(
                    fontSize: 10, color: AppColors.textMuted)),
        ],
      ),
    );
  }

  String _elapsedLabel(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return h > 0 ? '${h}h ${m}m' : '${d.inMinutes}m ${s}s';
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();
  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
  }
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }
  @override
  Widget build(BuildContext context) => FadeTransition(
        opacity: Tween<double>(begin: 0.3, end: 1.0).animate(_c),
        child: Container(
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
              color: AppColors.success, shape: BoxShape.circle),
        ),
      );
}
