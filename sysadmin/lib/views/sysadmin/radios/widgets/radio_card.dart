import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/models/sysadmin/radio_model.dart';

class RadioCard extends StatelessWidget {
  final RadioModel radio;
  final VoidCallback onTap;

  const RadioCard({
    Key? key,
    required this.radio,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isLive = radio.isLive;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLive ? AppColors.live.withOpacity(0.4) : AppColors.cardBorder,
            width: isLive ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Name + Live/Recorded badge
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    radio.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: isLive ? AppColors.live.withOpacity(0.15) : AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isLive ? AppColors.live : AppColors.textMuted,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: isLive ? AppColors.live : AppColors.textSecondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        isLive ? 'Live ${(radio.listenerCount / 1000).toStringAsFixed(1)}k' : 'Recorded',
                        style: TextStyle(
                          color: isLive ? AppColors.live : AppColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Middle: Admin
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.person_outline_rounded, color: AppColors.primaryLight, size: 16),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Admin: ${radio.radioAdminName}',
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                  decoration: BoxDecoration(
                    color: radio.isNonProfit
                        ? AppColors.success.withOpacity(0.12)
                        : (radio.legalStatus == 'stateOwned'
                            ? AppColors.info.withOpacity(0.12)
                            : AppColors.primary.withOpacity(0.1)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    radio.legalStatus == 'nonProfit'
                        ? 'Non-Profit'
                        : (radio.legalStatus == 'stateOwned' ? 'State-Owned' : 'For-Profit'),
                    style: TextStyle(
                      color: radio.isNonProfit
                          ? AppColors.success
                          : (radio.legalStatus == 'stateOwned' ? AppColors.info : AppColors.primaryLight),
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            const Divider(color: AppColors.cardBorder, height: 1),
            const SizedBox(height: 12),

            // Bottom info row: RadioAdmin Account and Stream Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primaryLight, size: 15),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Admin: ${radio.radioAdminName}',
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      radio.isActive ? Icons.wifi_tethering_rounded : Icons.wifi_tethering_off_rounded,
                      color: radio.isActive ? AppColors.success : AppColors.textMuted,
                      size: 15,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      radio.isActive ? 'Live' : 'Off',
                      style: TextStyle(
                        color: radio.isActive ? AppColors.success : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.textMuted, size: 12),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

