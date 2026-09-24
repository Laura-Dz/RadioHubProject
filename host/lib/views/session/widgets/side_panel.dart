import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../view_models/host_view_model.dart';
import 'call_queue.dart';
import 'live_broadcast_timer.dart';
import 'on_call_card.dart';
import 'poll_results_card.dart';
import 'announcements_modal.dart';

class SidePanel extends StatelessWidget {
  const SidePanel({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HostViewModel>();
    final s = vm.session;
    if (s == null) return const SizedBox.shrink();

    return Container(
      color: AppColors.surface,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Session summary
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NOW ON AIR',
                      style: TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textMuted,
                          letterSpacing: 0.8)),
                  const SizedBox(height: 8),
                  Text(s.programName,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text('Host: ${s.hostName}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary)),
                  if (s.guestName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      'Guest: ${s.guestName}'
                      '${s.guestRole != null ? " · ${s.guestRole}" : ""}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ],
                  if (s.thematic != null) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.label_outline,
                              size: 13, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(s.thematic!,
                                style: const TextStyle(
                                    fontSize: 12.5,
                                    fontStyle: FontStyle.italic)),
                          ),
                        ],
                      ),
                    ),
                  ],
                  if (s.isOnAir) ...[
                    const SizedBox(height: 14),
                    LiveBroadcastTimerCard(
                      scheduledStart: s.scheduledStart,
                      scheduledEnd: s.scheduledEnd,
                      isLive: s.isOnAir,
                    ),
                  ],
                ],
              ),
            ),

            // Metrics
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: _metric(
                      Icons.headphones,
                      '${s.listenerCount}',
                      'Listeners',
                      AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metric(
                      Icons.trending_up,
                      '${s.peakListeners}',
                      'Peak',
                      AppColors.gold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _metric(
                      Icons.call_outlined,
                      '${s.callsCount}',
                      'Calls',
                      AppColors.success,
                    ),
                  ),
                ],
              ),
            ),

            // Announcements quick access
            if (vm.announcements.isNotEmpty) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: InkWell(
                  onTap: () => showDialog(
                    context: context,
                    builder: (_) => const AnnouncementsModal(),
                  ),
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.gold.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.gold.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.campaign, color: AppColors.gold, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Show Announcements',
                                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.bold)),
                              Text(
                                '${vm.pendingAnnouncements.length} pending · ${vm.announcements.length - vm.pendingAnnouncements.length} aired',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.textMuted),
                      ],
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),
            const PollResultsCard(),
            const SizedBox(height: 12),
            const Divider(height: 1, color: AppColors.divider),

            // On call
            if (vm.onCall != null) ...[
              OnCallCard(call: vm.onCall!),
              const Divider(height: 1, color: AppColors.divider),
            ],

            // Call queue
            CallQueue(),
          ],
        ),
      ),
    );
  }

  Widget _metric(IconData icon, String value, String label, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(value,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800)),
          Text(label,
              style: const TextStyle(
                  fontSize: 10.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
