import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class ShowStatsCard extends StatelessWidget {
  final Map<String, dynamic> show;

  const ShowStatsCard({Key? key, required this.show}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final status = (show['status'] ?? '').toString().toLowerCase();
    final isLive = status == 'live';
    final isUpcoming = status == 'scheduled';
    final isEnded = status == 'ended' || status == 'recorded';

    Color statusColor;
    String statusLabel;

    if (isLive) {
      statusColor = AppColors.live;
      statusLabel = '🔴 Live';
    } else if (isUpcoming) {
      statusColor = AppColors.chartTalk;
      statusLabel = '⏳ Upcoming';
    } else if (isEnded) {
      statusColor = AppColors.textSecondary;
      statusLabel = '📻 Recorded';
    } else {
      statusColor = AppColors.textMuted;
      statusLabel = show['status'] ?? 'Unknown';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isLive ? AppColors.live.withOpacity(0.08) : AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isLive ? AppColors.live.withOpacity(0.3) : AppColors.cardBorder,
        ),
      ),
      child: Row(
        children: [
          // Status indicator stripe
          Container(
            width: 4,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),

          // Show info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      show['programName'] ?? 'Unknown Show',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (show['thematic'] != null && show['thematic'].toString().isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        '• ${show['thematic']}',
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      '🎙️ ${show['hostName'] ?? 'No Host'}',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (show['guestName'] != null && show['guestName'].toString().isNotEmpty) ...[
                      const SizedBox(width: 12),
                      Text(
                        '👤 Guest: ${show['guestName']}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.primaryLight,
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Listeners & Status
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${show['listenerCount'] ?? 0} listeners',
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

