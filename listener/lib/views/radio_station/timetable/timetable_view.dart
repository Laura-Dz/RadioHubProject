import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../core/models/timetable_slot.dart';
import '../../../core/services/radio_schedule_service.dart';
import '../../../core/constants/app_colors.dart';

class TimetableView extends StatefulWidget {
  final String radioId;
  final String radioName;

  const TimetableView({
    Key? key,
    required this.radioId,
    required this.radioName,
  }) : super(key: key);

  @override
  State<TimetableView> createState() => _State();
}

class _State extends State<TimetableView> {
  final _service = RadioScheduleService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Timetable',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            Text(widget.radioName,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ],
        ),
      ),
      body: StreamBuilder<List<TimetableSlot>>(
        stream: _service.streamTimetable(widget.radioId),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          final slots = snap.data!;
          if (slots.isEmpty) {
            return _empty();
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Info banner
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: AppColors.info.withOpacity(0.2)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.info_outline,
                          size: 16, color: AppColors.info),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Weekly recurring programming. Tap a slot to set a reminder.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // 7 day sections
                ...List.generate(7, (i) => _daySection(i + 1, slots)),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _daySection(int weekday, List<TimetableSlot> all) {
    final slots =
        all.where((s) => s.weekday == weekday).toList();
    if (slots.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Day header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(13)),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today,
                    size: 14, color: AppColors.primary),
                const SizedBox(width: 8),
                Text(
                  TimetableSlot.dayNames[weekday - 1],
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${slots.length}',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ),
          // Slots
          ...slots.map((s) => _slotRow(s)),
        ],
      ),
    );
  }

  Widget _slotRow(TimetableSlot s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          // Time
          SizedBox(
            width: 70,
            child: Text(
              s.timeRange,
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary),
            ),
          ),
          const SizedBox(width: 12),
          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.programName,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                if (s.hostNames.isNotEmpty)
                  Text(s.hostNames.join(', '),
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // Reminder
          IconButton(
            tooltip: 'Set reminder',
            icon: const Icon(Icons.notifications_none,
                size: 18, color: AppColors.textSecondary),
            onPressed: () => _setReminder(context, s),
          ),
        ],
      ),
    );
  }

  void _setReminder(BuildContext context, TimetableSlot slot) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    // Compute the next occurrence of this weekday
    final now = DateTime.now();
    var next = DateTime(now.year, now.month, now.day, slot.startHour, slot.startMinute);
    while (next.weekday != slot.weekday || next.isBefore(now)) {
      next = next.add(const Duration(days: 1));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
            'Reminder set for ${TimetableSlot.dayNames[slot.weekday - 1]} at ${slot.timeRange.split('–').first}'),
        backgroundColor: AppColors.success,
      ),
    );
  }

  Widget _empty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.calendar_view_week_outlined,
              size: 72, color: AppColors.textMuted.withOpacity(0.4)),
          const SizedBox(height: 12),
          const Text('No timetable yet',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('The radio has not published its weekly schedule.',
              style: TextStyle(
                  fontSize: 12.5, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
