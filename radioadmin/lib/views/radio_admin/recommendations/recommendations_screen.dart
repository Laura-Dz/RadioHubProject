import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../view_models/radio_admin_view_model.dart';
import '../../../core/models/radio_admin/recommendation_model.dart';
import '../../../core/constants/app_colors.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<RadioAdminViewModel>();
    final ins = vm.insights;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('AI Recommendations'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => context.read<RadioAdminViewModel>().loadInsights(),
          ),
        ],
      ),
      body: vm.loadingInsights
          ? const Center(child: CircularProgressIndicator())
          : ins == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.auto_awesome, size: 64, color: Colors.grey),
                      const SizedBox(height: 12),
                      const Text('No insights loaded yet'),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () => context.read<RadioAdminViewModel>().loadInsights(),
                        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                        child: const Text('Generate Insights'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (ins.audimat != null) _audimatSection(ins.audimat!),
                      const SizedBox(height: 16),
                      if (ins.shows != null) _showsSection(ins.shows!),
                      const SizedBox(height: 16),
                      if (ins.revenue != null) _revenueSection(ins.revenue!),
                      const SizedBox(height: 16),
                      if (ins.scheduling != null) _schedulingSection(ins.scheduling!),
                    ],
                  ),
                ),
    );
  }

  Widget _audimatSection(AudimatInsights a) {
    return _card('Audimat Insights', Icons.analytics, [
      _subsection('Peak Hours', a.peakHours.map((h) => _row(h.hour, '${h.avgListeners} listeners', h.recommendation)).toList()),
      _subsection('Declining Slots', a.decliningSlots.map((h) => _row(h.hour, '${h.avgListeners} listeners', h.recommendation)).toList()),
    ]);
  }

  Widget _showsSection(ShowInsights s) {
    return _card('Show Performance', Icons.tv, [
      _subsection('Top Performers', s.topPerformers.map((p) => _row(p.show, '${p.listeners} listeners | ${(p.retention * 100).toInt()}% retention', p.recommendation)).toList()),
      _subsection('Underperformers', s.underperformers.map((p) => _row(p.show, '${p.listeners} listeners', p.recommendation)).toList()),
      _subsection('Suggested Schedule Changes', s.suggestedScheduleChanges.map((c) => _row(c.current, 'Move to: ${c.suggested}', c.reason)).toList()),
    ]);
  }

  Widget _revenueSection(RevenueInsights r) {
    return _card('Revenue Insights', Icons.attach_money, [
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text('Projected monthly: ${r.projectedMonthly.toStringAsFixed(0)} XAF',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ),
      _subsection('Recommended Categories', r.categoriesRecommended.map((c) => _row(c.category, '', c.reason)).toList()),
    ]);
  }

  Widget _schedulingSection(SchedulingInsights s) {
    return _card('Scheduling Insights', Icons.calendar_today, [
      _subsection('Recommended Slots', s.recommendedSlots.map((sl) => _row('${sl.day} ${sl.hour}', '', sl.reason)).toList()),
      _subsection('Avoid Slots', s.avoidSlots.map((sl) => _row('${sl.day} ${sl.hour}', '', sl.reason)).toList()),
    ]);
  }

  Widget _card(String title, IconData icon, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _subsection(String title, List<Widget> rows) {
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        ...rows,
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _row(String label, String value, String recommendation) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w600))),
              if (value.isNotEmpty) Text(value, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
            ],
          ),
          const SizedBox(height: 2),
          Text(recommendation, style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }
}

