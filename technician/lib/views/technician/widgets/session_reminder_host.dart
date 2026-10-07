import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../core/services/network_time_service.dart';
import '../../../core/constants/app_colors.dart';
import '../schedule/forced_session_init_modal.dart';

class SessionReminderHost extends StatefulWidget {
  final Widget child;
  final VoidCallback? onOpenSessions;
  const SessionReminderHost({
    Key? key,
    required this.child,
    this.onOpenSessions,
  }) : super(key: key);

  @override
  State<SessionReminderHost> createState() => _State();
}

class _State extends State<SessionReminderHost> {
  Timer? _timer;
  final Set<String> _shown = {};
  final Map<String, DateTime> _snoozedSlots = {};
  final Set<String> _dismissedSlots = {};
  bool _isModalOpen = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 20), (_) => _check());
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await NetworkTimeService().sync();
      _check();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _check() {
    if (!mounted || _isModalOpen) return;
    try {
      final vm = context.read<TechnicianViewModel>();
      final net = NetworkTimeService();
      final now = net.now();

      // ============================================================
      // 1. FORCED INITIALIZATION CHECK:
      // Scheduled timetable slots that have arrived but have NO session
      // (neither new live session nor rediffusion)
      // ============================================================
      final todayWeekday = now.weekday; // 1 = Monday ... 7 = Sunday
      final todaySlots = vm.timetable
          .where((slot) => slot.isActive && slot.weekday == todayWeekday)
          .toList();

      for (final slot in todaySlots) {
        final slotStart = slot.dateFor(now);
        final slotEnd = slot.endDateFor(now);

        // Check if air time has arrived (within 5 min before start up until end time)
        final isTimeArrived = now.isAfter(slotStart.subtract(const Duration(minutes: 5))) &&
            now.isBefore(slotEnd);
        if (!isTimeArrived) continue;

        final slotKey = '${slot.id}_${now.year}_${now.month}_${now.day}';
        final snoozedUntil = _snoozedSlots[slotKey];
        if (snoozedUntil != null && now.isBefore(snoozedUntil)) continue;
        if (_dismissedSlots.contains(slotKey)) continue;

        // Check if ANY session exists for this slot today (live, scheduled, ended, or rediffusion)
        final bool hasSession = vm.sessions.any((s) {
          final isSameSlot = s.timetableSlotId == slot.id;
          final isSameProgToday = s.programId == slot.programId &&
              s.scheduledStart.year == now.year &&
              s.scheduledStart.month == now.month &&
              s.scheduledStart.day == now.day &&
              (s.scheduledStart.difference(slotStart).abs().inMinutes <= 45);
          return (isSameSlot || isSameProgToday);
        });

        if (!hasSession) {
          _isModalOpen = true;
          ForcedSessionInitModal.show(
            context,
            slot: slot,
            date: now,
            onSnooze: () {
              _snoozedSlots[slotKey] = now.add(const Duration(minutes: 5));
            },
            onDismiss: () {
              _dismissedSlots.add(slotKey);
            },
          ).then((_) {
            _isModalOpen = false;
          });
          return;
        }
      }

      // ============================================================
      // 2. EXISTING SCHEDULED SESSION REMINDER:
      // For sessions that are already initialized and scheduled
      // ============================================================
      for (final s in vm.sessions) {
        if (s.status != SessionStatus.scheduled) continue;
        if (s.isRediffusion) continue;
        if (_shown.contains(s.id)) continue;

        final diff = s.scheduledStart.difference(now);
        if (diff.inSeconds <= 300 && diff.inSeconds >= -60) {
          _shown.add(s.id);
          // If a session is already live, don't nag
          if (vm.currentLiveSession != null) continue;
          _isModalOpen = true;
          _showPopup(s, diff);
          return;
        }
      }
    } catch (e) {
      debugPrint('SessionReminderHost._check error: $e');
    }
  }

  void _showPopup(Session s, Duration diff) {
    final minutes = diff.inMinutes <= 0 ? 0 : diff.inMinutes;
    final seconds = diff.inSeconds.remainder(60);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.play_circle_outline,
                  color: AppColors.success, size: 20),
            ),
            const SizedBox(width: 10),
            const Text('Session starting soon',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(s.programName,
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 4),
            Text(s.hostName,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.timer_outlined,
                      size: 18, color: AppColors.success),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      minutes > 0
                          ? '"${s.programName}" starts in $minutes min.'
                          : '"${s.programName}" starts in ${seconds}s.',
                      style: const TextStyle(fontSize: 13.5),
                    ),
                  ),
                ],
              ),
            ),
            if (!NetworkTimeService().isSynced) ...[
              const SizedBox(height: 8),
              const Text(
                'Using device time — network sync failed.',
                style: TextStyle(fontSize: 11, color: AppColors.warning),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              widget.onOpenSessions?.call();
            },
            icon: const Icon(Icons.arrow_forward, size: 16),
            label: const Text('Go to session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    ).then((_) {
      _isModalOpen = false;
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
