import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/models/technician/timetable_slot_model.dart';
import '../../../core/constants/app_colors.dart';
import 'initialize_session_modal.dart';
import 'rediffusion_modal.dart';

/// Modal dialog that prompts the technician when a scheduled program's
/// broadcast time has arrived, but no live session or rediffusion has been initialized.
class ForcedSessionInitModal extends StatelessWidget {
  final TimetableSlot slot;
  final DateTime date;

  const ForcedSessionInitModal({
    Key? key,
    required this.slot,
    required this.date,
  }) : super(key: key);

  /// Helper to display the modal and immediately route to the technician's choice
  static Future<void> show(
    BuildContext context, {
    required TimetableSlot slot,
    required DateTime date,
    VoidCallback? onSnooze,
    VoidCallback? onDismiss,
  }) async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ForcedSessionInitModal(slot: slot, date: date),
    );

    if (!context.mounted || result == null) return;

    if (result == 'initialize') {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => InitializeSessionModal(slot: slot, date: date),
      );
    } else if (result == 'rediffusion') {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => RediffusionModal(slot: slot, date: date),
      );
    } else if (result == 'snooze') {
      onSnooze?.call();
    } else if (result == 'dismiss') {
      onDismiss?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final slotDate = slot.dateFor(date);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Urgent Header with Pulse Indicator
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.notification_important_rounded,
                      color: AppColors.error,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Broadcast Time Arrived',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Uninitialized Scheduled Program',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    tooltip: 'Dismiss for now',
                    onPressed: () => Navigator.pop(context, 'dismiss'),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Program Information Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColors.error.withOpacity(0.25),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            slot.programName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            slot.timeRange,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          DateFormat('EEEE, d MMMM yyyy').format(slotDate),
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textSecondary),
                        ),
                        if (slot.defaultHostName != null &&
                            slot.defaultHostName!.isNotEmpty) ...[
                          const SizedBox(width: 16),
                          const Icon(Icons.person_outline,
                              size: 15, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              slot.defaultHostName!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 12.5,
                                  color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Alert Explanation
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.warning.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Icon(Icons.info_outline, size: 18, color: AppColors.warning),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'This scheduled slot is currently active or starting now, but no session has been created. Start a live broadcast or choose a past recording for rediffusion.',
                        style: TextStyle(fontSize: 12.5, height: 1.4),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Action 1: Start New Live Session
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'initialize'),
                icon: const Icon(Icons.play_circle_fill, size: 18),
                label: const Text('Start New Live Session'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 10),

              // Action 2: Set as Rediffusion
              ElevatedButton.icon(
                onPressed: () => Navigator.pop(context, 'rediffusion'),
                icon: const Icon(Icons.replay_rounded, size: 18),
                label: const Text('Set as Rediffusion (Replay Past Broadcast)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
              ),
              const SizedBox(height: 14),

              // Footer: Snooze & Dismiss
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton.icon(
                    onPressed: () => Navigator.pop(context, 'snooze'),
                    icon: const Icon(Icons.snooze, size: 16),
                    label: const Text('Snooze 5 min'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, 'dismiss'),
                    child: const Text('Dismiss (Skip today)'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
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
}
