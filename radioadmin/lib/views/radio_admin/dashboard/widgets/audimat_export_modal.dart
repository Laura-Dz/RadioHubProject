import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/radio_admin/metrics_model.dart';

class AudimatExportModal extends StatelessWidget {
  final String radioName;
  final String period;
  final RadioMetrics metrics;

  const AudimatExportModal({
    Key? key,
    required this.radioName,
    required this.period,
    required this.metrics,
  }) : super(key: key);

  static void show(BuildContext context, {
    required String radioName,
    required String period,
    required RadioMetrics metrics,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => AudimatExportModal(
        radioName: radioName,
        period: period,
        metrics: metrics,
      ),
    );
  }

  String _generateCsv() {
    final buffer = StringBuffer();
    buffer.writeln('RADIO STATION AUDIMAT REPORT');
    buffer.writeln('Station:,$radioName');
    buffer.writeln('Period:,$period');
    buffer.writeln('Generated on:,${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}');
    buffer.writeln('Total Reach:,"${metrics.totalListeners} listeners"');
    buffer.writeln('Peak Concurrent:,"${metrics.peakListeners} listeners"');
    buffer.writeln('Audience Growth:,"${metrics.growthPercent.toStringAsFixed(1)}%"');
    buffer.writeln('Avg Engagement / Retention:,"${(metrics.engagementRate * 100).toStringAsFixed(1)}%"');
    buffer.writeln();

    // Hourly Breakdown Table
    buffer.writeln('HOURLY AUDIENCE DISTRIBUTION');
    buffer.writeln('Hour Slot,Audience Count,Share (%)');
    final totalHourlySum = metrics.audienceByHour.values.fold<int>(0, (s, v) => s + v);
    for (int h = 0; h < 24; h++) {
      final count = metrics.audienceByHour[h] ?? 0;
      final share = totalHourlySum > 0 ? (count / totalHourlySum * 100).toStringAsFixed(1) : '0.0';
      final label = '${h.toString().padLeft(2, '0')}:00 - ${(h + 1).toString().padLeft(2, '0')}:00';
      buffer.writeln('"$label",$count,$share%');
    }
    buffer.writeln();

    // Program Performance Table
    if (metrics.showPerformance.isNotEmpty) {
      buffer.writeln('PROGRAM PERFORMANCE RANKINGS');
      buffer.writeln('Show Name,Average Listeners,Retention Rate (%)');
      for (final p in metrics.showPerformance) {
        buffer.writeln('"${p.showName}",${p.avgListeners},"${(p.retention * 100).toStringAsFixed(1)}%"');
      }
    }

    return buffer.toString();
  }

  String _generateAdvertiserBrief() {
    final buffer = StringBuffer();
    final nowStr = DateFormat('MMMM dd, yyyy').format(DateTime.now());
    buffer.writeln('========================================');
    buffer.writeln(' OFFICIAL AUDIMAT & RATINGS SUMMARY');
    buffer.writeln(' Station: $radioName');
    buffer.writeln(' Reporting Window: Last $period (Generated $nowStr)');
    buffer.writeln('========================================');
    buffer.writeln();
    buffer.writeln('1. AUDIENCE REACH & ENGAGEMENT');
    buffer.writeln(' • Total Verified Listeners: ${NumberFormat('#,###').format(metrics.totalListeners)}');
    buffer.writeln(' • Peak Concurrent Audience: ${NumberFormat('#,###').format(metrics.peakListeners)}');
    buffer.writeln(' • Period Audience Growth: ${metrics.growthPercent >= 0 ? '+' : ''}${metrics.growthPercent.toStringAsFixed(1)}%');
    buffer.writeln(' • Average Broadcast Retention: ${(metrics.engagementRate * 100).toStringAsFixed(1)}%');
    buffer.writeln();

    buffer.writeln('2. PRIME TIME AUDIENCE WINDOWS (24h)');
    final sortedHours = metrics.audienceByHour.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topHours = sortedHours.take(5).toList();
    if (topHours.isNotEmpty) {
      for (final e in topHours) {
        final start = e.key.toString().padLeft(2, '0');
        final end = ((e.key + 1) % 24).toString().padLeft(2, '0');
        buffer.writeln(' • $start:00 - $end:00 → ${NumberFormat('#,###').format(e.value)} listeners (Peak Slot)');
      }
    } else {
      buffer.writeln(' • Continuous broadcast monitoring active.');
    }
    buffer.writeln();

    if (metrics.showPerformance.isNotEmpty) {
      buffer.writeln('3. TOP SHOW PERFORMANCE & SPONSOR OPPORTUNITIES');
      for (final p in metrics.showPerformance.take(5)) {
        buffer.writeln(' • ${p.showName}: Avg ${NumberFormat('#,###').format(p.avgListeners)} listeners · ${(p.retention * 100).toStringAsFixed(1)}% retention');
      }
      buffer.writeln();
    }

    buffer.writeln('========================================');
    buffer.writeln('Report certified by RadioHub Broadcast Analytics Engine');
    buffer.writeln('Strict multi-tenant audimat data collected via verified streaming telemetry.');
    buffer.writeln('========================================');
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final totalHourlySum = metrics.audienceByHour.values.fold<int>(0, (s, v) => s + v);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      backgroundColor: AppColors.surface,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720, maxHeight: 780),
        child: Column(
          children: [
            // Modal Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.analytics_outlined, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Audimat Report · $radioName',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Certified audience ratings & commercial sponsor report ($period window)',
                          style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.textSecondary),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Modal Body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Summary KPI Cards Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricTile(
                            'Total Reach',
                            NumberFormat('#,###').format(metrics.totalListeners),
                            Icons.people_alt_outlined,
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            'Peak Concurrent',
                            NumberFormat('#,###').format(metrics.peakListeners),
                            Icons.trending_up_rounded,
                            AppColors.gold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            'Audience Growth',
                            '${metrics.growthPercent >= 0 ? '+' : ''}${metrics.growthPercent.toStringAsFixed(1)}%',
                            Icons.auto_graph_rounded,
                            metrics.growthPercent >= 0 ? AppColors.success : AppColors.error,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricTile(
                            'Avg Retention',
                            '${(metrics.engagementRate * 100).toStringAsFixed(1)}%',
                            Icons.favorite_border_rounded,
                            AppColors.info,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Top Program Rankings
                    if (metrics.showPerformance.isNotEmpty) ...[
                      const Text(
                        'Top Shows by Audience',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: metrics.showPerformance.take(4).map((p) {
                            return ListTile(
                              dense: true,
                              title: Text(p.showName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                              subtitle: Text('Avg Audience: ${NumberFormat('#,###').format(p.avgListeners)} listeners', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondary)),
                              trailing: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  '${(p.retention * 100).toStringAsFixed(1)}% retention',
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Hourly Ratings Table
                    const Text(
                      '24-Hour Audience Distribution',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Listener activity aggregate by hour of the day',
                      style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        children: [
                          Container(
                            color: AppColors.surface,
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            child: const Row(
                              children: [
                                Expanded(flex: 3, child: Text('TIME SLOT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                                Expanded(flex: 2, child: Text('LISTENERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                                Expanded(flex: 2, child: Text('SHARE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                                Expanded(flex: 4, child: Text('RELATIVE VOLUME', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textSecondary))),
                              ],
                            ),
                          ),
                          const Divider(height: 1, color: AppColors.border),
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: 24,
                            separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                            itemBuilder: (ctx, h) {
                              final count = metrics.audienceByHour[h] ?? 0;
                              final share = totalHourlySum > 0 ? (count / totalHourlySum) : 0.0;
                              final slotLabel = '${h.toString().padLeft(2, '0')}:00 - ${((h + 1) % 24).toString().padLeft(2, '0')}:00';
                              final isPeak = metrics.peakListeners > 0 && count == metrics.peakListeners;

                              return Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      flex: 3,
                                      child: Row(
                                        children: [
                                          Text(slotLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                                          if (isPeak) ...[
                                            const SizedBox(width: 6),
                                            Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                                              decoration: BoxDecoration(
                                                color: AppColors.gold.withOpacity(0.15),
                                                borderRadius: BorderRadius.circular(4),
                                              ),
                                              child: const Text('PEAK', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppColors.gold)),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        NumberFormat('#,###').format(count),
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 2,
                                      child: Text(
                                        '${(share * 100).toStringAsFixed(1)}%',
                                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                                      ),
                                    ),
                                    Expanded(
                                      flex: 4,
                                      child: ClipRRect(
                                        borderRadius: BorderRadius.circular(4),
                                        child: LinearProgressIndicator(
                                          value: share.clamp(0.0, 1.0),
                                          minHeight: 8,
                                          backgroundColor: AppColors.border,
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            isPeak ? AppColors.gold : AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Modal Footer Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.verified_outlined, size: 16, color: AppColors.success),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'RadioHub Certified Multi-Tenant Telemetry',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.table_chart_outlined, size: 16),
                    label: const Text('Copy CSV'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.border),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generateCsv()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Audimat CSV copied to clipboard (ready for Excel/Sheets)'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy Advertiser Brief'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                    ),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: _generateAdvertiserBrief()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Advertiser brief copied to clipboard!'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}
