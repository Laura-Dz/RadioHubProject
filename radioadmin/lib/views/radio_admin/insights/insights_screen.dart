import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/recommendation_model.dart';
import '../../../core/constants/app_colors.dart';
import 'comparison_view.dart';

class InsightsScreen extends StatefulWidget {
  const InsightsScreen({Key? key}) : super(key: key);
  @override
  State<InsightsScreen> createState() => _InsightsScreenState();
}

class _InsightsScreenState extends State<InsightsScreen> {
  String _range = 'last_30_days';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RadioAdminViewModel>().loadInsights(timeRange: _range);
    });
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final insights = vm.insights;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('AI Insights', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'last_7_days', label: Text('7d')),
                ButtonSegment(value: 'last_30_days', label: Text('30d')),
                ButtonSegment(value: 'last_90_days', label: Text('90d')),
              ],
              selected: {_range},
              onSelectionChanged: (s) {
                setState(() => _range = s.first);
                context.read<RadioAdminViewModel>().loadInsights(timeRange: _range);
              },
              showSelectedIcon: false,
              style: ButtonStyle(
                visualDensity: VisualDensity.compact,
                foregroundColor: MaterialStateProperty.resolveWith((states) =>
                    states.contains(MaterialState.selected) ? Colors.white : AppColors.textSecondary),
                backgroundColor: MaterialStateProperty.resolveWith((states) =>
                    states.contains(MaterialState.selected) ? AppColors.primary : AppColors.surface),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Regenerate insights',
            icon: const Icon(Icons.refresh, size: 20),
            onPressed: () => context.read<RadioAdminViewModel>().loadInsights(timeRange: _range),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: vm.loadingInsights
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : insights == null
              ? _empty()
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (insights.audimat != null) _audimatSection(insights.audimat!),
                      const SizedBox(height: 16),
                      if (insights.shows != null) _showsSection(insights.shows!),
                      const SizedBox(height: 16),
                      if (insights.revenue != null) _revenueSection(insights.revenue!),
                      const SizedBox(height: 16),
                      if (insights.scheduling != null) _schedulingSection(insights.scheduling!),
                      if (insights.comparisons.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Row(
                          children: const [
                            Icon(Icons.compare_arrows, color: AppColors.gold, size: 20),
                            SizedBox(width: 8),
                            Text('Why some shows outperform others',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...insights.comparisons.map((c) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: ComparisonCard(comparison: c),
                        )),
                      ],
                      if (insights.diagnostics.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          children: const [
                            Icon(Icons.insights, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text('Show diagnostics',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...insights.diagnostics.map((d) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DiagnosticCard(diagnostic: d),
                        )),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _empty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.auto_awesome_outlined, size: 72, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No insights yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () => context.read<RadioAdminViewModel>().loadInsights(timeRange: _range),
              icon: const Icon(Icons.auto_awesome, size: 16),
              label: const Text('Generate insights'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        ),
      );

  Widget _audimatSection(AudimatInsights a) => _card(
        'Audimat insights',
        Icons.analytics_outlined,
        [
          _subsection('Peak hours', a.peakHours
              .map((h) => _insightRow(h.hour, '${h.avgListeners} avg', h.recommendation))
              .toList()),
          _subsection('Declining slots', a.decliningSlots
              .map((h) => _insightRow(h.hour, '${h.avgListeners} avg', h.recommendation))
              .toList()),
        ],
      );

  Widget _showsSection(ShowInsights s) => _card(
        'Show performance',
        Icons.tv_outlined,
        [
          _subsection('Top performers', s.topPerformers
              .map((p) => _insightRow(p.show, '${p.listeners} · ${(p.retention * 100).toInt()}% ret',
                  p.recommendation))
              .toList()),
          _subsection('Underperformers', s.underperformers
              .map((p) => _insightRow(p.show, '${p.listeners} · ${(p.retention * 100).toInt()}% ret',
                  p.recommendation))
              .toList()),
          _subsection('Suggested changes', s.suggestedScheduleChanges
              .map((c) => _insightRow(c.current, '→ ${c.suggested}', c.reason))
              .toList()),
        ],
      );

  Widget _revenueSection(RevenueInsights r) => _card(
        'Revenue insights',
        Icons.attach_money,
        [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Text('Projected monthly: ',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                Text('${r.projectedMonthly.toStringAsFixed(0)} XAF',
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
              ],
            ),
          ),
          _subsection('Recommended categories', r.categoriesRecommended
              .map((c) => _insightRow(c.category, '', c.reason))
              .toList()),
        ],
      );

  Widget _schedulingSection(SchedulingInsights s) => _card(
        'Scheduling insights',
        Icons.calendar_today_outlined,
        [
          _subsection('Recommended slots', s.recommendedSlots
              .map((sl) => _insightRow('${sl.day} · ${sl.hour}', '', sl.reason))
              .toList()),
          _subsection('Avoid slots', s.avoidSlots
              .map((sl) => _insightRow('${sl.day} · ${sl.hour}', '', sl.reason))
              .toList()),
        ],
      );

  Widget _card(String title, IconData icon, List<Widget> children) => Container(
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
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: AppColors.primary),
                ),
                const SizedBox(width: 10),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      );

  Widget _subsection(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 4),
          child: Text(title,
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w700)),
        ),
        ...rows,
      ],
    );
  }

  Widget _insightRow(String label, String value, String recommendation) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(label,
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                if (value.isNotEmpty)
                  Text(value,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ),
            if (recommendation.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(recommendation,
                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary)),
            ],
          ],
        ),
      );
}

class _DiagnosticCard extends StatelessWidget {
  final ShowDiagnostic diagnostic;
  const _DiagnosticCard({required this.diagnostic});

  @override
  Widget build(BuildContext context) {
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
              Expanded(
                child: Text(diagnostic.show,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text('${diagnostic.listeners} avg',
                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(diagnostic.verdict,
              style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
          const SizedBox(height: 8),
          // Mini bar for age distribution
          Row(
            children: diagnostic.distribution.map((d) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: Column(
                    children: [
                      Container(
                        height: 40 * d.pct / 100,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(d.ageGroup, style: const TextStyle(fontSize: 8, color: AppColors.textMuted)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
