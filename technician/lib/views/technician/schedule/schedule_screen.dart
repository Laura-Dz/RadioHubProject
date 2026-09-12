import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../core/models/technician/timetable_slot_model.dart';
import '../../../core/constants/app_colors.dart';
import '../sessions/session_detail_screen.dart';
import 'initialize_session_modal.dart';
import 'rediffusion_modal.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({Key? key}) : super(key: key);
  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  DateTime _weekStart = _monday(DateTime.now());

  static DateTime _monday(DateTime d) =>
      DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<TechnicianViewModel>();

    final days = List.generate(7, (i) => _weekStart.add(Duration(days: i)));

    // Only sessions that fall in this week
    final weekEnd = _weekStart.add(const Duration(days: 7));
    final sessionsInWeek = vm.sessions.where((s) =>
        s.scheduledStart.isAfter(_weekStart.subtract(const Duration(seconds: 1))) &&
        s.scheduledStart.isBefore(weekEnd)).toList();

    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            color: AppColors.surface,
            child: Row(
              children: [
                IconButton(
                  tooltip: 'Previous week',
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => setState(
                      () => _weekStart = _weekStart.subtract(const Duration(days: 7))),
                ),
                TextButton(
                  onPressed: () =>
                      setState(() => _weekStart = _monday(DateTime.now())),
                  child: const Text('Today'),
                ),
                IconButton(
                  tooltip: 'Next week',
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => setState(
                      () => _weekStart = _weekStart.add(const Duration(days: 7))),
                ),
                const SizedBox(width: 16),
                Text(
                  'Week of ${DateFormat('d MMM yyyy').format(_weekStart)}',
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                if (vm.timetable.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.warning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded,
                            size: 14, color: AppColors.warning),
                        SizedBox(width: 6),
                        Text('No timetable yet — build one first',
                            style: TextStyle(
                                fontSize: 12,
                                color: AppColors.warning,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.divider),

          // Info strip
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.info.withOpacity(0.05),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: AppColors.info),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Schedule is a live view of the timetable for the selected week. Click any empty slot to go live or schedule a rediffusion.',
                    style: TextStyle(fontSize: 12, color: AppColors.textPrimary),
                  ),
                ),
              ],
            ),
          ),

          // Week grid
          Expanded(
            child: vm.timetable.isEmpty
                ? _emptyTimetable()
                : Padding(
                    padding: const EdgeInsets.all(16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(
                        children: [
                          _headerRow(days),
                          Expanded(
                            child: Row(
                              children: days.map((d) =>
                                _dayColumn(vm, d, sessionsInWeek)).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _headerRow(List<DateTime> days) => Container(
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.divider)),
        ),
        child: Row(
          children: days.map((d) {
            final isToday = _sameDay(d, DateTime.now());
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isToday
                      ? AppColors.primary.withOpacity(0.05)
                      : Colors.transparent,
                  border: Border(
                    right: BorderSide(
                      color: d == days.last
                          ? Colors.transparent
                          : AppColors.divider,
                    ),
                  ),
                ),
                child: Column(
                  children: [
                    Text(DateFormat('EEE').format(d),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isToday
                              ? AppColors.primary
                              : AppColors.textSecondary,
                        )),
                    const SizedBox(height: 2),
                    Text(d.day.toString(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color:
                              isToday ? AppColors.primary : AppColors.textPrimary,
                        )),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      );

  Widget _dayColumn(
      TechnicianViewModel vm, DateTime day, List<Session> sessionsInWeek) {
    // Slots for this weekday
    final slots =
        vm.timetable.where((s) => s.weekday == day.weekday).toList()
          ..sort((a, b) {
            if (a.startHour != b.startHour) {
              return a.startHour.compareTo(b.startHour);
            }
            return a.startMinute.compareTo(b.startMinute);
          });

    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            right: BorderSide(
              color: _sameDay(day, _weekStart.add(const Duration(days: 6)))
                  ? Colors.transparent
                  : AppColors.divider,
            ),
          ),
        ),
        child: slots.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('—',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(8),
                children: slots.map((slot) {
                  // Find the session bound to this slot on this date
                  Session? session;
                  for (final s in sessionsInWeek) {
                    if (s.timetableSlotId == slot.id &&
                        _sameDay(s.scheduledStart, day)) {
                      session = s;
                      break;
                    }
                  }
                  return _slotCell(vm, slot, day, session);
                }).toList(),
              ),
      ),
    );
  }

  Widget _slotCell(
      TechnicianViewModel vm, TimetableSlot slot, DateTime day, Session? session) {
    final now = DateTime.now();
    final slotEnd = slot.endDateFor(day);
    final isPast = slotEnd.isBefore(now);
    final isLive = session?.status == SessionStatus.live;
    final isRediff = session?.isRediffusion == true;
    final isEnded = session?.status == SessionStatus.ended;

    Color color;
    String label;
    if (isLive) {
      color = AppColors.success;
      label = 'Live';
    } else if (isRediff) {
      color = AppColors.gold;
      label = 'Rediffusion';
    } else if (isEnded) {
      color = AppColors.textMuted;
      label = 'Ended';
    } else if (session != null) {
      color = AppColors.primary;
      label = 'Scheduled';
    } else if (isPast) {
      color = AppColors.textMuted;
      label = 'Missed';
    } else {
      color = AppColors.primary.withOpacity(0.35);
      label = 'Plan';
    }

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _onSlotTap(context, vm, slot, day, session),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: session != null
                ? color.withOpacity(0.08)
                : (isPast
                    ? AppColors.surfaceAlt
                    : AppColors.primary.withOpacity(0.03)),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: session != null
                  ? color.withOpacity(0.35)
                  : AppColors.primary.withOpacity(0.15),
              width: isLive ? 1.5 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(slot.timeRange,
                      style: TextStyle(
                          fontSize: 11,
                          color: session != null ? color : AppColors.primary,
                          fontWeight: FontWeight.w700)),
                  const Spacer(),
                  if (session != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(label,
                          style: TextStyle(
                              fontSize: 9.5,
                              color: color,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3)),
                    )
                  else
                    Icon(
                      isPast ? Icons.remove : Icons.add,
                      size: 12,
                      color: isPast
                          ? AppColors.textMuted
                          : AppColors.primary.withOpacity(0.5),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              Text(slot.programName,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis),
              if (session != null) ...[
                const SizedBox(height: 2),
                Text(session.hostName,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ] else if (slot.hostNames.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(slot.hostNames.join(', '),
                    style: const TextStyle(
                        fontSize: 10.5, color: AppColors.textMuted),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _onSlotTap(
    BuildContext context,
    TechnicianViewModel vm,
    TimetableSlot slot,
    DateTime day,
    Session? session,
  ) async {
    if (session != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SessionDetailScreen(session: session),
        ),
      );
      return;
    }

    // Empty slot — pick Live or Rediffusion
    final choice = await showModalBottomSheet<String>(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _choiceSheet(slot, day),
    );

    if (!context.mounted || choice == null) return;
    if (choice == 'live' || choice == 'initialize') {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => InitializeSessionModal(slot: slot, date: day),
      );
    } else if (choice == 'rediffusion') {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => RediffusionModal(slot: slot, date: day),
      );
    }
  }

  Widget _choiceSheet(TimetableSlot slot, DateTime day) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(slot.programName,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            '${DateFormat('EEEE d MMM').format(day)} · ${slot.timeRange}',
            style: const TextStyle(
                fontSize: 13, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 24),
          _bigChoice(
            icon: Icons.schedule,
            color: AppColors.primary,
            title: 'Initialize session',
            subtitle:
                'Set the host, co-hosts, guest, and thematics now. Start it when it\'s time.',
            onTap: () => Navigator.pop(context, 'initialize'),
          ),
          const SizedBox(height: 12),
          _bigChoice(
            icon: Icons.replay,
            color: AppColors.gold,
            title: 'Set as rediffusion',
            subtitle:
                'Replay a past session of this program. Calls will be disabled.',
            onTap: () => Navigator.pop(context, 'rediffusion'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  Widget _bigChoice({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.06),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: color)),
                    const SizedBox(height: 2),
                    Text(subtitle,
                        style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.35)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: color),
            ],
          ),
        ),
      );

  Widget _emptyTimetable() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.calendar_view_week_outlined,
                size: 72, color: AppColors.textMuted.withOpacity(0.4)),
            const SizedBox(height: 12),
            const Text('No timetable yet',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            const Text(
                'Create recurring slots in the Timetable tab to see them here.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          ],
        ),
      );

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}
