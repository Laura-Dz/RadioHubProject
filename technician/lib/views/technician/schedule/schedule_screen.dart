import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../../view_models/technician_view_model.dart';
import '../../../core/models/technician/session_model.dart';
import '../../../core/models/technician/timetable_slot_model.dart';
import '../../../core/services/network_time_service.dart';
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
  DateTime _weekStart = _monday(NetworkTimeService().now());

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
                      setState(() => _weekStart = _monday(NetworkTimeService().now())),
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

          // Legend row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            color: AppColors.surface,
            child: Row(
              children: [
                const Text('Legend:',
                    style: TextStyle(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600)),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFF3B82F6), 'Empty'),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFF22C55E), 'Live session'),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFFD4A017), 'Rediffusion'),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFF8B5CF6), 'Intermediary'),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFFEF4444), 'Special event'),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFFB91C1C), 'Flash news'),
                const SizedBox(width: 12),
                _legendItem(const Color(0xFF9CA3AF), 'Passed'),
                const Spacer(),
                // On-air indicator
                Row(
                  children: [
                    Container(
                      width: 10, height: 10,
                      decoration: const BoxDecoration(
                        color: AppColors.error,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Text('On air now',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                  ],
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
            final isToday = _sameDay(d, NetworkTimeService().now());
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

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(2),
            border: Border.all(color: color.withOpacity(0.5)),
          ),
        ),
        const SizedBox(width: 5),
        Text(label, style: const TextStyle(fontSize: 11.5)),
      ],
    );
  }

  Widget _dayColumn(
    TechnicianViewModel vm,
    DateTime day,
    List<Session> sessionsInWeek,
  ) {
    // 1. Timetable slots for this weekday
    final slots = vm.timetable.where((s) => s.weekday == day.weekday).toList();

    // 2. Special / flash sessions on this date (no timetable slot)
    final specials = sessionsInWeek.where((s) =>
        s.timetableSlotId == null &&
        (s.sessionType == SessionType.special || s.sessionType == SessionType.flash) &&
        _sameDay(s.scheduledStart, day)).toList();

    // 3. Build a unified list sorted by start time (in minutes)
    final entries = <_DayEntry>[];

    for (final slot in slots) {
      Session? session;
      for (final s in sessionsInWeek) {
        if (s.timetableSlotId == slot.id && _sameDay(s.scheduledStart, day)) {
          session = s;
          break;
        }
      }
      entries.add(_DayEntry(
        startMinute: slot.startHour * 60 + slot.startMinute,
        slot: slot,
        session: session,
      ));
    }

    for (final s in specials) {
      entries.add(_DayEntry(
        startMinute: s.scheduledStart.hour * 60 + s.scheduledStart.minute,
        special: s,
      ));
    }

    entries.sort((a, b) => a.startMinute.compareTo(b.startMinute));

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
        child: entries.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('—',
                      style: TextStyle(color: AppColors.textMuted)),
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(8),
                children: entries.map((e) {
                  if (e.special != null) {
                    return _specialCard(e.special!);
                  }
                  return _slotCell(vm, e.slot!, day, e.session, specials);
                }).toList(),
              ),
      ),
    );
  }

  Widget _specialCard(Session s) {
    final isFlash = s.sessionType == SessionType.flash;
    final isLive = s.isOnAir;
    final isEnded = s.status == SessionStatus.ended || s.isPassed;

    // Distinct reds: Special = bright red (0xFFEF4444), Flash = dark red (0xFFB91C1C)
    final Color baseColor =
        isFlash ? const Color(0xFFB91C1C) : const Color(0xFFEF4444);
    final Color color = isEnded ? const Color(0xFF9CA3AF) : baseColor;
    final icon = isFlash ? Icons.bolt : Icons.celebration_outlined;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SessionDetailScreen(session: s),
          ),
        ),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isLive
                  ? const Color(0xFFEF4444)
                  : color.withOpacity(isLive ? 0.7 : 0.4),
              width: isLive ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: time + type badge
                  Row(
                    children: [
                      Text(
                        '${s.scheduledStart.hour.toString().padLeft(2, '0')}:${s.scheduledStart.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 11,
                          color: color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '–${s.scheduledEnd.hour.toString().padLeft(2, '0')}:${s.scheduledEnd.minute.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: 10,
                          color: color.withOpacity(0.7),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 9, color: color),
                            const SizedBox(width: 3),
                            Text(
                              isFlash ? 'FLASH' : 'SPECIAL',
                              style: TextStyle(
                                fontSize: 9,
                                color: color,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    s.programName,
                    style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (s.hostName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      s.hostName,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  // Status pill
                  const SizedBox(height: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isLive
                          ? AppColors.success.withOpacity(0.15)
                          : (isEnded
                              ? AppColors.textMuted.withOpacity(0.15)
                              : color.withOpacity(0.1)),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      isLive
                          ? 'LIVE'
                          : (isEnded ? 'ENDED' : 'SCHEDULED'),
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: isLive
                            ? AppColors.success
                            : (isEnded ? AppColors.textMuted : color),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
              if (isLive)
                Positioned(
                  top: -2,
                  right: -2,
                  child: _OnAirDot(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotCell(
    TechnicianViewModel vm,
    TimetableSlot slot,
    DateTime day,
    Session? session,
    List<Session> specials,
  ) {
    final visual = _visualFor(session);
    final onAir = session?.isOnAir == true;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => _onSlotTap(context, vm, slot, day, session),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: visual.color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: onAir
                  ? AppColors.error
                  : visual.color.withOpacity(0.5),
              width: onAir ? 2 : 1,
            ),
          ),
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        slot.timeRange,
                        style: TextStyle(
                          fontSize: 11,
                          color: visual.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (session != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: visual.color.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            visual.label,
                            style: TextStyle(
                              fontSize: 8.5,
                              color: visual.color,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                        )
                      else
                        Icon(Icons.add,
                            size: 12,
                            color: visual.color.withOpacity(0.6)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    slot.programName,
                    style: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    session?.hostName ??
                        (slot.hostNames.isNotEmpty
                            ? slot.hostNames.join(', ')
                            : 'Unassigned'),
                    style: TextStyle(
                      fontSize: 10.5,
                      color: session != null
                          ? AppColors.textSecondary
                          : AppColors.textMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              // On-air red dot
              if (onAir)
                Positioned(
                  top: -2,
                  right: -2,
                  child: _OnAirDot(),
                ),
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

// Helper class for day column entries
class _DayEntry {
  final int startMinute;
  final TimetableSlot? slot;
  final Session? session;
  final Session? special;

  _DayEntry({
    required this.startMinute,
    this.slot,
    this.session,
    this.special,
  });
}

class _SlotVisual {
  final Color color;
  final String label;
  const _SlotVisual(this.color, this.label);
}

_SlotVisual _visualFor(Session? s) {
  if (s == null) {
    return const _SlotVisual(Color(0xFF3B82F6), 'EMPTY'); // blue
  }
  switch (s.contentTag) {
    case 'live':
      return const _SlotVisual(Color(0xFF22C55E), 'LIVE'); // green
    case 'rediffusion':
      return const _SlotVisual(Color(0xFFD4A017), 'REDIFF'); // gold
    case 'intermediary':
      return const _SlotVisual(Color(0xFF8B5CF6), 'INTERM.'); // purple
    case 'special':
      return const _SlotVisual(Color(0xFFEF4444), 'SPECIAL'); // bright red
    case 'flash':
      return const _SlotVisual(Color(0xFFB91C1C), 'FLASH'); // dark red
    case 'passed':
      return const _SlotVisual(Color(0xFF9CA3AF), 'PASSED'); // grey
    default:
      return const _SlotVisual(Color(0xFF3B82F6), 'EMPTY');
  }
}

class _OnAirDot extends StatefulWidget {
  @override
  State<_OnAirDot> createState() => _OnAirDotState();
}

class _OnAirDotState extends State<_OnAirDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.35, end: 1.0).animate(_c),
      child: Container(
        width: 10,
        height: 10,
        decoration: BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.5),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
      ),
    );
  }
}
