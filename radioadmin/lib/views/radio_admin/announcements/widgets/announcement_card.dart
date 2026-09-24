import 'package:flutter/material.dart';
import '../../../../core/models/radio_admin/announcement_request_model.dart';
import '../../../../core/constants/app_colors.dart';

class AnnouncementCard extends StatelessWidget {
  final AnnouncementRequest announcement;
  final VoidCallback? onValidate;
  final VoidCallback? onReject;
  final VoidCallback? onPrint;

  const AnnouncementCard({
    Key? key,
    required this.announcement,
    this.onValidate,
    this.onReject,
    this.onPrint,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final a = announcement;
    final statusColor = _statusColor(a.status);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Listener name, category, status
          Row(
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.primary.withOpacity(0.1),
                child: Text(
                  a.listenerName.isNotEmpty ? a.listenerName[0].toUpperCase() : '?',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.listenerName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                    Text(a.listenerEmail, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.gold.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  a.categoryLabel,
                  style: const TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Text(
                  a.statusLabel,
                  style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Content preview
          Text(
            '"${a.finalText.isNotEmpty ? a.finalText : a.originalText}"',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          // Diffusion & Pricing strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.surfaceAlt,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.repeat, size: 14, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  '${a.diffusionsPerDay}x/day for ${a.days} days',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const Spacer(),
                Text(
                  '${a.baseAmount.toStringAsFixed(0)} ${a.currency}',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
          ),
          // Actions
          if (onValidate != null || onReject != null || onPrint != null) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (onReject != null)
                  TextButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, size: 16, color: AppColors.error),
                    label: const Text('Reject', style: TextStyle(color: AppColors.error)),
                  ),
                if (onValidate != null) ...[
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: onValidate,
                    icon: const Icon(Icons.check, size: 16),
                    label: const Text('Validate & Schedule'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
                if (onPrint != null)
                  ElevatedButton.icon(
                    onPressed: onPrint,
                    icon: const Icon(Icons.print_outlined, size: 16),
                    label: const Text('Print PDF'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Color _statusColor(AnnouncementRequestStatus s) {
    switch (s) {
      case AnnouncementRequestStatus.pendingPayment:
      case AnnouncementRequestStatus.pendingValidation:
        return AppColors.warning;
      case AnnouncementRequestStatus.validated:
      case AnnouncementRequestStatus.scheduled:
      case AnnouncementRequestStatus.broadcasted:
        return AppColors.success;
      case AnnouncementRequestStatus.rejected:
        return AppColors.error;
      case AnnouncementRequestStatus.refunded:
        return AppColors.escrowRefunded;
    }
  }
}
