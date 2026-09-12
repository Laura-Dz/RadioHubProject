import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import '../../../core/models/radio_admin/recommendation_model.dart';
import '../../../core/constants/app_colors.dart';

class ComparisonCard extends StatelessWidget {
  final ShowComparison comparison;

  const ComparisonCard({Key? key, required this.comparison}) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.compare_arrows, color: AppColors.gold, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${comparison.strongShow} vs ${comparison.weakShow}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // KPI row
          Row(
            children: [
              Expanded(child: _kpi('Listener gap', '${comparison.listenerGap}')),
              Expanded(child: _kpi('Retention gap',
                  '${(comparison.retentionGap * 100).toStringAsFixed(0)}%')),
            ],
          ),
          const SizedBox(height: 16),

          // Audience distribution chart
          const Text('Audience by age group',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          SizedBox(
            height: 180,
            child: SfCartesianChart(
              primaryXAxis: CategoryAxis(
                majorGridLines: const MajorGridLines(width: 0),
                labelStyle: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              ),
              primaryYAxis: NumericAxis(
                labelFormat: '{value}%',
                majorGridLines: const MajorGridLines(color: AppColors.divider, width: 0.5),
                labelStyle: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary),
              ),
              legend: const Legend(
                isVisible: true,
                position: LegendPosition.bottom,
                textStyle: TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              tooltipBehavior: TooltipBehavior(enable: true),
              series: [
                ColumnSeries<AudienceDiff, String>(
                  name: comparison.strongShow,
                  dataSource: comparison.audienceDiff,
                  xValueMapper: (p, _) => p.ageGroup,
                  yValueMapper: (p, _) => p.strongShowPct,
                  color: AppColors.success,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                ColumnSeries<AudienceDiff, String>(
                  name: comparison.weakShow,
                  dataSource: comparison.audienceDiff,
                  xValueMapper: (p, _) => p.ageGroup,
                  yValueMapper: (p, _) => p.weakShowPct,
                  color: AppColors.primary,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Suggestions
          const Text('What to try',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          ...comparison.suggestions.map(_suggestion),
        ],
      ),
    );
  }

  Widget _kpi(String label, String value) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ],
      );

  Widget _suggestion(CompareSuggestion s) => Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.04),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.15)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text(
                  s.attribute.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(s.observation,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textPrimary)),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.arrow_forward, size: 12, color: AppColors.success),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(s.action,
                      style: const TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text('Expected: ${s.expectedEffect}',
                style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary, fontStyle: FontStyle.italic)),
          ],
        ),
      );
}
