import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class AudimatChart extends StatelessWidget {
  final List<Map<String, dynamic>> shows;

  const AudimatChart({Key? key, required this.shows}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (shows.isEmpty) {
      return const Center(
        child: Text(
          'No show statistics recorded for this period',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
        ),
      );
    }

    final maxListeners = shows.fold<double>(
      100.0,
      (max, s) {
        final val = ((s['listenerCount'] ?? 0) as num).toDouble();
        return val > max ? val : max;
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final chartHeight = constraints.maxHeight - 40;

        return Column(
          children: [
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Y-axis labels
                  SizedBox(
                    width: 45,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('${maxListeners.toInt()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        Text('${(maxListeners * 0.75).toInt()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        Text('${(maxListeners * 0.5).toInt()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        Text('${(maxListeners * 0.25).toInt()}', style: const TextStyle(color: AppColors.textMuted, fontSize: 10)),
                        const Text('0', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Vertical Axis Line
                  Container(
                    width: 1,
                    color: AppColors.cardBorder,
                    height: double.infinity,
                  ),
                  const SizedBox(width: 8),

                  // Bars Row
                  Expanded(
                    child: Stack(
                      children: [
                        // Grid lines
                        Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: List.generate(
                            5,
                            (index) => Container(
                              height: 1,
                              color: AppColors.cardBorder.withOpacity(0.3),
                            ),
                          ),
                        ),

                        // Columns
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: shows.map((show) {
                            final listeners = ((show['listenerCount'] ?? 0) as num).toDouble();
                            final heightFraction = (listeners / maxListeners).clamp(0.02, 1.0);
                            final isLive = show['status'] == 'live';

                            return Expanded(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${listeners.toInt()}',
                                      style: TextStyle(
                                        color: isLive ? AppColors.live : AppColors.primaryLight,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Tooltip(
                                      message: '${show['programName']}: ${listeners.toInt()} listeners (${show['status']})',
                                      child: Container(
                                        height: chartHeight * heightFraction,
                                        decoration: BoxDecoration(
                                          color: isLive
                                              ? AppColors.live
                                              : AppColors.chartTalk,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (isLive ? AppColors.live : AppColors.chartTalk).withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, -2),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Horizontal Axis Line
            Padding(
              padding: const EdgeInsets.only(left: 53),
              child: Container(height: 1, color: AppColors.cardBorder),
            ),

            // X-axis rotated program labels
            Padding(
              padding: const EdgeInsets.only(left: 53),
              child: Row(
                children: shows.map((show) {
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Transform.rotate(
                        angle: -0.5, // ~ -30 degrees
                        child: Text(
                          show['programName'] ?? '',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.right,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

